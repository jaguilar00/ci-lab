#pull base image
FROM openjdk:8-jdk-alpine

#maintainer
MAINTAINER jaguilar@sms-latam.com

#expose port 8080
EXPOSE 8080

#default command
CMD java -jar /data/ci-test-project.jar

#copy ci-lab.jar to docker image
ADD ./data/hello-world-0.1.0.jar /data/ci-lab-0.0.2.jar