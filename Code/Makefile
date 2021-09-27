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
	ls $(FOLDER)/groups/* | xargs cat | sort -u | cat LMFDBGrp.header  - > $(LMFDB)/groups.data

subs:
	ls $(FOLDER)/subgroups/* | xargs cat | sort -u | cat LMFDBSubGrp.header - > $(LMFDB)/subs.data

glnc:
	ls $(FOLDER)/glnc/* | xargs cat | sort -u |  cat LMFDBRepCC.header - > $(LMFDB)/glnc.data

glnq:
	ls $(FOLDER)/glnq/* | xargs cat | sort -u | cat LMFDBRepQQ.header - > $(LMFDB)/glnq.data

qchar:
	ls $(FOLDER)/characters_qq/* | xargs cat | sort -u | cat LMFDBGrpChtrQQ.header - > $(LMFDB)/qchar.data

cchar:
	ls $(FOLDER)/characters_cc/* | xargs cat  | sort -u |cat LMFDBGrpChtrCC.header - > $(LMFDB)/cchar.data

ccs:
	ls $(FOLDER)/groups_cc/* | xargs cat | sort -u | cat LMFDBGrpConjCls.header - > $(LMFDB)/ccs.data
