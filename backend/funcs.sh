# this contains declarations used in all of the .sh scripts
# 
#  Copyright Tarisoga LLC, 2013 
# 


CURRDT=`date +'%R %D'`
CURRDATE=`date +%F`

export JAVA_HOME=/usr/lib/jvm/java-6-sun
export ANT_HOME=/usr/share/ant
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
export BROWSER_SCRAPE=/usr/local/bin/firefox/firefox

BASEP=`( cd .. ; pwd )`
XARGSCMD="xargs --replace=%"

if [[ $MACHTYPE == *apple-darwin* ]] ; then
	XARGSCMD="xargs -I %";
	export JAVA_HOME=$(/usr/libexec/java_home)
	export ANT_HOME=/opt/local/share/java/apache-ant
  export BROWSER_SCRAPE=/opt/local/bin/firefox-x11
fi

export AWS_RDS_HOME=$BASEP/backend/amazon/tools/RDSCli-1.10.003
export AWS_CREDENTIAL_FILE=$BASEP/backend/amazon/credentials/credential-file
# export EC2_REGION=
export EC2_HOME=$BASEP/backend/amazon/tools/ec2-api-tools-1.6.6.0

export PATH=${ANT_HOME}/bin:/usr/sbin:${PATH}:$BASEP/backend:$AWS_RDS_HOME/bin:$EC2_HOME/bin:$BASEP/backend/webtest/bin
export HTML_TIDY=$BASEP/backend/tidy/config.txt
export EDIREADER_HOME=$BASEP/backend/processor/edireader
export PYTHONPATH=$BASEP/backend

# DBLOG (in other scripts) should be set to the file that is used to hold error messages

export TARIDB=backend
if [[ $BASEP == *dev* ]] ; then export TARIDB=tarisogadevdb ; fi

function calldb() {
	MYSQ="mysql -u cronjob -h localhost -prabbitDuCKgooseMongoose -D ${TARIDB}"
    # echo "${1}" >> $BASEP/backend/sql.log
	DBR=`echo "use ${TARIDB}; ${1}" | ${MYSQ}`
	if [ $? == 1 ]; then
		echo "ERROR ${CURRDT} Database problem: ${2} : ${1}" >> $DBLOG
		exit
	fi
    # echo "${DBR}" >> $BASEP/backend/sql.log
	return 0
}
