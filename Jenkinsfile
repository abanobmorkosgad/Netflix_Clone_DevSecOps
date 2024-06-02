pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        TMDB_TOKEN = "a20a396a2b4394f2565c4d934c628bc8"
        IMAGE_VERSION = "${env.BUILD_NUMBER}"
    }
    stages{
        stage("SonarQube Analysis"){
            steps{
                withSonarQubeEnv('sonar-server'){
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Netflix \
                          -Dsonar.projectKey=Netflix'''
                }
            }
        }
        stage("quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage("building and pushing docker image"){
            steps{
                withCredentials([
                    usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'USER', passwordVariable: 'PASS')
                ]){
                    sh "docker build --build-arg TMDB_V3_API_KEY=${TMDB_TOKEN} -t abanobmorkos10/netflix:${IMAGE_VERSION} ."
                    sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                    sh "docker push abanobmorkos10/netflix:${IMAGE_VERSION}"
                }
            }
        }
        stage("trivy scan"){
            steps{
                sh "trivy image abanobmorkos10/netflix:${IMAGE_VERSION} > trivy_scan.txt"
            }
        }
        stage("change image version in k8s") {
            steps {
                script {
                    sh "sed -i \"s|image:.*|image: ${NEXUS_SERVER}/boardgame:${IMAGE_TAG}|g\" k8s/deployment.yaml"
                }
            }
        }
        stage('Commit back the Deployment File') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        git config user.email "abanobmorkos10@gmail.com"
                        git config user.name "abanobmorkosgad"
                        git remote set-url origin https://${USER}:${PASS}@github.com/abanobmorkosgad/DevSecOps_Project.git
                        git add .
                        git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                        git push origin HEAD:main
                    '''
                }
            }
        }
    }
    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                  "Build Number: ${env.BUILD_NUMBER}<br/>" +
                  "URL: ${env.BUILD_URL}<br/>",
            to: 'abanobmorkos13@gmail.com',                                
            attachmentsPattern: 'trivy_scan.txt'
        }
    }
}