pipeline {
    agent any

    environment {
        HOST_PORT = "9090"
        CONTAINER_PORT = "8080"
        APP_NAME = "devops-app-container"
        IMAGE_NAME = "devops-app:latest"
        ZAP_REPORT_DIR = "zap-report"
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
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image --exit-code 1 --severity CRITICAL,HIGH ${IMAGE_NAME}"
            }
        }

        stage('Run App Container') {
            steps {
                sh """
                docker rm -f ${APP_NAME} || true
                docker run -d --name ${APP_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${IMAGE_NAME}

                # Wait until the app is ready on port ${HOST_PORT}
                echo "Waiting for app to start..."
                for i in {1..20}; do
                    nc -z localhost ${HOST_PORT} && break
                    echo "Waiting 1s..."
                    sleep 1
                done
                """
            }
        }

        stage('OWASP ZAP DAST Scan') {
            steps {
                sh """
                mkdir -p ${ZAP_REPORT_DIR}
                docker run --network=host -u root \
                    -v \$(pwd)/${ZAP_REPORT_DIR}:/zap/wrk \
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
                    reportDir: "${ZAP_REPORT_DIR}",
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
            sh "docker stop ${APP_NAME} || true"
            sh "docker rm ${APP_NAME} || true"
        }
    }
}
