#!groovy​

final GIT_URL = 'https://github.com/jaguilar00/ci-lab.git'
final NEXUS_URL = '172.20.68.52:8081'
final NEXUS_REPO = 'ci-test-project'
final CONTAINER_NAME= 'ci-test-project'

final DOCKER_REPO_HOST = "registry.intranet.sms"
final DOCKER_REPO_URL="https://${DOCKER_REPO_HOST}"
final DOCKER_IMAGE_NAME = "ci-test-project"
final DOCKER_CONTAINER_NAME = "ci-test-project-container"
final DOCKER_IMAGE_TAG = "${DOCKER_REPO_HOST}/${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}"
final APP_PORT=8088

stage('Build') {
    node {
        git GIT_URL
        withEnv(["PATH+MAVEN=${tool 'm3'}/bin"]) {
            def pom = readMavenPom file: 'pom.xml'
            sh "mvn -B versions:set -DnewVersion=${pom.version}-${BUILD_NUMBER}"
            sh "mvn -B -Dmaven.test.skip=true clean package"
            stash name: "artifact", includes: "target/ci-lab-*.jar"
        }
    }
}

stage('Unit Tests') {
    node {
        withEnv(["PATH+MAVEN=${tool 'm3'}/bin"]) {
            sh "mvn -B clean test"
            stash name: "unit_tests", includes: "target/surefire-reports/**"
        }
    }
}

stage('Integration Tests') {
    node {
        withEnv(["PATH+MAVEN=${tool 'm3'}/bin"]) {
            sh "mvn -B clean verify -Dsurefire.skip=true"
            stash name: 'it_tests', includes: 'target/failsafe-reports/**'
        }
    }
}

stage('Static Analysis') {
    node {
        withEnv(["PATH+MAVEN=${tool 'm3'}/bin"]) {
            withSonarQubeEnv('sonar'){
                unstash 'it_tests'
                unstash 'unit_tests'
                sh 'mvn sonar:sonar -DskipTests'
            }
        }
    }
}
//For approval stage
//stage('Approval') {
//    timeout(time:3, unit:'DAYS') {
//        input 'Do I have your approval for deployment?'
//    }
//}

stage('Artifact Upload') {
    node {
        unstash 'artifact'

        def pom = readMavenPom file: 'pom.xml'
        def file = "${pom.artifactId}-${pom.version}"
        def jar = "target/${file}.jar"

        sh "cp pom.xml ${file}.pom"

        nexusArtifactUploader artifacts: [
                [artifactId: "${pom.artifactId}", classifier: '', file: "${jar}", type: 'jar'],
                [artifactId: "${pom.artifactId}", classifier: '', file: "${file}.pom", type: 'pom']
            ],
            credentialsId: 'nexus-credentials',
            groupId: "${pom.groupId}",
            nexusUrl: NEXUS_URL,
            nexusVersion: 'nexus3',
            protocol: 'http',
            repository: NEXUS_REPO,
            version: "${pom.version}"
    }
}

stage('Build Docker Image') {
    node {
        unstash 'artifact'

        docker.build(CONTAINER_NAME)
    }
}

stage('Docker Image Upload'){
    node {
        echo "Docker Image Tag Name: ${DOCKER_IMAGE_NAME}"

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'registry-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            sh "docker login -u ${USERNAME} -p ${PASSWORD} ${DOCKER_REPO_URL}"
            sh "docker tag ${DOCKER_IMAGE_NAME} ${DOCKER_IMAGE_TAG}"
            sh "docker push ${DOCKER_IMAGE_TAG}"
        }
    }
}

stage('Deploy'){
    node {

        try {
            sh "docker stop ${DOCKER_CONTAINER_NAME}"
        } catch (Exception e) {
            echo "${DOCKER_CONTAINER_NAME} not found."
        }
        sh "docker run -d --rm -p ${APP_PORT}:8080 --name ${DOCKER_CONTAINER_NAME} ${DOCKER_IMAGE_TAG}"
        echo "App running in port ${APP_PORT}"
    }
}