#!/bin/bash

# inex page to htm pages

cd ./latest
rm -rf *
cd ../results
rm -rf *

wget -t 2 -S -T 90 -o wgeterrs -O index http://www.greatwhitefleet.com/liner/Applications/SailingSchedule/SailingSchedule.asp
if [ $? == 1 ]; then exit 1; fi

grep -o  '/liner/.*htm' index | tee step1 | sort | uniq | tee step2 | awk ' { print "http://www.greatwhitefleet.com" $0; }' > urls
if [ ${PIPESTATUS[0]} -ne 0 ]; then  exit 1 ; fi

wget -t 2 -S -T 90 -a wgeterrs -i urls;
if [ $? == 1 ]; then exit 1; fi
for file in *.htm ; do mv $file ${file}l ; done

rm NorthAmericaSailingSchedule.html

cp *.html ../latest
exit 0
