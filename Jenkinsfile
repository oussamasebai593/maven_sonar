pipeline {
    agent any

    environment {
        HOST_PORT = "9090"       // Port على السيرفر
        CONTAINER_PORT = "8080"  // Port التطبيق داخليًا داخل Docker
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

        stage('Run App Container') {
            steps {
                sh """
                # Remove old container if exists
                docker rm -f devops-app-container || true

                # Run new container
                docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} \
                    --name devops-app-container devops-app:latest
                """
            }
        }

        stage('OWASP ZAP DAST Scan') {
            steps {
                sh """
                mkdir -p zap-report
                chmod 777 zap-report
                docker run --network=host \
                -v \$(pwd)/zap-report:/zap/wrk \
                ghcr.io/zaproxy/zaproxy:stable \
                zap-baseline.py \
                -t http://localhost:${HOST_PORT} \
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
