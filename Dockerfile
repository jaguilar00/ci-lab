#pull base image
FROM openjdk:8-jdk-alpine

#maintainer
MAINTAINER jaguilar@sms-latam.com

#expose port 8080
EXPOSE 8080

#default command
CMD java -jar /data/ci-lab.jar

#copy ci-lab.jar to docker image
ADD target/ci-lab*.jar /data/ci-lab.jar