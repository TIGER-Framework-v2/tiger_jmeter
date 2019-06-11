
set -e

JM_VER="5.1.1"
JM_NAME="apache-jmeter-${JM_VER}"
JM_HOME_DIR=/opt/$JM_NAME
JM_URL="https://archive.apache.org/dist/jmeter/binaries/${JM_NAME}.tgz"
backend_listener_url="https://github.com/vvxxsz00/InfluxBackendListenerClient/blob/master/out/artifacts/InfluxBackendListener_jar/InfluxBackendListenerClient.jar"

export PATH=$PATH:${JM_HOME_DIR}/bin


apk update 
apk upgrade 
apk add ca-certificates 
update-ca-certificates 
apk add --no-cache nss openjdk8-jre tzdata git ruby ruby-rdoc
gem install influxdb
rm -rf /var/cache/apk/*  
wget -O ${JM_NAME}.tgz ${JM_URL} 
tar -xzf ${JM_NAME}.tgz -C /opt/ 
rm -f ${JM_NAME}.tgz 
mkdir -p /opt/tiger/scripts /opt/tiger/jmeter_test /opt/tiger/temp
curl -O $backend_listener_url /opt/tiger/temp
adduser -D -u 1001 tiger 
chown -R tiger /opt/tiger
mv /opt/tiger/temp/InfluxBackendListenerClient.jar /opt/apache-jmeter-5.1.1/lib/ext
rm -rf /opt/tiger/temp

 
