#!make
SHELL := /bin/bash
GEONAMES_VERSION := 20200106

all: pairs/amh_Ethi2Latn_ALA_1997.csv

data:
	mkdir -p $@

data/geonames.zip: | data
	curl -sL http://geonames.nga.mil/gns/html/cntyfile/geonames_${GEONAMES_VERSION}.zip -o $@

data/Countries.txt: data/geonames.zip | data
	unzip $< -d data

db:
	mkdir -p $@

db/geonames.db: data/Countries.txt | data
	sqlite3 ".mode tabs" ".import $< countries" ".backup $@"

data/geonames_pairs.csv: db/geonames.db | db
	sqlite3 $< < sql/geonames_pairs.sql

db/geonames_pairs.db: data/geonames_pairs.csv | data
	sqlite3 ".mode csv" ".import $< countries" ".backup $@"

sql/sequence_system_all.sql:
	echo > $@; \
	for system in `cat data/translit_systems.txt`; do \
		export TRANSLIT_SYSTEM=$$system; \
		envsubst < sql/sequence_system_each.sql.in >> $@; \
	done

pairs:
	mkdir -p $@

pairs/%.csv: db/geonames_pairs.db sql/sequence_system_all.sql | pairs
	sqlite3 $< < sql/sequence_system_all.sql

distclean: clean
	rm -rf data

clean:
	rm -f db/ sql/sequence_system_all.sql
	rm -rf pairs

.PHONY: all clean distclean

.SECONDARY: data/geonames.zip geonames.db geonames_pairs.db
