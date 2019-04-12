
set -e

JM_VER="5.1.1"
JM_NAME="apache-jmeter-${JM_VER}"
JM_HOME_DIR=/opt/$JM_NAME
JM_URL="https://archive.apache.org/dist/jmeter/binaries/${JM_NAME}.tgz" 

export PATH=$PATH:${JM_HOME_DIR}/bin


apk update 
apk upgrade 
apk add ca-certificates 
update-ca-certificates 
apk add --no-cache nss openjdk8-jre tzdata git ruby 
rm -rf /var/cache/apk/* 
wget -O ${JM_NAME}.tgz ${JM_URL} 
tar -xzf ${JM_NAME}.tgz -C /opt/ 
rm -f ${JM_NAME}.tgz 
mkdir -p /opt/tiger/scripts /opt/tiger/tests 
adduser -D -u 1001 tiger 
chown -R tiger /opt/tiger/jmeter_test
 
