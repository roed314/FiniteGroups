FOLDER = DATA
LMFDB = LMFDB

data: glnc glnq cchar qchar ccs groups subs

diagramx:
	cat $(LMFDB)/grdata? > $(LMFDB)/grdata.out

diagramxaut:
	cat $(LMFDB)/grdata_aut? > $(LMFDB)/grdata_aut.out

copy:
	cp *.data ~/lmfdb; cp *chars2reps LMFDB

groupclean:
	rm -rf $(FOLDER)/*group*/*; rm -rf $(FOLDER)/characters*/*

clean:
	rm -rf $(FOLDER)/*/*; rm -f CCchars2reps; rm -f QQchars2reps; rm -f Qreps/*

repclean:
	rm -rf $(FOLDER)/gln*/*; rm -f CCchars2reps; rm -f QQchars2reps; rm -f Qreps/*

upload: data diagramx diagramxaut
	cd $(LMFDB); sage -python uploadgrps.py ;\
	sage -python add-rep-images.py c; sage -python add-rep-images.py q;\
	sage -python grfinish.py; \
	cd ..

uploadgraph: diagramx diagramxaut
	cd $(LMFDB); sage -python grfinish.py; cd ..

groups:
	find $(FOLDER)/groups -type f -exec cat '{}' ';' | sort -u | cat LMFDBGrp.header  - > $(LMFDB)/groups.data

subs:
	find $(FOLDER)/subgroups -type f -exec cat '{}' ';' | sort -u | cat LMFDBSubGrp.header - > $(LMFDB)/subs.data

glnc:
	find $(FOLDER)/glnc -type f -exec cat '{}' ';' | sort -u | cat LMFDBRepCC.header - > $(LMFDB)/glnc.data

glnq:
	find $(FOLDER)/glnq -type f -exec cat '{}' ';' | sort -u | cat LMFDBRepQQ.header - > $(LMFDB)/glnq.data

qchar:
	find $(FOLDER)/characters_qq -type f -exec cat '{}' ';' | sort -u | cat LMFDBGrpChtrQQ.header - > $(LMFDB)/qchar.data

cchar:
	find $(FOLDER)/characters_cc -type f -exec cat '{}' ';' | sort -u | cat LMFDBGrpChtrCC.header - > $(LMFDB)/cchar.data

ccs:
	find $(FOLDER)/groups_cc -type f -exec cat '{}' ';' | sort -u | cat LMFDBGrpConjCls.header - > $(LMFDB)/ccs.data
