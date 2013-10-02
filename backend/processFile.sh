#!/bin/bash
#
#  Copyright Tarisoga LLC, 2013
#

# this script handles processing of the new files within carrierXXX/latest

# syntax:   processFile.sh  [carrier number] [file type extension] [Linescape formatted XLS]

# first XLS files are turned into html or xml, then html files are tidy'ed up to clean bad html
# then if there is a matching xsl file, a xsl transformation is performed to turn the .xhtml into a standardized xml.
# then all xml is then processed into the database

# if the files are jpg, etc, then only a cmp against the current reference files are done to see if there has been an update

# PDF files are processed by using pdfminer to create a HTML file, then TableMaker.php is used to turn that into
# a XML file - these HTML files do not have a "real" table structure in them - the lines etc are explicitly specified
# so TableMaker uses an algorithm to deduce the cirrect structure of the simulated table

# the script that includes this must first set the current directory to the carrier0xx directory it is working on
# calldb() must be defined in it as well

# this script can also be called standalone to process new files w/o having to go thru the fetch or check mail step
# argument 1 is the carrier number, argument 2 (optional) is the file type to check - html, xls, csv, other

# v1.3  eliminated dependency on fetchSched.sh so that processfile can be called in own cron job
#       script now looks at sched_fetch table/fetched,fetchedtime for carriers to process

# v1.2  added support for processing PDF files through pdfminer - pdfminer should be installed in usual way
#	and pdf2txt.py made avilable on system path, e.g. /usr/local/bin

# v1.1	moved cp of new xLS/CSV/etc to current only if all new files processed successfully - i.e. chkport did not fail
#	added call to preprocessHTML.sh to pre-process HTML files extracted from XLS files
#	added ability to use <sheet>_generic.xsl - one sheet to handle X html from one XLS file

if [ -z "${BASEP}" ]; then
	source ./funcs.sh
fi;

function mailreport() {
  RETADD=$3
  if [ -z "${3}" ] ; then RETADD="webmaster@tarisoga.com"; fi;
  echo -e "Subject: $1\n\n$2" | sh -c "sendmail -f schedules@tarisoga.com -F \"Schedule Processor\" ${RETADD}"
}

function mailnvocc() {
  calldb "select id from sponsor where fk_carrier=${2};" "get sponsor ID for mail nvocc"
  SID=`echo "${DBR}" | awk '/[0-9]+/ { print $0 }'`
  calldb "select email from sponsor_account where fk_sponsor=${SID} order by id limit 1;" "get sponsor emails for mail nvocc"
  RETADD=${DBR:6}

  DT=`date +'%F'`;
  if [ -z "$3" ]; then
    sed -e "s/%date%/${DT}/" $BASEP/backend/nvoccSuccess.txt | sh -c "sendmail -f schedules@tarisoga.com -F \"Linescape Schedule Processor\" ${RETADD}"
  else
    sed -e "s/%file%/${3}/;s/%date%/${DT}/" $BASEP/backend/nvoccErrors.txt | sh -c "sendmail -f schedules@tarisoga.com -F \"Linescape Schedule Processor\" ${RETADD}"
  fi;
}

# this is for variations in wget, which may or may not append .1 to the file fetched
# DontProcess set to 1 if xslfile indicates XML file has to be manually processed after transform step
function getXSLFile() {
  currXslFile=
  declare -a fnames
  prefi=${1:0:3}
  # deal with variability on carrier side
  prefi2=`echo "$prefi" | tr '[:lower:]' '[:upper:]'`
  prefi3=`echo "$prefi" | tr '[:upper:]' '[:lower:]'`
  fnames[0]=../xslfiles/${1/.html/.xsl}
  fnames[1]=../xslfiles/${1/.?.html/.xsl}
  fnames[2]=../xslfiles/${1/.xls/.xsl}
  fnames[3]=../xslfiles/${1/.?.xls/.xsl}
  fnames[4]=../xslfiles/manual-${1/.html/.xsl}
  fnames[5]=../xslfiles/manual-${1/.?.html/.xsl}
  fnames[6]=../xslfiles/manual-${1/.xls/.xsl}
  fnames[7]=../xslfiles/manual-${1/.?.xls/.xsl}
  fnames[8]=../xslfiles/${prefi}_generic.xsl          # for sheets all from one XLS file
  fnames[9]=../xslfiles/${prefi2}_generic.xsl
  fnames[10]=../xslfiles/${prefi3}_generic.xsl
  fnames[11]=../xslfiles/generic.xsl

  for ((i=0 ; i < 12 ; i++)); do
    if [ -e ${fnames[$i]} ]; then
      currXslFile=${fnames[$i]};
      if [ $i -gt 3 -a $i -lt 8 ]; then DontProcess=1; fi;
      return;
    fi;
  done;
}

function getPropsFile() {
  XLSConvertProps=
  declare -a fnames
  fnames[0]=../${1/.xls/.properties}
  fnames[1]=../xlsconvert.properties

  for ((i=0 ; i < 2 ; i++)); do
    if [ -e "${fnames[$i]}" ]; then
      XLSConvertProps="-props ${fnames[$i]}";
      return;
    fi;
  done;
}

# removes spaces from filesnames

function removeSpaces() {
	for xx in *.$1 ; do
		if [ "${xx}" == "*.${1}" ]; then continue; fi;
		echo "${xx}" | awk '{print "\""$0"\""}' | ${XARGSCMD} mv % ${xx//\ } > /dev/null 2>&1 ;
	done;
}

function cleanupTmpFiles() {
	if [ -e xml-processing.log ]; then
		cat xml-processing.log >> ../logs/$LOGFILE ;
        TMP=`grep -E "(WARNING|ERROR)" xml-processing.log | sort | uniq` ;
        if [ -n "$TMP" ]; then
			mailreport "${CN} Schedule Process warning" "XMLPROCESS WARNINGS (port issues) for carrier ${CNUM}\n${TMP}"
			calldb "update sched_fetch set processError=\"CHK DATA\" where id=${CN};" "update with port warnings"
		fi;
		rm xml-processing.log ;
	fi;
	for xx in *.terr; do if [ ! -s $xx ]; then rm $xx 2> /dev/null; fi; done
	for xx in *.xlserr; do if [ ! -s $xx ]; then rm $xx 2> /dev/null; fi; done
	for xx in *.xml-errors; do if [ ! -s $xx ]; then rm $xx 2> /dev/null; fi; done
	for xx in *.xslerr; do if [ ! -s $xx ]; then rm $xx 2> /dev/null; fi; done

	if [ "${Changed}" == "1" ]; then
		OverallChange=1
	fi;
}

####  process any command line parameters present

FTYPE=""

# if not being called by other script
if [ -z "${CN}" ]; then
	CURRDT=`date +'%R %D'`
	cd $BASEP/backend/fetcher
	LOGDIR=`pwd`
	DBLOG="${LOGDIR}/fetchSched.log";

  if [ $# -eq 0 ]; then
    calldb 'show processlist' 'examining processlist'
    PCNT=`echo "${DBR}" | grep -v -E "^Id|sugarcrm|Sleep|Waiting on empty queue|Waiting for next activation|show processlist" | wc -l`
    if [ $PCNT -gt 0 ]; then
      echo "${CURRDT} Delay of cron processing" >> $DBLOG
      exit;
    fi;

    calldb 'select s.id from sched_fetch s, carrier c where c.id=s.id and s.fetched=1 and s.skip=0 order by c.kindof desc, s.fetchedTime asc, s.id asc limit 1;' "finding carrier to process"
    CN=`echo "${DBR}" | awk '/[0-9]+/ { print $0 }'`
    if [ -z "$CN" ]; then
      echo "${CURRDT} No carriers to process" >> $DBLOG
      exit;
    fi;
    echo "${CURRDT} ${CN} Cron processing starting" >> $DBLOG;

  else
  	CN=$1;
    if [ -n "$2" ]; then
      FTYPE=$2;
    fi
  	echo "${CURRDT} ${CN} Manual processing starting (${FTYPE})" >> $DBLOG;
  fi

  if [ ${#CN} -lt 3 ]; then
	  if [ $CN -lt 10 ]; then
      CNUM="carrier00${CN}";
		elif [ $CN -lt 100 ]; then
      CNUM="carrier0${CN}";
    fi;
	else
    CNUM="carrier${CN}";
	fi

	cd $CNUM
fi

calldb "update sched_fetch set fetched=2 where id=${CN};" "set to processing started"

if [ -z "${MAILED}" ]; then
	MAILED=0;
fi
if [ -n "$3" ]; then
	MAILED=1;
fi

CURRDATE=`date +%F`
LOGFILE="run-${CURRDATE}.log"

cd ./latest

# DontProcess is a flag that detects when there is a manual-???.xsl stylesheet - this indicates that a human needs to deal with something
# before the XML can be processed.   XML that needs to be human processed is put into .xxm files

# Changed is a flag that is set when a new source file for schedule data is detected
# OverallChange is a flag that is set if anything has changed (as a carrier may have multiple types of source files)

# Manual is a flag that is set when there is no XSL sheet for a source file, thus a human has to process the data

OverallChange=0
Manual=0
DontProcess=0
Changed=x

function cmpfile() {
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${1}" >> ../logs/$LOGFILE;
	TMP=`diff -q --unidirectional-new-file ../current/$1 $1`
	if [ -n "$TMP" ]; then
		calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result"

		cp $1 ../current/$1;
		Changed=1;
		Manual=1;
	fi;
}

if [ -z "${FTYPE}" -o "${FTYPE}" == "other" ]; then

Changed=x
for exts in jpg swf gif png ; do
	removeSpaces ${exts} ;
	for cfile in *.${exts} ; do
		if [ "${cfile}" == "*.${exts}" ]; then continue; fi;
		if [ "${Changed}" == "x" ]; then Changed=0 ; fi;
		cmpfile $cfile
	done;
done;

if [ "${Changed}" == "1" ]; then
	OverallChange=1
fi;

fi;

if [ -z "${FTYPE}" -o "${FTYPE}" == "doc" ]; then

DontProcess=0
Changed=x
# if Manual is set to 1 from above, then don't want to reset it to 0 - else a 0 results here would overwrite the processError status

removeSpaces doc ;

for docfile in *.doc ; do
	if [ "${docfile}" == "*.doc" ]; then continue; fi;
	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${docfile}" >> ../logs/$LOGFILE;
	TMP=`diff -q --unidirectional-new-file ../current/$docfile $docfile`
	if [ -n "$TMP" ]; then
		Changed=1
		getXSLFile $docfile
		if [ -n "${currXslFile}" ]; then
			TMP=`unoconv --port 8100 -f html ${docfile} > ${docfile/.doc/.err} 2>&1`
			if [ $? != 0 ]; then
				mailreport "${CN} Schedule Process failed" "DOC2HTML error for carrier ${CNUM} failed: ${docfile} Error: ${?}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with doc2html result"
				exit;
			fi;
		else
			calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result"
			Manual=1
		fi;
	fi;
done;

cleanupTmpFiles ;

fi;

if [ -z "${FTYPE}" -o "${FTYPE}" == "csv" ]; then

DontProcess=0
Changed=x
# if Manual is set to 1 from above, then don't want to reset it to 0 - else a 0 results here would overwrite the processError status

removeSpaces csv ;

# deal with mailed in CSV files
for x in *.CSV ; do
	if [ "${x}" == "*.CSV" ]; then continue; fi;
	mv $x ${x/.CSV/.csv} ;
done;

for cfile in *.csv ; do
	if [ "${cfile}" == "*.csv" ]; then continue; fi;
	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${cfile}" >> ../logs/$LOGFILE;
	TMP=`diff -q --unidirectional-new-file ../current/$cfile $cfile`
	if [ -n "$TMP" ]; then
		Changed=1
		# morph CSV to create standard XML file
		if [ -e ../csv2xml.awk ] ; then
			TMP=`awk -f ../csv2xml.awk $cfile > ${cfile/.csv/.xml} 2> ${cfile/.csv/.xslerr}` ;
		else
			TMP=`awk -f ../../../processor/csv2xml.awk $cfile > ${cfile/.csv/.xml} 2> ${cfile/.csv/.xslerr}` ;
		fi;
		if [ $? == 1 ]; then
			mailreport "${CN} Schedule Process failed" "CSV-XMLTRANS error for carrier ${CNUM} failed: ${cfile}"
			calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update csv-xmltrans result"

			if [ "${CTYPE}" == "nvocc" ]; then
				mailnvocc "$CURRDT" $CN $cfile
			fi;
			exit;
		fi;
	fi;
done;

cleanupTmpFiles ;

fi;

if [ -z "${FTYPE}" -o "${FTYPE}" == "xls" ]; then

DontProcess=0
Changed=x
# if Manual is set to 1 from above, then don't want to reset it to 0 - else a 0 results here would overwrite the processError status

removeSpaces xls ;

for xlsfile in *.xls ; do
	if [ "${xlsfile}" == "*.xls" ]; then continue; fi;
	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${xlsfile}" >> ../logs/$LOGFILE;
	TMP=`diff -q --unidirectional-new-file ../current/$xlsfile $xlsfile`
	if [ -n "$TMP" ]; then
		Changed=1
		getXSLFile $xlsfile
                getPropsFile $xlsfile
		if [ "${MAILED}" == "1" -o "${CTYPE}" == "nvocc" ]; then
			# morp XLS to create standard XML file
			TMP=`java -Xmx512m -Djxl.nowarnings=true -jar ../../../xls2html/xlsconvert.jar -xml $XSLConvertProps $xlsfile > ${xlsfile/.xls/.xlserr} 2>&1`
			# TMP=`awk -f ../../../processor/xls2xml.awk $xlsfile > ${xlsfile/.xls/.xml} 2> ${xlsfile/.xls/.xlserr}`
			if [ -s ${xlsfile/.xls/.xlserr} ]; then
				if [ -n "${RETADDR}" ] ; then
					mailreport "XLS File Failure" "Error processing XLS file to XML for carrier ${CNUM}" $RETADDR
				fi;
				mailreport "${CN} Schedule Process Failed" "XLS-XMLTRANS error for carrier ${CNUM} failed: ${xlsfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update xls-xmltrans result"
				if [ "${CTYPE}" == "nvocc" ]; then
					mailnvocc "$CURRDT" $CN $xlsfile
				fi;
				exit;
			fi;
		elif [ -n "${currXslFile}" ]; then
			TMP=`java -Xmx512m -Djxl.nowarnings=true -jar ../../../xls2html/xlsconvert.jar -html $XLSConvertProps ${xlsfile} > ${xlsfile/.xls/.xlserr} 2>&1`
			# TMP=`../../../xls2html/xls2html.php ${xlsfile} > ${xlsfile/.xls/.html} 2> ${xlsfile/.xls/.xlserr}`
			if [ -s ${xlsfile/.xls/.xlserr} ]; then
				mailreport "${CN} Schedule Process failed" "XLS2HTML error for carrier ${CNUM} failed: ${xlsfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with xls2html result"
				exit;
			fi;
			if [ -f ../preprocessHTML.sh ] ; then source ../preprocessHTML.sh ; fi;
		else
			calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result"
			Manual=1
		fi;
	fi;
done;

cleanupTmpFiles ;

fi;

DontProcess=0
Changed=x

if [ -z "${FTYPE}" -o "${FTYPE}" == "pdf" ]; then

removeSpaces pdf ;

for pdffile in *.pdf ; do
	if [ "${pdffile}" == "*.pdf" ]; then continue; fi;
	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${pdffile}" >> ../logs/$LOGFILE;
  if [ ! -e ../pdfparams ]; then continue; fi;
	TMP=`diff -q --unidirectional-new-file ../current/$pdffile $pdffile`
	if [ -n "$TMP" ]; then
		Changed=1
    # read params for pdf2txt from pdf-params - pdf2args
    doProcess=`grep "${pdffile} pdf2txt" ../pdfparams`
    if [ -n "${doProcess}" ]; then
      PDF2ARGS=`echo ${doProcess} | awk -- ' { st=""; for(x=3; x<=NF; x++) st = st " " $x; print st; }'`
      TMP=`/usr/local/bin/pdf2txt.py -o ${pdffile/.pdf/.htm} -A -V -t html -s 2 ${PDF2ARGS} ${pdffile}`
      if [ $? == 1 ]; then
        mailreport "${CN} Schedule Process failed" "PDF2TXT error for carrier ${CNUM} failed: ${pdffile}"
        calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update pdf2txt result"
			  exit;
      else
        TABLEARGS=`grep "${pdffile} TableMaker" ../pdfparams | awk -- ' { st=""; for(x=3; x<=NF; x++) st = st " " $x; print st; }'`
        TMP=`../../../processor/TableMaker.php -i ${pdffile/.pdf/.htm} ${TABLEARGS} 2> ${pdffile/.pdf/.out}`
        if [ $? == 1 ]; then
	        mailreport "${CN} Schedule Process failed" "TableMaker error for carrier ${CNUM} failed: ${pdffile}"
			    calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update tablemaker result"
			    exit;
        fi;
      fi;
    else   # some files can't / set not to be processed
      Manual=1
	  fi;
  fi;
done;

if [ "${Manual}" == "1" ]; then
  calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result";
fi;

cleanupTmpFiles ;

fi;

DontProcess=0
Changed=x

if [ -z "${FTYPE}" -o "${FTYPE}" == "html" -o "${FTYPE}" == "doc" -o "${FTYPE}" == "pdf" -o "${FTYPE}" == "xls" ]; then

removeSpaces html ;

# list of file to be processed
file_list = $(dirname $0)/${CNUM}.list
for htmlfile in *.html ; do
	if [ "${htmlfile}" == "*.html" ]; then continue; fi;

	if [ -f "${file_list}" ] && grep -Fq $htmlfile ${file_list} ; then continue; fi

	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${htmlfile}" >> ../logs/$LOGFILE;
	TMP=`diff -w -B -a -q --unidirectional-new-file ../current/$htmlfile $htmlfile`
	if [ -n "${TMP}" ]; then
		Changed=1
		DontProcess=0
		getXSLFile $htmlfile
		if [ -n "${currXslFile}" ]; then
			# find any specific Tidy config file
			TIDYCFG="";
			if [ -e ../tidy.config ]; then TIDYCFG="-config ../tidy.config "; fi;
			# carrier112 file encoded with Shift_JIS:
			if [ "${CN}" == "112" ] && grep -Fiq shift_jis ${htmlfile}
			then
				# Back-up:
				mv ${htmlfile} ${htmlfile/.html/_shiftjis.html}
				iconv -f SHIFT-JIS -t UTF-8 ${htmlfile/.html/_shiftjis.html} > ${htmlfile}
				sed -i 's/"text\/html; charset=shift_jis"/"text\/html; charset=utf-8"/I' ${htmlfile}
				TIDYENC="--input-encoding utf8"
			fi
			TMP=`tidy -asxhtml -f ${htmlfile/.html/.err} ${TIDYCFG} ${TIDYENC} ${htmlfile} > ${htmlfile/.html/.xhtml} 2> ${htmlfile/.html/.terr}`
			if [[ $? == 2 && ! -f "${htmlfile/.html/.xhtml}" ]]; then
				mailreport "${CN} Schedule Process Failed" "Tidy error for carrier ${CNUM} failed: ${htmlfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with tidy result"
				exit;
			else
				rm ${htmlfile/.html/.err} ;
			fi;
			if [ -f ../postprocessTidy.sh ] ; then source ../postprocessTidy.sh ; fi;

			# perform XSLT to create standard XML file
			if [ "${DontProcess}" == "0" ]; then
				TMP=`../../../processor/xsltrans.php $currXslFile ${htmlfile/.html/.xhtml} > ${htmlfile/.html/.xml} 2> ${htmlfile/.html/.xslerr}`;
			else
				TMP=`../../../processor/xsltrans.php $currXslFile ${htmlfile/.html/.xhtml} > ${htmlfile/.html/.xxm} 2> ${htmlfile/.html/.xslerr}`;
			fi;
			if [ $? == 0 ]; then
				mailreport "${CN} Schedule Process failed" "HTML-XSLTRANS error for carrier ${CNUM} failed: ${htmlfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with html-xsltrans result"
				exit;
			fi;

			if [ "${Manual}" == "1" -o "${DontProcess}" == "1" ]; then
				calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result";
				Manual=1;
				DontProcess=0;
			fi;

		else
			calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result"
			Manual=1
		fi;
	fi;
done;

cleanupTmpFiles ;

fi;

# XM files are XML from carrier (EDI etc)

DontProcess=0
Changed=x

if [ -z "${FTYPE}" -o "${FTYPE}" == "xm" ]; then

removeSpaces xm ;

for xmfile in *.xm ; do
	if [ "${xmfile}" == "*.xm" ]; then continue; fi;
	Changed=0
	CURRDT=`date +'%R %D'`
	echo "${CURRDT} Processing of ${CNUM} ${xmfile}" >> ../logs/$LOGFILE;
	TMP=`diff -w -B -a -q --unidirectional-new-file ../current/$xmfile $xmfile`
	if [ -n "${TMP}" ]; then
		Changed=1
		DontProcess=0
		getXSLFile $xmfile
		if [ -n "${currXslFile}" ]; then
			# perform XSLT to create standard XML file
			if [ "${DontProcess}" == "0" ]; then
				TMP=`../../../processor/xsltrans.php $currXslFile $xmfile > ${xmfile/.xm/.xml} 2> ${xmfile/.xm/.xslerr}`;
			else
				TMP=`../../../processor/xsltrans.php $currXslFile $xmfile > ${xmfile/.xm/.xxml} 2> ${xmfile/.xm/.xslerr}`;
			fi;
			if [ $? == 0 ]; then
				mailreport "${CN} Schedule Process Failed" "XML-XSLTRANS error for carrier ${CNUM} failed: ${xmfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with xml-xsltrans result"
				exit;
			fi;

			if [ "${Manual}" == "1" -o "${DontProcess}" == "1" ]; then
				calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result";
				Manual=1;
				DontProcess=0;
			fi;

		else
            python ../../../processor/transform_edi.py $xmfile > ${xmfile/.xm/.xml} 2> ${xmfile/.xm/.xslerr}
			if [ $? != 0 ]; then
				mailreport "${CN} Schedule Process Failed" "XML-EDI-PYTRANS error for carrier ${CNUM} failed: ${xmfile}"
				calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with xml-edi-trans result"
				exit;
			fi;

			# calldb "update sched_fetch set scheduleChanged=1,processError=\"MANUAL\" where id=${CN};" "update with manual change result"
			# Manual=1
		fi;
	fi;
done;

cleanupTmpFiles ;

fi;

######## process all XML files

if [ -f chkports.out ]; then rm chkports.out; fi;
if [ -f chkports.err ]; then rm chkports.err; fi;

if [ -f ../preprocess.sh ]; then ../preprocess.sh; fi;

XIT=0
CURRDT=`date +'%R %D'`
for cfile in *.xml ; do
	if [ "${cfile}" == "*.xml" ]; then continue; fi;
	TMP=`../../../processor/checkports.php ${cfile} >> chkports.out 2>> chkports.err`
	if [ $? == 1 -a "${CTYPE}" == "nvocc" ]; then
		mailnvocc "$CURRDT" $CN $cfile
	fi;
done;

if [ -s chkports.err ]; then
	RETADD=$RETADDR
	# if XLS file mailed in, send errors to its sender, else ignore any RETADDR (i.e. off of checkMail.sh)
	if [ -z "${RETADD}" -o "${MAILED}" != "1" ] ; then RETADD="webmaster@tarisoga.com"; fi;
	echo -e "Subject: ${CN} Port Validation failed\n" > chkports.sub
	cat chkports.sub chkports.err | sh -c "sendmail -f schedules@tarisoga.com -F \"Schedule Processor\" ${RETADD}";
	if [ -n "${MAILED_FROM}" ] ; then
		cat chkports.sub chkports.err | sh -c "sendmail -f schedules@tarisoga.com -F \"Schedule Processor\" ${MAILED_FROM}";
	fi
	XIT=1;

else

DATAFILE="${BASEP}/dumpdata/schedules-${CN}*"
rm -f $DATAFILE

for cfile in *.xml ; do
	if [ "${cfile}" == "*.xml" ]; then continue; fi;
	# run processXML to create schedule data
	TMP=`../../../processor/xmlprocess.php ${CN} ${cfile} > ${cfile/.xml/.xml-errors}`
	if [ $? == 1 ]; then
		mailreport "${CN} Schedule Process Failed" "XMLPROCESS error for carrier ${CNUM} failed: ${cfile}"
		calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"FAILED\" where id=${CN};" "update with xmlprocess result"
		if [ "${CTYPE}" == "nvocc" ]; then
			mailnvocc "$CURRDT" $CN $cfile
		fi;
		XIT=1;
	fi;
done;

if [ "${XIT}" == "1" ]; then exit; fi

# can't process all XML seg data in one go - carriers will update a vessel schedule several times in one data
# set and so the DELETE * op that clears out a old sched in xmlprocess.php won't clear obsolete scheds -
# the bulk data load will add all the data for all scheds at once.  Would have to prefilter sched data / cache
# before data file gets created.  LOAD DATA called after evey process of a XML file - ensures scheds get cleared
# as need be

# run LOAD DATA on /tmp/schedule-<carrier ID>.dat to load all segments vals in one go

# calldb "LOAD DATA INFILE '${DATAFILE}' replace into table segments character set utf8 FIELDS ENCLOSED BY '\"' TERMINATED BY ',' LINES TERMINATED BY '\r\n';" \
# "load data file - del ${DATAFILE}"

rm -f $DATAFILE

# mail success
if [ "${CTYPE}" == "nvocc" ]; then
	mailnvocc "$CURRDT" $CN
fi;

# copy new --processed-- source file - but not intermediates - files only if everything went ok
cp *.doc ../current/ 2> /dev/null
cp *.csv ../current/ 2> /dev/null
cp *.xls ../current/ 2> /dev/null
cp *.pdf ../current/ 2> /dev/null
cp *.xm ../current/ 2> /dev/null

for x in *.html ; do
  if [ "${x}" == "*.html" ]; then continue; fi
  if [[ "$x" == *-table* ]]; then continue; fi
  cp "$x" ../current/ 2> /dev/null
done;

fi;

cleanupTmpFiles ;

if [ "${Manual}" == "0" ]; then
	calldb "update sched_fetch set fetched=0,scheduleChanged=1,processError=\"SUCCESS\" where id=${CN};" "update with success change result"
fi;

if [ "${OverallChange}" == "0" ]; then
	calldb "update sched_fetch set fetched=0,scheduleChanged=0,processError=\"NO CHANGE\" where id=${CN};" "update with no change in any data"
fi;

if [ "${CTYPE}" == "nvocc" ]; then
	calldb "update sched_fetch set fetched=0,skip=1 where id=${CN};" "update nvocc to skip auto-processing"
fi;

#############

# to carrier0xx
cd ..

# delete outdated schedules for this carrier
# base on end_date
# TODO:  move outdated schedules+segments (merge schemas) to performance table in order to capture performance data (eta, real ta)
# calldb "delete from schedule where fk_carrier=${CN} and template=0 and date(now()) > date(adddate(end_date,interval 7 day));" "delete of outdated schedules for ${CN}"

# check that not all schedules have been deleted - if so, carrier needs manual updating
calldb "select count(*) from schedule where fk_carrier=${CN} and date(now()) <= end_date;" "select of current schedules"
SCNT=`echo "${DBR}" | awk '/[0-9]+/ { print $0 }'`
if [ $SCNT -eq 0 ]; then
   	calldb "update sched_fetch set scheduleChanged=1,skip=0,processError=\"ADD SCH\" where id=${CN};" "update - schedules need manually added"
fi;

calldb "update sched_fetch set fetched=0 where id=${CN};" "reset for fetch"

CURRDT=`date +'%R %D'`;
echo "${CURRDT} ${CN} Processing stopping" >> $DBLOG
