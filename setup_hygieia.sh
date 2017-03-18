#!/bin/sh
set -x
#===============================================================================
# Not using docker-compose to avoid creating a mongodb docker image to 
# create db user
#===============================================================================

#===============================================================================
# Clean up existing containers
#===============================================================================
#docker rm -f $(docker ps -aq)
docker rm -f mongodb
docker rm -f hygieia-ui
docker rm -f hygieia-api
docker rm -f hygieia-sonar-codequality
docker rm -f hygieia-jenkins-build


#===============================================================================
# Remove mongo data directory
#===============================================================================
rm -rf mongo

#===============================================================================
# Start mongo db
#===============================================================================
docker run -d \
  -p 27017:27017 \
  --name mongodb \
  -v $(pwd)/mongo:/data/db \
  mongo:latest  mongod --smallfiles

#===============================================================================
# Sleep until mongodb starts up and then create user "db" with password "dbpass"
# in "dashboard" database
# TODO: Could be robust by checking if mongodb is ready
# Note: login as localhost/dashboard database to create user db in dashboard
#===============================================================================

sleep 10

docker exec mongodb \
  mongo localhost/dashboard --eval 'db.createUser({user: "db", pwd: "dbpass", roles: [{role: "readWrite", db: "dashboard"}]});'

#===============================================================================
# Start hygieia-api container
#===============================================================================
docker run -d \
  -p 8080:8080 \
  --link mongodb:mongo \
  -e "JASYPT_ENCRYPTOR_SECRET=hygieiasecret" \
  -e "SPRING_DATA_MONGODB_DATABASE=dashboard" \
  -e "SPRING_DATA_MONGODB_HOST=mongo" \
  -e "SPRING_DATA_MONGODB_PORT=27017" \
  -e "SPRING_DATA_MONGODB_PASSWORD=ENC(aSPTk36yA/ZklUg75CrZ8w==)" \
  -v $(pwd)/logs:/hygieia/logs \
  --name hygieia-api capitalone/hygieia-api:latest

sleep 5

#===============================================================================
# Start hygieia-ui container
#===============================================================================
docker run -d \
  -p 8088:80 \
  --link hygieia-api:hygieia-api \
  --name hygieia-ui \
  hygieia-ui:latest

#===============================================================================
# Start hygieia Sonar  Collector
#===============================================================================
docker run -d \
  --link mongodb:mongo \
  --link hygieia-api \
  --link sonar_sonarqube_1 \
  -e "JASYPT_ENCRYPTOR_PASSWORD=hygieiasecret" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_DATABASE=dashboard" \
  -e "MONGODB_HOST=mongo" \
  -e "MONGODB_PORT=27017" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_USERNAME=db" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_PASSWORD=ENC(aSPTk36yA/ZklUg75CrZ8w==)" \
  -e "SONAR_CRON=0 0/1 * * * *" \
  -e "SONAR_URL=http://sonar_sonarqube_1:9000" \
  -e "SONAR_METRICS=ncloc,line_coverage,violations,critical_violations,major_violations,blocker_violations,sqale_index,test_success_density,test_failures,test_errors,tests" \
  -v $(pwd)/logs:/hygieia/logs \
  --name hygieia-sonar-codequality hygieia-sonar-codequality-collector:latest

#===============================================================================
# Start hygieia Jenkins Collector
#===============================================================================
docker run -d \
  --link mongodb:mongo \
  --link hygieia-api \
  --link jenkins-master \
  -e "JASYPT_ENCRYPTOR_PASSWORD=hygieiasecret" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_DATABASE=dashboard" \
  -e "MONGODB_HOST=mongo" \
  -e "MONGODB_PORT=27017" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_USERNAME=db" \
  -e "HYGIEIA_API_ENV_SPRING_DATA_MONGODB_PASSWORD=ENC(aSPTk36yA/ZklUg75CrZ8w==)" \
  -e "JENKINS_CRON=0 0/1 * * * *" \
  -e "JENKINS_MASTER=http://jenkins-master:8080" \
  -v $(pwd)/logs:/hygieia/logs \
  --name hygieia-jenkins-build hygieia-jenkins-build-collector:latest

