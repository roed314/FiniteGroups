# Scripts for controlling remote machines on Google cloud platform using SSH that have already been set up

# Never change the order of server_ips.txt, but adding to the end is fine.

import os
from collections import defaultdict
from os.path import splitext
ope, opj = os.path.exists, os.path.join
from subprocess import call, check_output, CalledProcessError

def server_ips():
    with open("DATA/server_ips.txt") as F:
        return F.read().strip().split("\n")

def job_servers():
    jobs = {}
    jfile = opj("DATA", "jobs.txt")
    if ope(jfile):
        with open(jfile) as F:
            for line in F:
                if line:
                    prefix, nos, pids, status = line.strip().split()
                    jobs[prefix] = [int(n) for n in nos.split(",")]
    return jobs

def job_data():
    jobs = {}
    jfile = opj("DATA", "jobs.txt")
    if ope(jfile):
        with open(jfile) as F:
            for line in F:
                if line:
                    prefix, nos, pids, status = line.strip().split()
                    jobs[prefix] = [int(n) for n in nos.split(",")], pids.split(",")
    return jobs

def record_job(prefix, servers, pids):
    J = job_servers()
    jfile = opj("DATA", "jobs.txt")
    if prefix in J:
        raise ValueError(f"{prefix} already started")
    if not servers:
        raise ValueError("No servers given")
    if len(servers) != len(pids):
        raise ValueError("Must provide the same number of servers and pids")
    with open(jfile, "a") as F:
        nos = ','.join([str(n) for n in servers])
        pids = ','.join([str(pid) for pid in pids])
        _ = F.write(f"{prefix} {nos} {pids} started\n")

def job_status(prefix, value=None):
    found = False
    with open("DATA/jobtmp", "w") as Fout:
        with open("DATA/jobs.txt") as F:
            for line in F:
                pref, nos, pids, status = line.strip().split()
                if pref == prefix:
                    found = True
                    if value is None:
                        if status in ["done", "complete"]:
                            working = []
                        elif status == "started":
                            ips = server_ips()
                            nums = [int(i) for i in nos.split(",")]
                            ips = [ips[i] for i in nums]
                            working = [i for (ip, i) in zip(ips, nums) if not server_is_finished(ip)]
                            if not working:
                                value = "done"
                        else:
                            raise RuntimeError(f"Invalid status {status}")
                    else:
                        working = None
                    if value is None:
                        _ = Fout.write(line)
                    else:
                        _ = Fout.write(f"{pref} {nos} {pids} {value}\n")
                else:
                    _ = Fout.write(line)
            if not found:
                raise ValueError(f"No job {prefix}")
    if value is None:
        os.remove("DATA/jobtmp")
    else:
        os.rename("DATA/jobtmp", "DATA/jobs.txt")
    return working

def server_is_finished(ip):
    try:
        ok = check_output(f"ssh -q {ip} [[ -f finished ]]", shell=True)
    except CalledProcessError:
        return False
    else:
        return True

def server_is_ready(ip):
    try:
        ok = check_output(f"ssh -q {ip} [[ ! -f output ]]", shell=True)
    except CalledProcessError:
        return False
    else:
        return True

def available_servers(ips=None):
    if ips is None:
        ips = server_ips()
    return [i for (i, ip) in enumerate(ips) if server_is_ready(ip)]

def execute(cmd, ips=None, output=False, get_pid=False, nohup=True):
    if output and get_pid:
        raise ValueError("Cannot simultaneously get output and a background PID")
    singleton = False
    if ips is None:
        ips = server_ips()
    elif isinstance(ips, str):
        singleton = True
        ips = [ips]
    outs = []
    for ip in ips:
        if output:
            outs.append(check_output(f"ssh -q {ip} '{cmd}'", shell=True).decode("ascii"))
        elif get_pid:
            outs.append(check_output(f"ssh -q {ip} 'nohup {cmd} >/dev/null 2>/dev/null </dev/null & echo $!'", shell=True).decode("ascii").strip())
        elif nohup:
            call(f"ssh -q {ip} 'nohup {cmd} 2>/dev/null >/dev/null </dev/null &'", shell=True)
        else:
            call(f"ssh -q {ip} '{cmd}'", shell=True)
    if output or get_pid:
        if singleton:
            return outs[0]
        return outs

def send_file(fpath, ips=None, recompile=None, dest=None):
    if ips is None:
        ips = server_ips()
    elif isinstance(ips, str):
        ips = [ips]
    if recompile is None:
        base, ext = splitext(fpath)
        recompile = (ext == ".m")
    if dest is None:
        dest = fpath
    for ip in ips:
        call(f"scp {fpath} {ip}:{dest}", shell=True)
        if recompile:
            execute(f"magma -c {dest}", ip)

def send_files(fpaths, ips=None, recompile=None):
    if ips is None:
        ips = server_ips()
    for fpath in fpaths:
        send_file(fpath, ips, recompile=recompile)

def setup_TE(outputs, TEfolder):
    TElines = defaultdict(list)
    for oname in outputs:
        with open(oname) as F:
            for line in F:
                if line[0] in "TE":
                    label = line[1:].split("(",1)[0]
                    TElines[label].append(line)
    os.makedirs(TEfolder, exist_ok=True)
    for label, lines in TElines.items():
        with open(opj(TEfolder, label), "w") as F:
            _ = F.write("".join(lines))

def get_output(prefix, tmp_ok=False, basepath="/scratch/grp"):
    J = job_servers()
    if prefix not in J:
        raise ValueError(f"{prefix} not one of [{','.join(J)}]")
    ips = server_ips()
    ips = [ips[i] for i in J[prefix]]
    finished = [server_is_finished(ip) for ip in ips]
    os.makedirs(opj(basepath, prefix), exist_ok=True)
    if all(finished):
        tmp_ok = False
        dests = [opj(basepath, prefix, f"output{i}") for i in range(1, len(ips) + 1)]
    elif tmp_ok:
        dests = [opj(basepath, prefix, f"tmp{i}") for i in range(1, len(ips) + 1)]
    else:
        raise ValueError(f"{prefix} not finished")
    for ip, dest in zip(ips, dests):
        call(f"scp {ip}:output {dest}", shell=True)
        print(dest, "copied")
    if not tmp_ok:
        server_md5s = [x.split()[0] for x in execute("md5sum output", ips, output=True)]
        local_md5s = [check_output(f"md5sum {dest}", shell=True).decode("ascii").split()[0] for dest in dests]
        if server_md5s != local_md5s:
            raise RuntimeError("MD5 mismatch")
        print("MD5 match")
        execute("rm output", ips)
        setup_TE(dests, opj(basepath, prefix, "TE"))

def deploy(labelcodes, prefix, jobtime, totaltime, server_numbers=None, basepath="DATA"):
    ips = server_ips()
    available = available_servers(ips)
    if server_numbers is None:
        server_numbers = available
    elif any(ip not in available for ip in server_numbers):
        raise ValueError(f"Servers not available: {','.join(str(n) for n in server_numbers)}")
    ips = [ips[i] for i in server_numbers]
    N = len(server_numbers)
    todo_names = [opj(basepath, f"compute_{prefix}.todo{i}") for i in range(N)]
    mname = opj(basepath, "tmpmanifest")
    for i, (fname, ip) in enumerate(zip(todo_names, ips)):
        todo = labelcodes[i::N]
        with open(fname, "w") as F:
            for label, codes in todo:
                _ = F.write(f"{label} {codes}\n")
        send_file(fname, ips=ip, dest="DATA/compute.todo")
        with open(mname, "w") as F:
            _ = F.write(f"DATA/compute.todo DATA/computes DATA/timings ComputeCodes.m {len(todo)} 1 {jobtime} {totaltime}\n")
        send_file(mname, ips=ip, dest="DATA/manifest")
        print(f"Server {i} setup complete")
    os.remove(mname)

    pids = execute("/home/roed/cloud_parallel.py", ips, get_pid=True)
    record_job(prefix, server_numbers, pids)

def stop_computation(prefix):
    server_numbers, pids = job_data()[prefix]
    ips = server_ips()
    ips = [ips[i] for i in server_numbers]
    for ip, pid in zip(ips, pids):
        execute(f"kill {pid}", ip)
        execute(f"kill {pid}", ip) # kill twice to kill currently running jobs
