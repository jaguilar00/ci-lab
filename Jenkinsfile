#!groovy​

final GIT_URL = 'https://github.com/jaguilar00/ci-lab.git'
final NEXUS_URL = '192.168.50.10:8081'

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



stage('Approval') {
    timeout(time:3, unit:'DAYS') {
        input 'Do I have your approval for deployment?'
    }
}




stage('Artifact Upload') {
    node {
        unstash 'artifact'

        def pom = readMavenPom file: 'pom.xml'
        def file = "${pom.artifactId}-${pom.version}"
        def jar = "target/${file}.jar"

        sh "cp pom.xml ${file}.pom"

        nexusArtifactUploader artifacts: [
                [artifactId: "${pom.artifactId}", classifier: '', file: "target/${file}.jar", type: 'jar'],
                [artifactId: "${pom.artifactId}", classifier: '', file: "${file}.pom", type: 'pom']
            ],
            credentialsId: 'nexus-credentials',
            groupId: "${pom.groupId}",
            nexusUrl: NEXUS_URL,
            nexusVersion: 'nexus3',
            protocol: 'http',
            repository: 'ci-lab',
            version: "${pom.version}"
    }
}



//stage('Deploy') {
//    node {
//        def pom = readMavenPom file: "pom.xml"
//        def repoPath =  "${pom.groupId}".replace(".", "/") +
//                        "/${pom.artifactId}"
//
//        def version = pom.version
//
//        if(!FULL_BUILD) { //takes the last version from repo
//            sh "curl -o metadata.xml -s http://${NEXUS_URL}/repository/soccer-test-app/${repoPath}/maven-metadata.xml"
//            version = sh script: 'xmllint metadata.xml --xpath "string(//latest)"',
//                         returnStdout: true
//        }
//        def artifactUrl = "http://${NEXUS_URL}/repository/soccer-test-app/${repoPath}/${version}/${pom.artifactId}-${version}.war"
//
//        withEnv(["ARTIFACT_URL=${artifactUrl}", "APP_NAME=${pom.artifactId}"]) {
//            echo "The URL is ${env.ARTIFACT_URL} and the app name is ${env.APP_NAME}"
//
//            // install galaxy roles
//            sh "ansible-galaxy install -vvv -r provision/requirements.yml -p provision/roles/"
//
//            ansiblePlaybook colorized: true,
//            credentialsId: 'ssh-jenkins',
//            limit: "${HOST_PROVISION}",
//            installation: 'ansible',
//            inventory: 'provision/inventory.ini',
//            playbook: 'provision/playbook.yml',
//            become: true,
//            becomeUser: 'jenkins',
//            extraVars: [
//                    ARTIFACT_URL: '${artifactUrl}',
//                    APP_NAME:'${APP_NAME}'
//            ]
//        }
//    }
//}