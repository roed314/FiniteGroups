FOLDER = DATA
LMFDB = LMFDB

data: glnc glnq cchar qchar ccs groups subs

diagramx:
	cat $(LMFDB)/grdata? > $(LMFDB)/grdata.out

copy:
	cp *.data ~/lmfdb; cp *chars2reps LMFDB

groupclean:
	rm -rf $(FOLDER)/*group*/*; rm -rf $(FOLDER)/characters*/*

clean:
	rm -rf $(FOLDER)/*/*; rm -f CCchars2reps; rm -f QQchars2reps; rm -f Qreps/*

repclean:
	rm -rf $(FOLDER)/gln*/*; rm -f CCchars2reps; rm -f QQchars2reps; rm -f Qreps/*

upload: data diagramx
	cd $(LMFDB); sage -python uploadgrps.py ;\
	sage -python add-rep-images.py c; sage -python add-rep-images.py q;\
	sage -python grfinish.py; \
	cd ..

groups:
	cat $(FOLDER)/groups/* | sort -u | cat LMFDBGrp.header  - > $(LMFDB)/groups.data

subs:
	cat $(FOLDER)/subgroups/* | sort -u | cat LMFDBSubGrp.header - > $(LMFDB)/subs.data

glnc:
	cat $(FOLDER)/glnc/* | sort -u |  cat LMFDBRepCC.header - > $(LMFDB)/glnc.data

glnq:
	cat $(FOLDER)/glnq/* | sort -u | cat LMFDBRepQQ.header - > $(LMFDB)/glnq.data

qchar:
	cat $(FOLDER)/characters_qq/* | sort -u | cat LMFDBGrpChtrQQ.header - > $(LMFDB)/qchar.data

cchar:
	cat $(FOLDER)/characters_cc/*  | sort -u |cat LMFDBGrpChtrCC.header - > $(LMFDB)/cchar.data

ccs:
	cat $(FOLDER)/groups_cc/* | sort -u | cat LMFDBGrpConjCls.header - > $(LMFDB)/ccs.data
