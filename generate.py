from sage.databases.cremona import cremona_letter_code, class_to_int # for the make_label function
from sage.misc.lazy_attribute import lazy_attribute
from itertools import izip_longest
import json, os, re, sys, random, string
opj, ope = os.path.join, os.path.exists
from collections import defaultdict
from ConfigParser import ConfigParser
from lmfdb import db
from psycopg2.sql import SQL
from sage.arith.misc import euler_phi
from sage.combinat.hall_polynomial import hall_polynomial
from sage.structure.sequence import Sequence
from sage.rings.integer_ring import ZZ
from sage.matrix.constructor import matrix
from sage.matrix.matrix_space import MatrixSpace
from sage.libs.gap.libgap import libgap
from sage.arith.srange import srange
from sage.functions.other import ceil
from sage.misc.flatten import flatten
from sage.misc.misc_c import prod

# If the group is non-abelian and the transitive degree is under the following bound
# we store generators as permutations
TRANSITIVE_DEGREE_BOUND = 20
# The bound below which we call TransitiveIdentification
TRANSITIVE_IDENTIFICATION_BOUND = 30

# The following classes support nicely loading and saving
# to disk in a format readable by postgres

class PGType(lazy_attribute):
    check=None # bound for integer types
    @classmethod
    def _load(cls, x):
        """
        Wraps :meth:`load` for the appropriate handling of NULLs.
        """
        if x != r'\N':
            return cls.load(x)
    @classmethod
    def load(cls, x):
        """
        Takes a string from a file and returns the appropriate
        Sage object.

        Should be inverse to :meth:`save`

        This default function can be overridden in subclasses.
        """
        if x.isdigit():
            return ZZ(x)
        elif x.startswith('{'):
            return sage_eval(x.replace('{','[').replace('}',']'))
        else:
            return x

    @classmethod
    def _save(cls, x):
        """
        Wraps :meth:`save` for the appropriate handling of NULLs.
        """
        if x is None:
            return r'\N'
        else:
            return cls.save(x)

    @classmethod
    def save(cls, x, recursing=False):
        """
        Takes a Sage object stored in this attribute
        and returns a string appropriate to write to a file
        that postgres can load.

        Should be inverse to :meth:`load`

        This default function can be overridden in subclasses.
        """
        if isinstance(x, (list, tuple)):
            return '{' + ','.join(cls.save(a) for a in x) + '}'
        else:
            if cls.check and (x >= cls.check or x <= -cls.check):
                raise ValueError("Out of bounds")
            x = str(x)
            if recursing:
                return '"' + x + '"'
            else:
                return x

class pg_text(PGType):
    pg_type = 'text'
class pg_smallint(PGType):
    check = 2**15-1
    pg_type = 'smallint'
class pg_integer(PGType):
    check = 2**31-1
    pg_type = 'integer'
class pg_bigint(PGType):
    check = 2**63-1
    pg_type = 'bigint'
class pg_numeric(PGType):
    # Currently only used to store large integers, so no decimal handling needed
    pg_type = 'numeric'
class pg_smallint_list(PGType):
    check = 2**15-1
    pg_type = 'smallint[]'
class pg_integer_list(PGType):
    check = 2**31-1
    pg_type = 'integer[]'
class pg_bigint_list(PGType):
    check = 2**63-1
    pg_type = 'bigint[]'
class pg_float8_list(PGType):
    pg_type = 'float8[]'
class pg_text_list(PGType):
    pg_type = 'text[]'
class pg_numeric_list(PGType):
    pg_type = 'numeric[]'
class pg_boolean(PGType):
    pg_type = 'boolean'
    @classmethod
    def load(cls, x):
        if x == 't':
            return True
        elif x == 'f':
            return False
        else:
            raise RuntimeError
    @classmethod
    def save(cls, x):
        if x:
            return 't'
        else:
            return 'f'
class _rational_list(object):
    @classmethod
    def load(cls, x):
        def recursive_QQ(y):
            if isinstance(y, basestring):
                return QQ(y)
            else:
                return map(recursive_QQ, y)
        x = PGType.load(x)
        return recursive_QQ(x)
    @classmethod
    def save(cls, x):
        def recursive_str(y):
            if isinstance(y, list):
                return [recursive_str(z) for z in y]
            else:
                return str(y)
        x = recursive_str(x)
        return PGType.save(x)
class pg_rational_list(_rational_list, PGType):
    pg_type = 'text[]'
class pg_jsonb(PGType):
    pg_type = 'jsonb'
    @classmethod
    def load(cls, x):
        return sage_eval(x)
    @classmethod
    def save(cls, x):
        return str(x).replace("'",'"')

class Stage(object):
    def __init__(self, controller, input, output, done):
        self.controller = controller
        self.input = input
        self.output = output
        self.done = done

class GenericTask(object):
    #def __init__(self, g, q, stage):
    #    self.g, self.q, self.stage = g, q, stage
    #    self.logheader = stage.controller.logheader.format(g=g, q=q, name=stage.shortname)
    def ready(self):
        return all(ope(data[-1]) for data in self.input_data)
    def done(self):
        return all(ope(output.format(g=self.g, q=self.q)) for output in self.stage.output)
    @lazy_attribute
    def input_data(self):
        """
        Default behavior can beoverridden in subclass
        """
        return [filename.format(g=self.g, q=self.q) for filename in self.stage.input]

class Worker(object):
    def __init__(self, logfile):
        self.logfile = logfile

class Controller(object):
    def __init__(self, worker_count=1, config=None):
        if config is None:
            if os.path.exists('config.ini'):
                config = os.path.abspath('config.ini')
            else:
                raise ValueError("Must have config.ini in directory or specify location")
        self.config_file = config
        self.cfgp = cfgp = ConfigParser()
        cfgp.read(config)
        # Create subdirectories if they do not exist
        basedir = os.path.abspath(os.path.expanduser(cfgp.get('dirs', 'base')))
        if not ope(basedir):
            os.makedirs(basedir)
        subdirs = [sub.strip() for sub in cfgp.get('dirs', 'subdirs').split(',')] + ['logs']
        for subdir in subdirs:
            if not ope(opj(basedir, subdir)):
                os.mkdir(opj(basedir, subdir))
        self._extra_init()

        # Create Stages
        stages = []
        self.logfrequency = int(cfgp.get('logging', 'logfrequency'))
        self.logheader = cfgp.get('logging', 'logheader') + ' '
        plan = ['Stage'+stage.strip() for stage in cfgp.get('plan', 'stages').split(',')]
        for stage in plan:
            if stage not in cfgp.sections():
                raise ValueError("Missing section %s"%stage)
            info = [(key, cfgp.get(stage, key)) for key in cfgp.options(stage)]
            input = [opj(basedir, val) for (key, val) in info if key.startswith('in')]
            if any(key.startswith('out') for key, val in info):
                output, output_indexes = zip(*((opj(basedir, val), key[3:]) for (key, val) in info if key.startswith('out')))
            else:
                output_indexes = output = []
            if any(key.startswith('data') for key, val in info):
                data, data_indexes = zip(*(([attr.strip() for attr in val.split(',')], key[4:]) for (key, val) in info if key.startswith('data')))
            else:
                data_indexes = data = []
            if output_indexes != data_indexes:
                raise ValueError("Output and data specifications need to be in the same order for %s.\nOne was %s while the other was %s" % (stage, ', '.join(output_indexes), ', '.join(data_indexes)))
            output = zip(output, data)
            done = [opj(basedir, val) for (key, val) in info if key.startswith('done')]
            if len(done) == 0:
                done = None
            elif len(done) == 1:
                done = done[0]
            else:
                raise ValueError("Multiple done values specified")
            stages.append(getattr(self.__class__, stage)(self, input=input, output=output, done=done))

        self.stages = stages
        self.tasks = sum((stage.tasks for stage in stages), [])
        logfile = cfgp.get('logging', 'logfile')
        self.workers = [Worker(opj(basedir, logfile.format(i=i))) for i in range(worker_count)]

    def _extra_init(self):
        # Parse config options before creating stages and tasks
        pass

    def run_serial(self):
        worker = self.workers[0]
        for task in self.tasks:
            task.run(worker.logfile)

    def load(self, filename, start=None, stop=None, cls=None, old=False):
        """
        Iterates over all of the isogeny classes stored in a file.
        The data contained in the file is specified by header lines: the first giving the
        column names (which are identical to PGType attributes of a PGSaver `cls`)
        the second giving postgres types (unused here), and the third blank.

        We use ':' as a separator.

        INPUT:

        - ``filename`` -- the filename to open
        - ``start`` -- if not ``None``, the line to start from, indexed so that 0 is
            the first line of data.  Note that this will be the fourth line of the
            file because of the header.
        - ``stop`` -- if not None``, the first line not to read, indexed as for ``start``
        - ``cls`` -- the PGSaver class to load data into
        - ``old`` -- if True, uses 'old_'+attr for attributes in the header if possible
        """
        if cls is None:
            cls = self.default_cls
        def fix_attr(attr):
            if old and hasattr(cls, 'old_' + attr):
                attr = 'old_' + attr
            return attr
        with open(filename) as F:
            for i, line in enumerate(F):
                if i == 0:
                    header = map(fix_attr, line.strip().split(':'))
                elif i >= 3 and (start is None or i-3 >= start) and (stop is None or i-3 < start):
                    yield cls.load(line.strip(), header)

    def save(self, filename, isogeny_classes, attributes, cls=None, force=False):
        """
        INPUT:

        - ``filename`` -- a filename to write
        - ``isogeny_classes`` -- an iterable of instances to write to the file
        - ``attributes`` -- a list of attributes to save to the file
        - ``cls`` -- the class of the entries of ``isogeny_classes``
        - ``force`` -- if True, will allow overwriting an existing file
        """
        # This should be re-enabled once no longer debugging
        # if not force and ope(filename):
        #     raise ValueError("File %s already exists"%filename)
        if cls is None:
            cls = self.default_cls
        types = [getattr(cls, attr) for attr in attributes]
        header = [':'.join(attributes),
                  ':'.join(attr.pg_type for attr in types),
                  '\n']
        with open(filename, 'w') as F:
            F.write('\n'.join(header))
            for isog in isogeny_classes:
                F.write(isog.save(attributes) + '\n')

class PGSaver(object):
    @classmethod
    def load(cls, s, header):
        """
        INPUT:

        - ``s`` -- a string, giving the data defined by ``header`` as colon separated values
        - ``header`` -- a list of attribute names to fill in
        """
        data = s.split(':')
        isoclass = cls()
        for attr, val in zip(header, data):
            setattr(isoclass, attr, getattr(cls, attr)._load(val))
        return isoclass

    def save(self, header):
        """
        INPUT:

        - ``header`` -- a list of attribute names to save

        OUTPUT:

        - a string, giving a colon separated list of the desired attributes
        """
        cls = self.__class__
        return ':'.join(getattr(cls, attr)._save(getattr(self, attr)) for attr in header)

class Groups(Controller):
    """
    This class controls the creation of group data for the LMFDB from sources like GAP and Magma

    - ``workers`` -- the number of processes to be allocated to this computation
    - ``config`` -- the filename for the configuration file, an example of which follows:
    """
    def __init__(self, worker_count=1, config=None):
        libgap.eval('LoadPackage("repsn")')
        self.default_cls = GroupGap
        Controller.__init__(self, worker_count, config)

    def _extra_init(self):
        # Parse the extent section
        cfgp = self.cfgp
        self.max_small_order = int(cfgp.get('extent', 'max_small_order'))
        self.task_limit = int(cfgp.get('extent', 'task_limit'))
        self.skips = map(int, cfgp.get('extent', 'skips').split(','))

    def recursively_add(self, G, subgroup_order_bound=None, quotient_order_bound=None, label=None):
        # Recursively add subquotients of G
        # TODO: add support for subgroup_order_bound and quotient_order_bound (maybe after switch to Magma?)
        N = ZZ(G.Size())
        if N <= self.max_small_order:
            return []
        if label is None:
            label = get_tmp_name(G)
        gp = GroupGap(G, label)
        all_gps = [gp]
        for H in gp.subgroup_lattice.subgroups[1:]:
            all_gps.extend(self.recursively_add(H.H, label=H.subgroup))
            if H.normal:
                # TODO: should we modify the pcgs?  GeneratorsOfGroup is quite long....
                all_gps.extend(self.recursively_add(G.FactorGroupNC(H.H), label=H.quotient))
        return all_gps

    class StageSmall(Stage):
        name = 'Generate Small'
        shortname = 'GenSmall'
        def intervals(self, N):
            M = ZZ(libgap.NumberSmallGroups(N))
            task_limit = self.controller.task_limit
            if M <= task_limit:
                yield (1, M+1)
            else:
                for a, b in zip(range(1, M+1, task_limit), range(1+task_limit, M+1, task_limit) + [M+1]):
                    yield (a, b)
        def finished(self, N):
            M = ZZ(libgap.NumberSmallGroups(N))
            desired_lines = ceil(M / self.controller.task_limit)
            with open(self.done.format(N=N)) as F:
                # Count lines
                for line in enumerate(F, 1):
                    pass
                return line == desired_lines

        @lazy_attribute
        def tasks(self):
            max_order = self.controller.max_small_order
            skips = self.controller.skips
            tasks = []
            for N in srange(1, max_order+1):
                if N in skips:
                    continue
                tasks.extend([self.Task(self, N, a, b) for (a,b) in self.intervals(N)])
            return tasks
        class Task(GenericTask):
            def __init__(self, stage, N, min_gid, max_gid):
                self.stage = stage
                self.N = ZZ(N)
                self.min_gid = min_gid
                self.max_gid = max_gid # not included
            def ready(self):
                return all(self.stage.finished(d) for d in self.N.divisors()[1:-1])
            @lazy_attribute
            def input_data(self):
                divisors = self.N.divisors()
                for d in divisors[1:-1]:
                    pass
            def run(self, logfile):
                stage = self.stage
                ctl = stage.controller
                groups = [GroupGap(label='%s.%s'%(self.N, gid)) for gid in range(self.min_gid, self.max_gid)]
                lattices = [gp.subgroup_lattice for gp in groups]
                character_tables = [gp.character_table for gp in groups]
                subgroups = sum([lat.subgroups[1:] for lat in lattices], [])
                conjugacy_classes = sum([tbl.conjugacy_classes[1:] for tbl in character_tables], [])
                characters = sum([tbl.characters[1:] for tbl in character_tables], [])
                cgroups = sum([tbl.cgroups[1:] for tbl in character_tables], [])
                for (filename, attributes), (items, cls) in zip(stage.output,
                    [(groups, GroupGap),
                     (subgroups, SubgroupGap),
                     (conjugacy_classes, ConjugacyClassGap),
                     (characters, CharacterGap),
                     (cgroups, CGroupGap)]):
                    filename = filename.format(N=self.N, minid=self.min_gid, maxid=self.max_gid)
                    ctl.save(filename, items, attributes, cls=cls)
                with open(stage.done.format(N=self.N), 'a') as done:
                    done.write('%s\n' % self.min_gid)

class Group(PGSaver):
    def __init__(self, G=None, label=None):
        # Automatically apply IsomorphismPermGroup?
        if label is not None:
            self.label = label
            order, which = label.split('.')
            self.order = ZZ(order)
            if self.order <= 2000 and self.order.valuation(2) <= 9: # We can create groups of order 512
                self.which = ZZ(which)
                if G is None:
                    G = self.driver.SmallGroup(self.order, self.which)
        if G is not None:
            self.G = G

    @pg_text
    def label(self):
        # Set in __init__ or externally
        raise NotImplementedError

    @pg_text
    def name(self):
        # TODO
        raise NotImplementedError

    @pg_text
    def tex_name(self):
        # TODO
        raise NotImplementedError

    @pg_numeric
    def order(self):
        return ZZ(self.Size(self.G))

    @pg_integer
    def which(self):
        return ZZ(tuple(self.IdGroup(self.G))[1])

    @pg_smallint_list
    def factored_order(self):
        return list(self.order.factor())

    @pg_integer
    def exponent(self):
        return ZZ(self.G.Exponent())

    @pg_boolean
    def abelian(self):
        return bool(self.G.IsAbelian())

    @pg_boolean
    def cyclic(self):
        return bool(self.G.IsCyclic())

    @pg_boolean
    def solvable(self):
        return bool(self.IsSolvable(self.G))

    @pg_boolean
    def supersolvable(self):
        return bool(self.IsSupersolvable(self.G))

    @pg_boolean
    def nilpotent(self):
        return bool(self.IsNilpotent(self.G))

    def _easy_metacyclic(self):
        if self.order.is_squarefree() or self.cyclic:
            return True
        if not self.solvable:
            return False
        if self.abelian:
            E = self.abelian_invariants
            pcounter = defaultdict(int)
            for m in E:
                p, e = m.is_prime_power(get_data=True)
                pcounter[p] += 1
                if pcounter[p] > 2:
                    return False
            return True

    @pg_boolean
    def metacyclic(self):
        return bool(self.IsMetacyclic(self.G))

    @pg_boolean
    def metabelian(self):
        return bool(self.G.DerivedSubgroup().IsAbelian())

    @pg_boolean
    def simple(self):
        return bool(self.G.IsSimple())

    @pg_boolean
    def almost_simple(self):
        return bool(self.IsAlmostSimple(self.G))

    @pg_boolean
    def quasisimple(self):
        return bool(self.IsQuasiSimple(self.G))

    @pg_boolean
    def perfect(self):
        return bool(self.IsPerfect(self.G))

    @pg_boolean
    def monomial(self):
        return bool(self.IsMonomial(self.G))

    @pg_boolean
    def rational(self):
        # We use an approach based on the subgroup lattice here; could also use the character table
        S = self.subgroup_lattice.subgroups
        for C in S:
            if C is None or not C.cyclic:
                continue
            n = C.subgroup_order
            weyl_order = S[C.normalizer].subgroup_order // S[C.centralizer].subgroup_order
            if weyl_order != euler_phi(n):
                return False
        return True

    @pg_boolean
    def Zgroup(self):
        # TODO: ideally this will be set when computing the subgroup lattice
        return all(self.G.SylowSubgroup(p).IsCyclic() for p, e in self.factored_order)

    @pg_boolean
    def Agroup(self):
        # TODO: ideally this will be set when computing the subgroup lattice
        return all(self.G.SylowSubgroup(p).IsAbelian() for p, e in self.factored_order)

    @pg_smallint
    def pgroup(self):
        F = self.factored_order
        if len(F) == 0:
            return ZZ(1)
        elif len(F) != 1:
            return ZZ(0)
        else:
            return F[0][0]

    @pg_integer
    def elementary(self):
        if not self.solvable:
            return ZZ(1)
        G = self.G
        return prod(p for (p, e), P, N in zip(self.factored_order,
                                              self.SylowSystem(G),
                                              self.ComplementSystem(G))
                    if N.IsCyclic() and G.IsNormal(N) and G.IsNormal(P))

    @pg_integer
    def hyperelementary(self):
        if not self.solvable:
            return ZZ(1)
        G = self.G
        return prod(p for (p, e), N in zip(self.factored_order,
                                              self.ComplementSystem(G))
                    if N.IsCyclic() and G.IsNormal(N))

    @pg_smallint
    def rank(self):
        return self._eulerian_data[0]

    @pg_numeric
    def eulerian_function(self):
        return self._eulerian_data[1]

    @pg_integer
    def center(self):
        return self.subgroup_lattice.identify(self.G.Center(), characteristic=True, abelian=True)

    @pg_integer
    def commutator(self):
        return self.subgroup_lattice.identify(self.G.DerivedSubgroup(), characteristic=True)

    @pg_integer
    def commutator_count(self):
        return ZZ(self.CommutatorLength(self.G))

    @pg_integer
    def frattini(self):
        return self.subgroup_lattice.identify(self.G.FrattiniSubgroup(), characteristic=True)

    @pg_integer
    def fitting(self):
        return self.subgroup_lattice.identify(self.G.FittingSubgroup(), characteristic=True)

    @pg_integer
    def radical(self):
        return self.subgroup_lattice.identify(self.Radical(self.G), characteristic=True)

    @pg_integer
    def socle(self):
        if self.solvable:
            abelian = True
        else:
            abelian = None
        return self.subgroup_lattice.identify(self.G.Socle(), characteristic=True, abelian=abelian)

    @pg_integer
    def smallrep(self):
        return self.character_table.smallrep

    @pg_numeric
    def aut_order(self):
        return ZZ(self.Size(self.G.AutomorphismGroup()))

    @pg_text
    def aut_group(self):
        A = self.G.AutomorphismGroup()
        # TODO: There might be an LMFDB label available even if IdGroup fails
        try:
            N, i = self.IdGroup(A)
            return '%s.%s'%(N,i)
        except Exception:
            return None

    @pg_numeric
    def outer_order(self):
        # Have to special case trivial group
        if self.order == 1:
            return ZZ(1)
        A = self.G.AutomorphismGroup()
        return ZZ(self.OuterOrder(A))

    @pg_text
    def outer_group(self):
        A = self.G.AutomorphismGroup()
        O = self.OuterGroup(A)
        # TODO: There might be an LMFDB label available even if IdGroup fails
        try:
            N, i = self.IdGroup(O)
            return '%s.%s'%(N,i)
        except Exception:
            return None

    @pg_smallint
    def nilpotency_class(self):
        if self.nilpotent:
            return ZZ(self.NilpotencyClass(self.G))
        else:
            return ZZ(-1)

    @pg_integer_list
    def sylow_subgroups(self):
        return sorted((C.sylow, C.which) for C in self.subgroup_lattice.subgroups[1:] if C.sylow)

    @pg_smallint
    def elt_rep_type(self):
        if self.IsPcGroup(self.G):
            return 0
        elif self.IsPermGroup(self.G):
            return -ZZ(self.Degree(self.G))
        elif self.IsMatrixGroup(self.G):
            K = self.CoefficientRing(self.G)
            if K.IsFinite():
                return ZZ(self.RingSize(K))
            else:
                return ZZ(1)

    @pg_smallint
    def ngens(self):
        # Magma has a special method for ngens, but this should be fine
        return len(self.Generators(self.G))

    @pg_numeric
    def pc_code(self):
        # Encoded relations for Pcgs groups
        if self.elt_rep_type == 0:
            return ZZ(self.EncodePcGroup(self.G))
        # Otherwise return None

    @pg_integer
    def transitive_degree(self):
        if self.subgroups_known:
            return min(C.quotient_order for C in self.subgroup_lattice.subgroups[1:] if C.core == 1)

    @pg_integer
    def transitive_subgroup(self):
        if self.subgroups_known:
            if self.transitive_degree <= TRANSITIVE_IDENTIFICATION_BOUND:
                candidates = [(int(C.coset_action_label.split('T')[1]), C.which) for C in self.subgroup_lattice.subgroups[1:] if C.quotient_order == self.transitive_degree and C.core == 1]
                tid, which = min(candidates)
                return which
            else:
                for C in self.subgroup_lattice.subgroups[1:]:
                    if C.core == 1 and C.quotient_order == self.transitive_degree:
                        return C.which

    def encode(self, g):
        # Encode into an integer using a method based on the value of elt_rep_type
        ert = self.elt_rep_type
        if ert == 0:
            return self.encode_as_pcgs(g)
        elif ert < 0:
            return self.encode_as_perm(g, -ert)
        else:
            # TODO: deal with matrices
            raise NotImplementedError

    def decode(self, code):
        ert = self.elt_rep_type
        if ert == 0:
            return self.decode_as_pcgs(code)
        elif ert < 0:
            return self.decode_as_perm(code, -ert)
        else:
            # TODO: deal with matrices
            raise NotImplementedError

    @lazy_attribute
    def pcgs_relative_orders(self):
        ords = map(ZZ, self.RelativeOrders(self.G))
        if prod(ords) != self.order:
            raise RuntimeError("Order mismatch")
        return ords

    def encode_as_pcgs(self, g):
        vec = map(ZZ, self.Eltseq(g))
        code = 0
        for e, m in zip(vec, self.pcgs_relative_orders):
            code *= m
            code += e
        return code

    def decode_as_pcgs(self, code):
        vec = []
        if code < 0 or code >= self.order:
            raise ValueError
        for m in reversed(self.pcgs_relative_orders):
            c = code % m
            vec.insert(0, c)
            code = code // m
        return self.PcElementByExponents(vec)

    @pg_numeric_list
    def perm_gens(self):
        # Encoded generators as a permutation group.  NULL if the minimal degree is too large.
        G = self.G
        if self.IsPermGroup(G):
            n = -self.elt_rep_type # largest moved point
            gens = self.Generators(G)
        elif not self.abelian and self.subgroups_known and self.transitive_degree <= TRANSITIVE_DEGREE_BOUND:
            n = self.transitive_degree
            H = self.subgroup_lattice.subgroups[self.transitive_subgroup].H
            # TODO: This will not be a minimal set of generators, but rather the image of a pcgs
            gens = self.Generators(self.CosetImage(G, H))
        else:
            return None
        return [self.encode_as_perm(g, n) for g in gens]

    @lazy_attribute
    def G(self):
        # Reconstruct the group from the data stored above
        if self.elt_rep_type == 0: # PcGroup
            return self.DecodePcGroup(self.pc_code, self.order)
        elif self.elt_rep_type < 0: # Permutation group
            gens = [self.decode(g) for g in self.perm_gens]
            return self.PermGroup(gens, -self.elt_rep_type)
        else:
            # TODO: Matrix groups
            raise NotImplementedError

    @pg_integer
    def number_conjugacy_classes(self):
        return ZZ(self.NrConjugacyClasses(self.G))

    @pg_integer
    def number_subgroup_classes(self):
        # The - 1  is from the leading None used to align the numbering between GAP and Python conventions
        return len(self.subgroup_lattice.subgroups) - 1

    @pg_integer
    def number_subgroups(self):
        return sum(C.count for C in self.subgroup_lattice.subgroups[1:])

    @pg_integer
    def number_normal_subgroups(self):
        return len([C for C in self.subgroup_lattice.subgroups[1:] if C.normal])

    @pg_integer
    def number_characteristic_subgroups(self):
        return len([C for C in self.subgroup_lattice.subgroups[1:] if C.characteristic])

    @pg_integer_list
    def derived_series(self):
        return [self.subgroup_lattice.identify(H, characteristic=True) for H in self.G.DerivedSeries()]

    @pg_smallint
    def derived_length(self):
        return ZZ(self.G.DerivedLength()) # could also do len(self.derived_series) - 1

    @pg_integer
    def perfect_core(self):
        return self.derived_series[-1]

    @pg_integer_list
    def chief_series(self):
        return [self.subgroup_lattice.identify(H, normal=True) for H in self.G.ChiefSeries()]

    @pg_integer_list
    def lower_central_series(self):
        return [self.subgroup_lattice.identify(H, normal=True) for H in self.G.LowerCentralSeries()]

    @pg_integer_list
    def upper_central_series(self):
        return [self.subgroup_lattice.identify(H, normal=True) for H in self.UpperCentralSeries(self.G)]

    # Magma and GAP define different abelian invariants, so we define each in terms of the other
    @lazy_attribute
    def _pparts(self):
        invs = self.primary_abelian_invariants
        parts = defaultdict(list)
        for q in invs:
            p, e = q.is_prime_power(get_data=True)
            parts[p].append(e)
        return parts
    @pg_integer_list
    def smith_abelian_invariants(self):
        parts = self._pparts
        return list(reversed(map(prod, izip_longest(*map(reversed, parts.values()), fillvalue=1))))
    @pg_integer_list
    def primary_abelian_invariants(self):
        return sorted(flatten([[p**e for p,e in a.factor()] for a in self.smith_abelian_invariants]))

    def _number_subgroups_abelian(self):
        """
        Count the number of subgroups of an abelian group.
        """
        parts = self._pparts
        total = 1
        def add_down(D, P):
            """
            Add the partition P and all down partitions to D (recursively)
            """
            m = sum(P)
            t = tuple(P)
            if t in D[m]:
                return
            D[m].add(t)
            for Q in P.down():
                add_down(D, Q)
        for p, nu in parts.items():
            pcontribution = 0
            nu = Partition(reversed(nu))
            partitions = defaultdict(set)
            add_down(partitions, nu)
            M = sum(nu)
            for m in range(M+1):
                for mu in partitions[m]:
                    for la in partitions[M-m]:
                        pcontribution += hall_polynomial(nu, mu, la, p)
            total *= pcontribution
        return total

    @pg_integer_list
    def schur_multiplier(self):
        return map(ZZ, self.AbelianInvariantsMultiplier(self.G))

    @pg_boolean
    def all_subgroups_known(self):
        # TODO: decide when this should be False
        return True

    @pg_boolean
    def normal_subgroups_known(self):
        return True

    @pg_smallint
    def maximal_subgroups_known(self):
        # TODO: figure out the plan for this
        return True

    @pg_boolean
    def subgroup_inclusions_known(self):
        # TODO: decide when this should be False
        return True

    @pg_smallint
    def subgroup_index_bound(self):
        # TODO: figure out the plan for this
        pass

    @pg_smallint
    def subgroup_order_bound(self):
        # TODO: figure out the plan for this
        pass

    @pg_boolean
    def outer_equivalence(self):
        # Need a better way of deciding whether to use inner/outer subgroup equivalence
        return self.abelian and self._number_subgroups_abelian() > 70

    def get_tmp_name(self, G, order=None):
        if order is None:
            order = ZZ(self.Size(G))
        if order <= 2000 and order.valuation(2) < 9:
            N, i = map(ZZ, self.IdGroup(G))
            if N != order:
                raise RuntimeError
            return "%s.%s" % (N, i)
        else:
            # We make up a temporary name that will be revised once all groups are computed
            return "%s.%s" % (order, ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(30)))

class MagmaMixin(object):
    """
    Function definitions used in multiple Gap-implemented classes
    """
    Size = staticmethod(magma.Order)
    IdGroup = staticmethod(magma.IdentifyGroup)
    FactorGroupNC = staticmethod(lambda G,H: G/H)
    IsPerfect = staticmethod(magma.IsPerfect)
    CosetImage = staticmethod(magma.CosetImage)
    TransitiveIdentification = staticmethod(magma.TransitiveGroupIdentification)
    PseudoRandom = staticmethod(magma.Random)

class GroupMagma(Group, MagmaMixin):
    """
    An object representing a group computed in Magma, to be saved to the gps_groups table
    """
    driver = magma
    IsSolvable = staticmethod(magma.IsSolvable)
    def IsSupersolvable(self, G):
        if not G.IsSolvable():
            return False
        if G.IsNilpotent():
            return True
        C = [ZZ(H.Order()) for H in G.ChiefSeries()]
        for a, b in zip(C[:-1], C[1:]):
            if not (a // b).is_prime():
                return False
        return True
    IsNilpotent = staticmethod(magma.IsNilpotent)
    def IsMetacyclic(self, G):
        ans = self._easy_metacyclic()
        if ans is not None:
            return ans
        if self.pgroup:
            return G.IsMetacyclicPGroup()
        D = G.DerivedSubgroup()
        if not D.IsCyclic():
            return False
        # We could pull back from the quotient, but I can't figure out how to construct the natural homomorphism to the quotient.
        for N in G.Subgroups(D, Normal=True):
            if N.IsCyclic() and magma.new('%s subset %s' % (D.name(), N.name())):
                Q = G / N
                if Q.IsCyclic():
                    return True
        return False
    def IsAlmostSimple(self, G):
        # In order to be almost simple, we need a simple nonabelian normal subgroup with trivial centralizer
        if self.abelian or self.solvable:
            return False
        for N in G.NormalSubgroups():
            if N.IsSimple() and G.Centralizer(N).Order() == 1:
                return True
        return False
    def IsQuasiSimple(self, G):
        return self.perfect and (G / G.Center()).IsSimple()
    def IsMonomial(self, G):
        if not self.solvable:
            return False
        if self.supersolvable or (self.solvable and self.Agroup):
            return True
        # TODO
        raise NotImplementedError
    SylowSystem = staticmethod(magma.SylowBasis)
    ComplementSystem = staticmethod(magma.ComplementBasis)
    Radical = staticmethod(magma.Radical)
    @lazy_attribute
    def _eulerian_data(self):
        # TODO: I don't know how to compute this in Magma
        raise NotImplementedError
    OuterOrder = staticmethod(magma.OuterOrder)
    OuterGroup = staticmethod(magma.OuterFPGroup)
    NilpotencyClass = staticmethod(magma.NilpotencyClass)
    def IsPcGroup(self, G):
        return G.Category() == magma('GrpPC')
    def IsPermGroup(self, G):
        return G.Category() == magma('GrpPerm')
    def IsMatrixGroup(self, G):
        return G.Category() == magma('GrpMat')
    Degree = staticmethod(magma.Degree)
    CoefficientRing = staticmethod(magma.CoefficientRing)
    def RingSize(self, R):
        return magma('#%s'%R.name())
    Generators = staticmethod(magma.Generators)
    EncodePcGroup = staticmethod(magma.SmallGroupEncoding)
    DecodePcGroup = staticmethod(magma.SmallGroupDecoding)
    def PermGroup(self, gens, n):
        # all gens should have the same degree
        return magma('PermutationGroup<%s|%s>' % (n, ', '.join(map(str, gens))))
    def encode_as_perm(self, g, n):
        # g should be an element of S_n
        S = SymmetricGroup(n)
        P = Permutations(n)
        return P(S(map(tuple, g.CycleDecomposition().sage()))).rank()
    def decode_as_perm(self, code, n):
        # code should be an integer with 0 <= m < factorial(n)
        S = SymmetricGroup(n)
        P = Permutations(n)
        # This function is used in reconstructing G, so we don't have it available
        return magma('SymmetricGroup(%s)!%s' % (n, S(P.unrank(code))))
    RelativeOrders = staticmethod(magma.PCPrimes)
    Eltseq = staticmethod(magma.Eltseq)
    def PcElementByExponents(self, vec):
        return magma('%s!%s' % (self.G.name(), vec))

    NrConjugacyClasses = staticmethod(magma.Nclasses)
    def UpperCentralSeries(self, G):
        # Magma has a different order for the upper central series than GAP does; we reverse to agree with GAP
        return reversed(G.UpperCentralSeries())

    @pg_integer_list
    def smith_abelian_invariants(self):
        return map(ZZ, self.G.AbelianInvariants())

    def AbelianInvariantsMultiplier(self, G):
        ans = []
        for p, e in self.factored_order:
            ans.extend([ZZ(c) for c in G.pMultiplicator(p) if c > 1])
        return sorted(ans)

    @pg_numeric_list
    def order_stats(self):
        D = defaultdict(int)
        for C in self.G.ConjugacyClasses():
            D[ZZ(C[1])] += ZZ(C[2])
        return sorted(D.items())

    @lazy_attribute
    def subgroup_lattice(self):
        return SubgroupLatticeMagma(self)

    @lazy_attribute
    def character_table(self):
        return CharacterTableMagma(self)

class GapMixin(object):
    """
    Function definitions used in multiple Gap-implemented classes
    """
    Size = staticmethod(libgap.Size)
    IdGroup = staticmethod(libgap.IdGroup)
    FactorGroupNC = staticmethod(libgap.FactorGroupNC)
    IsPerfect = staticmethod(libgap.IsPerfectGroup)
    @staticmethod
    def CosetImage(G, H):
        return G.FactorCosetAction(H).Image()
    TransitiveIdentification = staticmethod(libgap.TransitiveIdentification)
    PseudoRandom = staticmethod(libgap.PseudoRandom)

class GroupGap(Group, GapMixin):
    """
    An object representing a group computed in GAP, to be saved to the gps_groups table

    Note that various attributes must be filled in externally:

    - the `label` and `which` if the order has 2-adic valuation at least 9 or is larger than 2000.
    - the `name`
    - the `tex_name`
    - the `aliases`
    - the `tex_aliases`
    """
    driver = libgap
    IsSolvable = staticmethod(libgap.IsSolvableGroup)
    IsSupersolvable = staticmethod(libgap.IsSupersolvableGroup)
    IsNilpotent = staticmethod(libgap.IsNilpotentGroup)
    def IsMetacyclic(self, G):
        ans = self._easy_metacyclic()
        if ans is not None:
            return ans
        D = G.DerivedSubgroup()
        if not D.IsCyclic():
            return False
        for N in G.NormalSubgroupsAbove(D,[]):
            if N.IsCyclic() and G.FactorGroup(N).IsCyclic():
                return True
        return False
    IsAlmostSimple = staticmethod(libgap.IsAlmostSimpleGroup)
    def IsQuasiSimple(self, G):
        return self.perfect and G.FactorGroup(G.Center()).IsSimpleGroup()
    IsMonomial = staticmethod(libgap.IsMonomial)
    SylowSystem = staticmethod(libgap.SylowSystem)
    ComplementSystem = staticmethod(libgap.ComplementSystem)
    CommutatorLength = staticmethod(libgap.CommutatorLength)
    Radical = staticmethod(libgap.RadicalGroup)
    @staticmethod
    def OuterOrder(A):
        I = A.InnerAutomorphismsAutomorphismGroup()
        return ZZ(A.Size()) // ZZ(I.Size())
    @staticmethod
    def OuterGroup(A):
        I = A.InnerAutomorphismsAutomorphismGroup()
        return A.FactorGroup(I)
    NilpotencyClass = staticmethod(libgap.NilpotencyClassOfGroup)
    IsPcGroup = staticmethod(libgap.IsPcGroup)
    IsPermGroup = staticmethod(libgap.IsPermGroup)
    IsMatrixGroup = staticmethod(libgap.IsMatrixGroup)
    Degree = staticmethod(libgap.LargestMovedPoint)
    CoefficientRing = staticmethod(libgap.DefaultFieldOfMatrixGroup)
    RingSize = staticmethod(libgap.Size)
    Generators = staticmethod(libgap.GeneratorsOfGroup)
    EncodePcGroup = staticmethod(libgap.CodePcGroup)
    DecodePcGroup = staticmethod(libgap.PcGroupCode)
    @staticmethod
    def PermGroup(gens, n):
        return libgap.Group(gens)

    @lazy_attribute
    def _eulerian_data(self):
        if self.cyclic:
            return (ZZ(1), ZZ(1))
        G = self.G
        r = ZZ(2)
        a = ZZ(G.AutomorphismGroup().Size())
        while True:
            E = ZZ(G.EulerianFunction(r))
            if E > 0:
                if E % a != 0:
                    raise RuntimeError
                return r, (E // a)
            r += 1

    @staticmethod
    def encode_as_perm(g, n):
        # g should be an element of S_n
        return Permutations(n)(g.sage()).rank()
    @staticmethod
    def decode_as_perm(code, n):
        # code should be an integer with 0 <= m < factorial(n)
        return SymmetricGroup(n)(Permutations(n).unrank(code))

    @lazy_attribute
    def pcgs(self):
        return self.G.Pcgs()
    def RelativeOrders(self, G):
        return self.pcgs.RelativeOrders()
    def Eltseq(self, g):
        return self.pcgs.ExponentsOfPcElement(g)
    def PcElementByExponents(self, vec):
        return self.pcgs.PcElementByExponents(vec)

    NrConjugacyClasses = staticmethod(libgap.NrConjugacyClasses)
    UpperCentralSeries = staticmethod(libgap.UpperCentralSeries)

    @pg_integer_list
    def primary_abelian_invariants(self):
        return map(ZZ, self.G.AbelianInvariants())

    AbelianInvariantsMultiplier = staticmethod(AbelianInvariantsMultiplier)

    @pg_numeric_list
    def order_stats(self):
        D = defaultdict(int)
        for C in self.G.ConjugacyClasses():
            D[ZZ(C.Representative().Order())] += ZZ(C.Size())
        return sorted(D.items())

    @lazy_attribute
    def subgroup_lattice(self):
        return SubgroupLatticeGap(self)

    @lazy_attribute
    def character_table(self):
        return CharacterTableGap(self)

class Subgroup(PGSaver):
    def __init__(self, lattice, H, which, count, contains, contained_in, outer=False):
        self.lattice = lattice
        self.G = lattice.G
        self.H = H
        self.which = which
        self.count = count
        self.contains = contains
        self.contained_in = contained_in
        self.outer_equivalence = outer

    @pg_text
    def label(self):
        # TODO: should this include an indication of whether we're using outer equivalence?
        return "%s.%s" % (self.ambient, self.which)

    @pg_boolean
    def outer_equivalence(self):
        # Set in __init__
        raise NotImplementedError

    @pg_integer
    def which(self):
        # Set in __init__
        raise NotImplementedError

    @pg_integer
    def aut_which(self):
        # TODO
        raise NotImplementedError

    @pg_integer
    def extension_which(self):
        # TODO: waiting for Tim's description
        raise NotImplementedError

    @pg_text
    def subgroup(self):
        return self.lattice.gp.get_tmp_name(self.H, self.subgroup_order)

    @pg_numeric
    def subgroup_order(self):
        return ZZ(self.Size(self.H))

    @pg_text
    def ambient(self):
        return self.lattice.gp.label

    @pg_numeric
    def ambient_order(self):
        return self.lattice.gp.order

    @pg_text
    def quotient(self):
        # special case the trivial group so that we don't have to do isomorphism testing
        if self.subgroup_order == 1:
            return self.ambient
        elif self.quotient_order == 1:
            return '1.1'
        elif self.normal:
            return self.lattice.gp.get_tmp_name(self.FactorGroupNC(self.G, self.H), self.quotient_order)

    @pg_numeric
    def quotient_order(self):
        return self.ambient_order // self.subgroup_order

    @pg_boolean
    def normal(self):
        return bool(self.G.IsNormal(self.H))

    @pg_boolean
    def characteristic(self):
        return bool(self.IsCharacteristic(self.G, self.H))

    @pg_boolean
    def cyclic(self):
        return bool(self.H.IsCyclic())

    @pg_boolean
    def abelian(self):
        return bool(self.H.IsAbelian())

    @pg_boolean
    def perfect(self):
        return bool(self.IsPerfect(self.H))

    @pg_smallint
    def sylow(self):
        if self.hall and self.subgroup_order.is_prime_power():
            return self.hall
        else:
            return ZZ(0)

    @pg_numeric
    def hall(self):
        if self.subgroup_order.gcd(self.quotient_order) == 1:
            return self.subgroup_order.radical()
        else:
            return ZZ(0)

    @pg_boolean
    def maximal(self):
        return self.contained_in == [self.lattice.gp.number_subgroup_classes]

    @pg_boolean
    def maximal_normal(self):
        if not self.normal:
            return False
        if self.maximal:
            return True
        if self.lattice.gp.solvable:
            return self.quotient_order.is_prime()
        self.lattice._set_maximal_normal()
        return self.maximal_normal

    @pg_boolean
    def minimal(self):
        return self.subgroup_order.is_prime()

    @pg_boolean
    def minimal_normal(self):
        if not self.normal:
            return False
        if self.minimal:
            return True
        if self.lattice.gp.nilpotent:
            return False
        self.lattice._set_minimal_normal()
        return self.minimal_normal

    @pg_boolean
    def split(self):
        if not self.normal:
            return None
        return len(self.complements) > 0

    @pg_integer_list
    def complements(self):
        # TODO: for solvable groups there is also the ComplementClassesRepresentatives method available; should check if that's faster
        # TODO: when N is not normal, the size of the intersection could depend on the choice of representative subgroups
        N = self.H
        desired_order = self.quotient_order
        return sorted(i for i, H in enumerate(self.lattice.subgroups[1:],1)
                      if H.subgroup_order == desired_order and
                      self.Size(self.Intersection(N, H.H)) == 1)

    @pg_boolean
    def direct(self):
        if not self.normal:
            return None
        S = self.lattice.subgroups
        return any(S[i].normal for i in self.complements)

    @pg_boolean
    def central(self):
        return bool(self.IsCentral(self.G, self.H))

    @pg_boolean
    def stem(self):
        return self.central and self.IsSubset(self.G.DerivedSubgroup(), self.H)

    @pg_numeric
    def count(self):
        # Set in __init__
        raise NotImplementedError

    @pg_numeric
    def conjugacy_class_count(self):
        if self.outer_equivalence:
            if self.abelian:
                return self.count
            else:
                # TODO
                raise NotImplementedError

    @pg_integer
    def core(self):
        if self.normal:
            return self.which
        else:
            return self.lattice.identify(self.G.Core(self.H), normal=True)

    @pg_text
    def coset_action_label(self):
        # Have to special case the trivial group
        if self.ambient_order == 1:
            return '1T1'
        if self.core == 1 and self.quotient_order <= TRANSITIVE_IDENTIFICATION_BOUND:
            F = self.CosetImage(self.G, self.H)
            tid = self.TransitiveIdentification(F)
            return '%sT%s'%(self.quotient_order, tid)

    @pg_integer
    def normalizer(self):
        # For Magma, set in __init__
        if self.normal:
            return self.lattice.gp.number_subgroup_classes
        else:
            return self.lattice.identify(self.G.Normalizer(self.H))

    @pg_integer
    def centralizer(self):
        # For Magma, set in __init__
        if self.central:
            return self.lattice.gp.number_subgroup_classes
        else:
            return self.lattice.identify(self.G.Centralizer(self.H))

    @pg_integer
    def normal_closure(self):
        if self.normal:
            return self.which
        else:
            # TODO: could do this just using the lattice
            return self.lattice.identify(self.G.NormalClosure(self.H), normal=True)

    @pg_integer
    def quotient_action_kernel(self):
        # TODO
        # Need the subgroup lattice for Q, which isn't easily available
        if not self.normal:
            return None
        if self.split:
            # Intersection of centralizer of H with a complement
            pass
        elif self.H.IsAbelian():
            # It doesn't matter how we lift elements of Q:
            # The image of the centralizer of H in Q is the kernel
            pass
        else:
            # Set C to be the subgroup generated by H and its centralizer.  Maybe the image of C in Q?
            pass

    @pg_integer_list
    def contains(self):
        # Set in __init__
        raise NotImplementedError

    @pg_integer_list
    def contained_in(self):
        # Set in __init__
        raise NotImplementedError

    @pg_jsonb
    def quotient_fusion(self):
        # TODO
        # Need to compute conjugacy classes first
        pass

    @pg_integer_list
    def subgroup_fusion(self):
        # TODO
        # Need to compute conjugacy classes first
        pass

    @pg_smallint
    def alias_spot(self):
        # TODO
        # Waiting for response from Tim on numbering scheme for extensions.
        # Also, this will be set externally
        raise NotImplementedError

    @lazy_attribute
    def generating_elt(self):
        # An element of `H` that generates `H` along with the smallest-numbered maximal subgroup `K` of `H`.
        # We can choose any element of `H` that is not in `K`
        if self.which == 1: # trivial subgroup
            return None
        K = self.lattice.subgroups[self.contains[0]]
        # TODO: K might only be conjugate to a subgroup of H, not necessarily a subgroup itself
        # Constructing right transversals could be expensive, so we use PseudoRandom, which will lie outside K with probability at least 1/2.
        while True:
            x = self.PseudoRandom(self.H)
            if not self.Contains(K, x):
                return x
        # The following would be a deterministic way to find an element
        #T = self.H.RightTransversal(K)
        # Since K != H, T has length at least 2 and T[2] is not in K
        #return T[2]

    @pg_numeric
    def new_gen(self):
        return self.lattice.gp.encode(self.generating_elt)

class SubgroupMagma(Subgroup, MagmaMixin):
    @staticmethod
    def IsCharacteristic(G, H):
        if not G.IsNormal(H):
            return False
        A = G.AutomorphismGroup()
        for phi in A.Generators():
            if not phi.IsInner():
                phiH = magma('%s(%s)' % (phi.name(), H.name()))
                if phiH != H:
                    return False
        return True
    @staticmethod
    def Intersection(A, B):
        return magma('%s meet %s' % (A.name(), B.name()))
    IsCentral = magma.IsCentral
    @staticmethod
    def IsSubset(A, B):
        # We use GAP's convention on ordering: this tests whether B is a subset of A
        return magma('%s subset %s' % (B.name(), A.name()))
    @staticmethod
    def Contains(X, x):
        return magma('%s in %s' % (x.name(), X.name()))

class SubgroupGap(Subgroup, GapMixin):
    IsCharacteristic = libgap.IsCharacteristicSubgroup
    Intersection = libgap.Intersection
    IsCentral = libgap.IsCentral
    IsSubset = libgap.IsSubset
    @staticmethod
    def Contains(X, x):
        return x in X

class SubgroupLattice(object):
    """
    An object representing the lattice of subgroups up to conjugacy.
    """
    def __init__(self, gp):
        self.gp = gp # Group object
        self.G = gp.G # GAP/Magma group
        self.outer_equivalence = gp.outer_equivalence

class SubgroupLatticeMagma(SubgroupLattice):
    @lazy_attribute
    def subgroups(self):
        """
        A representative from each class of subgroups
        """
        subgroups = [None] # shift by 1 to align with Magma's numbering
        G = self.G
        gp = self.gp
        if gp.subgroup_inclusions_known:
            # Check option consistency
            if not (gp.all_subgroups_known and gp.normal_subgroups_known and gp.maximal_subgroups_known and gp.subgroup_index_bound is None and gp.subgroup_order_bound is None):
                raise ValueError("Inconsistent options")
            # TODO: doesn't work for matrix groups
            self.L = L = G.SubgroupLattice(Properties=True, Normalizers=True, Centralizers=True)
            LG = L.Top()
            for i in range(1,len(L)+1):
                elt = magma('%s!%s' % (L.name(), i))
                H = elt.Group()
                subs = map(ZZ, elt.MaximalSubgroups())
                sups = map(ZZ, elt.MinimalOvergroups())
                count = ZZ(elt.Length())
                # TODO: deal with the case of outer=True
                C = SubgroupMagma(self, H, i, count, subs, sups, outer=self.outer_equivalence)
                C.order = ZZ(elt.Order())
                C.centralizer = ZZ(LG.Centralizer(elt))
                C.normalizer = ZZ(LG.Normalizer(elt))
                subgroups.append(C)
        elif gp.all_subgroups_known:
            if not (gp.normal_subgroups_known and gp.maximal_subgroups_known and gp.subgroup_index_bound is None and gp.subgroup_order_bound is None):
                raise ValueError("Inconsistent options")
            for i, elt in enumerate(G.Subgroups(), 1):
                H = magma('%s`subgroup' % (elt.name()))
                count = ZZ(magma('%s`length' % (elt.name())))
                order = ZZ(magma('%s`order' % (elt.name())))
                # TODO: deal with the case of outer=True
                C = SubgroupMagma(self, H, i, count, None, None, outer=self.outer_equivalence)
                # TODO: set the attributes which depend on the lattice: maximal, maximal_normal, minimal, minimal_normal, normalizer?, centralizer?, new_gen
                subgroups.append(C)
        else:
            # TODO: do some of these options require a permutation group?
            Hs = []
            bound = gp.subgroup_index_bound
            Gorder = gp.order
            normals = gp.normal_subgroups_known
            if bound is not None:
                Hs.extend(G.Subgroups(IndexLimit=gp.subgroup_index_bound))
            # TODO: do we want to support subgroup_order_bound?
            if normals:
                for Nrec in G.NormalSubgroups():
                    order = ZZ(magma('%s`order' % (Nrec.name())))
                    if bound is None or bound * order < Gorder:
                        Hs.append(Nrec)
            if gp.maximal_subgroups_known:
                for Hrec in G.MaximalSubgroups():
                    order = ZZ(magma('%s`order' % (Hrec.name())))
                    H = magma('%s`subgroup' % (Hrec.name()))
                    if ((bound is None or bound * order < Gorder) and
                        not (normals and G.IsNormal(H))):
                        Hs.append(Hrec)
            # TODO: finish this case
            subgroups.extend(G.NormalSubgroups())
        return subgroups

class SubgroupLatticeGap(SubgroupLattice):
    @lazy_attribute
    def subgroups(self):
        """
        A representative from each class of subgroups
        """
        subgroups = [None] # shift by 1 to align with GAP's numbering
        G = self.G
        L = G.LatticeSubgroups()
        max_subs = L.MaximalSubgroupsLattice()
        min_sups = L.MinimalSupergroupsLattice()
        for i, (C, subs, sups) in enumerate(zip(L.ConjugacyClassesSubgroups(), max_subs, min_sups), 1):
            H = C.ClassElementLattice(1)
            subs = sorted(set(ZZ(c) for c,k in subs))
            sups = sorted(set(ZZ(c) for c,k in sups))
            count = ZZ(C.Size())
            # TODO: deal with the case of outer=True
            subgroups.append(SubgroupGap(self, H, i, count, subs, sups, outer=self.outer_equivalence))
        return subgroups

    @lazy_attribute
    def subgroups_of_order(self):
        res = defaultdict(list)
        for i, C in enumerate(self.subgroups[1:],1):
            res[C.subgroup_order].append(i)
        return res

    def identify(self, H, normal=None, characteristic=None, abelian=None):
        """
        Given a GAP subgroup H, identify which conjugacy class it belongs to.
        """
        # For now we just do something simple:
        m = ZZ(H.Size())
        # If there is only one subgroup of the appropriate size, return it.
        if len(self.subgroups_of_order[m]) == 1:
            return self.subgroups_of_order[m][0]
        if characteristic:
            normal = True
        if normal is None:
            normal = bool(self.G.IsNormal(H))
        for i in self.subgroups_of_order[m]:
            C = self.subgroups[i]
            if normal is not None and C.normal != normal:
                continue
            if characteristic is not None and C.characteristic != characteristic:
                continue
            if abelian is not None and C.abelian != abelian:
                continue
            if (normal and H == C.H) or (not normal and self.G.IsConjugate(H, C.H)):
                return i
        raise RuntimeError

    def _set_maximal_normal(self):
        # Since we want to set the value of maximal_normal for all subgroups,
        # for non-solvable groups it's better to do all at once rather than individually
        S = self.subgroups
        seen = set()
        def mark_subs(cur, value):
            recurse = set()
            for next in S[cur].contains:
                if next in seen:
                    continue
                seen.add(next)
                H = S[next]
                if value is None:
                    if H.normal:
                        H.maximal_normal = True
                        mark_subs(next, False)
                    else:
                        H.maximal_normal = False
                        recurse.add(next)
                else: # value = False
                    H.maximal_normal = False
                    mark_subs(next, False)
            # Now recurse for subgroups that haven't been marked
            for next in recurse:
                mark_subs(next, None)

        cur = self.number_subgroup_classes
        S[cur].maximal_normal = False
        seen.add(cur)
        mark_subs(cur, None)

    def _set_minimal_normal(self):
        # Since we want to set the value of minimal_normal for all subgroups,
        # for non-nilpotent groups it's better to do all at once rather than individually
        S = self.subgroups
        seen = set()
        def mark_sups(cur, value):
            recurse = set()
            for next in S[cur].contained_in:
                if next in seen:
                    continue
                seen.add(next)
                H = S[next]
                if value is None:
                    if H.normal:
                        H.minimal_normal = True
                        mark_sups(next, False)
                    else:
                        H.minimal_normal = False
                        recurse.add(next)
                else: # value = False
                    H.minimal_normal = False
                    mark_sups(next, False)
            # Now recurse for supergroups that haven't been marked
            for next in recurse:
                mark_sups(next, None)

        S[1].minimal_normal = False
        seen.add(1)
        mark_sups(1, None)

class ConjugacyClassGap(PGSaver):
    def __init__(self, char_table, C, which, label, outer=False):
        self.char_table = char_table
        self.C = C
        self.G = self.char_table.G
        self.which = which
        self.label = label
        self.outer_equivalence = outer

    @pg_text
    def label(self):
        # TODO: should this include an indication of whether we're using outer equivalence?
        # Set in __init__
        raise NotImplementedError

    @pg_boolean
    def outer_equivalence(self):
        # Set in __init__
        raise NotImplementedError

    @pg_text
    def group(self):
        return self.char_table.gp.label

    @pg_integer
    def size(self):
        return ZZ(self.C.Size())

    @pg_integer
    def which(self):
        # Set in __init__
        raise NotImplementedError

    @pg_integer
    def order(self):
        return ZZ(self.C.Representative().Order())

    @pg_integer
    def centralizer(self):
        lat = self.char_table.gp.subgroup_lattice
        H = self.G.Centralizer(self.C.Representative())
        return lat.identify(H)

    @pg_integer_list
    def powers(self):
        ans = []
        x = self.C.Representative()
        n = self.order
        for p, e in self.char_table.gp.factored_order:
            m = n if (n%p != 0) else n//p
            ans.append(self.char_table.identify_conjugacy_class(x**p, order=m))
        return ans

class CharacterGap(PGSaver):
    def __init__(self, char_table, chi, which):
        self.char_table = char_table
        self.chi = chi
        self.which = which

    @pg_text
    def label(self):
        return '%s.%s' % (self.group, self.which)

    @pg_text
    def atlas_label(self):
        # TODO
        raise NotImplementedError

    @pg_text
    def group(self):
        return self.char_table.gp.label

    @pg_smallint
    def dim(self):
        return ZZ(self.chi.DegreeOfCharacter())

    @pg_smallint
    def which(self):
        # Set in __init__
        raise NotImplementedError

    @pg_integer
    def kernel(self):
        lat = self.char_table.gp.subgroup_lattice
        return lat.identify(self.chi.KernelOfCharacter(), normal=True)

    @pg_boolean
    def faithful(self):
        return self.kernel == 1

    @pg_text
    def image(self):
        # TODO
        raise NotImplementedError

class CGroupGap(PGSaver):
    """
    A subgroup of GL_n(C), given as a faithful character of a group
    """
    def __init__(self, char_table, chi, label):
        self.char_table = char_table
        self.chi = chi
        self.label = label

    @pg_text
    def label(self):
        # Set in __init__
        raise NotImplementedError

    @pg_smallint
    def dim(self):
        return ZZ(self.chi.DegreeOfCharacter())

    @pg_numeric
    def order(self):
        return self.char_table.gp.order

    @pg_text
    def group(self):
        return self.char_table.gp.label

    @pg_boolean
    def irreducible(self):
        return bool(self.chi.IsIrreducibleCharacter())

    @pg_jsonb
    def decomposition(self):
        # TODO
        raise NotImplementedError

    @pg_smallint
    def indicator(self):
        return self.char_table.T.Indicator([self.chi], 2)[0]

    @lazy_attribute
    def char_values(self):
        """
        Sage values of the class function, as a Sequence (so that they all lie in the same cyclotomic field)
        """
        return Sequence(self.chi.ValuesOfClassFunction().sage())

    @lazy_attribute
    def matrix_images(self):
        """
        Sage matrices giving images of the generators, as a Sequence (so that they all lie over the same cyclotomic field)
        """
        # Need to call libgap.eval('LoadPackage("repsn")')
        if not self.irreducible:
            # TODO
            raise NotImplementedError
        mats = self.chi.IrreducibleAffordingRepresentation().Image().GeneratorsOfGroup().sage()
        if self.order == 1:
            universe = MatrixSpace(ZZ, 1)
        else:
            R = Sequence(flatten(mats)).universe()
            universe = MatrixSpace(R, self.dim)
        return Sequence(map(universe, mats), universe=universe)

    @pg_smallint
    def schur_index(self):
        # TODO: https://math.stackexchange.com/questions/814823/schur-index-in-gap
        charU = self.char_values.universe()
        matU = self.matrix_images.universe().base_ring()
        if matU.degree() % charU.degree() != 0:
            raise RuntimeError
        return matU.degree() // charU.degree()

    @pg_integer
    def cyc_order_mat(self):
        U = self.matrix_images.universe().base_ring()
        if U is ZZ:
            return ZZ(1)
        else: # cyclotomic field
            return U._n()

    @pg_integer
    def cyc_order_traces(self):
        U = self.char_values.universe()
        if U is ZZ:
            return ZZ(1)
        else: # cyclotomic field
            return U._n()

    @pg_integer_list
    def denominators(self):
        return [A.denominator() for A in self.matrix_images]

    @pg_jsonb
    def gens(self):
        gens = []
        for A, d in zip(self.matrix_images, self.denominators):
            A = d*A
            gens.append([[encode_cyclotomic_sum(x) for x in row] for row in A])
        return gens

    @pg_integer_list
    def traces(self):
        return [encode_cyclotomic_sum(x) for x in self.char_values]

class CharacterTableGap(object):
    """
    Coordinates the creation of conjugacy classes, characters and subgroups of GL_n(C)
    """
    def __init__(self, gp, outer=False):
        self.gp = gp # Group object
        self.G = gp.G # GAP group
        self.T = self.G.CharacterTable()
        self.outer = outer

    @lazy_attribute
    def conjugacy_classes(self):
        classes = [None] # Start at 1 for compatibility with GAP numbering
        # We want to order conjugacy classes by order, then by size
        cc_by_os = defaultdict(lambda: defaultdict(list))
        self.cc_by_os = defaultdict(lambda: defaultdict(list))
        T = self.T
        Glabel = self.gp.label
        if self.outer:
            # TODO
            raise NotImplementedError
        else:
            for i, C in enumerate(T.ConjugacyClasses()):
                size = ZZ(C.Size())
                order = ZZ(C.Representative().Order())
                cc_by_os[order][size].append((C, i))
            i = 1
            for order in sorted(cc_by_os):
                j = 0
                cc_by_s = cc_by_os[order]
                num_of_order = sum(map(len, cc_by_s.values()))
                for size in sorted(cc_by_s):
                    for C, gap_index in cc_by_s[size]:
                        if num_of_order > 1:
                            label = '%s.%s%s' % (Glabel, order, cremona_letter_code(j).upper())
                        else:
                            label = '%s.%s' % (Glabel, order)
                        classes.append(ConjugacyClassGap(self, C, i, label, outer=self.outer))
                        self.cc_by_os[order][size].append(i)
                        # TODO: store the permutation
                        i += 1
                        j += 1
        return classes

    @lazy_attribute
    def characters(self):
        # TODO: use something more deterministic than GAP's default ordering
        return [None] + [CharacterGap(self, chi, i) for i, chi in enumerate(self.T.Irr(), 1)]

    @lazy_attribute
    def cgroups(self):
        cgroups = [None] # for consistency with other such lists
        # At the moment we only create CGroups for irreducible characters; we should decide whether we want some reducible ones
        if self.G.Center().IsCyclic():
            for f in self.characters[1:]:
                if f.faithful:
                    # TODO: fix the label.  We just implement something simple for now
                    label = '%s.%s' % (f.dim, f.label)
                    cgroups.append(CGroupGap(self, f.chi, label))
        return cgroups

    def identify_conjugacy_class(self, x, order=None, size=None):
        """
        Returns the ``which`` value for the conjugacy class containing ``x``.

        INPUT:

        - ``x`` -- an element of the group
        - ``order`` -- the order of ``x``
        - ``size`` -- the size of the conjugacy class of ``x``
        """
        if order is None:
            order = ZZ(x.Order())
        possible = self.cc_by_os[order]
        if len(possible) > 1:
            if size is None:
                size = self.gp.order // ZZ(self.G.Centralizer(x).Size())
            possible = possible[size]
        else:
            possible = possible[possible.keys()[0]]
        Cs = self.conjugacy_classes
        if len(possible) == 1:
            return possible[0]
        for i in possible:
            if x in Cs[i].C:
                return i

    @lazy_attribute
    def smallrep(self):
        G = self.G
        if not G.Center().IsCyclic():
            return ZZ(0)
        



def encode_cyclotomic_sum(x):
    """
    INPUT:

    - ``x`` -- an element of Z or a cyclotomic field Q(zeta_n)

    OUTPUT:

    A list of pairs ``(c, e)`` so that ``x`` is the sum of c*zeta_n^e.
    We try to minimize the number of terms, rather than only using e up to phi(n)
    """
    # TODO - make this better so that it minimizes number of terms
    if x.parent() is ZZ:
        if x == 0:
            return []
        else:
            return [(x, 0)]
    else:
        return [(ZZ(c),ZZ(e)) for (e,c) in x.polynomial().dict().items()]
