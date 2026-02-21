pipeline {
    agent any

    environment {
        HOST_PORT = "9090"
        CONTAINER_PORT = "8080"
        DOCKER_NETWORK = "devops-net"
    }

    stages {

        stage('Build & SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube_test_server') {
                    sh 'mvn clean package sonar:sonar'
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --exit-code 1 --severity CRITICAL,HIGH .'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t devops-app:latest .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH devops-app:latest'
            }
        }

        stage('Create Docker Network') {
            steps {
                sh "docker network inspect ${DOCKER_NETWORK} || docker network create ${DOCKER_NETWORK}"
            }
        }

        stage('Run App Container') {
            steps {
                sh """
                docker rm -f devops-app-container || true
                docker run -d --name devops-app-container --network ${DOCKER_NETWORK} \
                    -p ${HOST_PORT}:${CONTAINER_PORT} devops-app:latest
                """
            }
        }

        stage('OWASP ZAP DAST Scan') {
            steps {
                sh """
                mkdir -p zap-report
                docker run -u root --network ${DOCKER_NETWORK} \
                    -v \$(pwd)/zap-report:/zap/wrk \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py \
                    -t http://devops-app-container:${CONTAINER_PORT} \
                    -r /zap/wrk/zap-report.html
                """
            }
        }

        stage('Publish ZAP Report') {
            steps {
                publishHTML(target: [
                    reportName: 'OWASP ZAP Report',
                    reportDir: 'zap-report',
                    reportFiles: 'zap-report.html',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
            }
        }
    }

    post {
        always {
            echo "Cleaning up container..."
            sh 'docker stop devops-app-container || true'
            sh 'docker rm devops-app-container || true'
        }
    }
}
