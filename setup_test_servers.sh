#!/bin/sh

#===============================================================================
# Start Sonar 
#===============================================================================
docker-compose -f test-servers/sonar/sonar.yml up -d

#===============================================================================
# Start Jenkins
#===============================================================================
docker-compose -f test-servers/jenkins/jenkins.yml up -d

wait_until_port_open(){
	local port=$1
	local app=$2

	while ! nc -z localhost $1; do   
		echo "Waiting $app to launch on $port..."
		sleep 0.1 # wait for 1/10 of the second before check again
	done

	echo "$app launched"
}

wait_until_port_open 9000 sonar
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000 -Dsonar.jdbc.url="jdbc:h2:tcp://localhost:9000/sonar"

wait_until_port_open 9100 jenkins
curl http://localhost:9100/job/Hygieia_Example_Job/build

