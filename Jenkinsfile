pipeline {
    agent any

    environment {
        HOST_PORT = "9090"       // البورت الذي سيعمل عليه التطبيق على السيرفر
        CONTAINER_PORT = "8080"  // البورت الداخلي داخل الـ Docker container
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
                # إزالة أي نسخة قديمة
                docker rm -f devops-app-container || true

                # تشغيل التطبيق
                docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} \
                    --name devops-app-container devops-app:latest
                """
            }
        }

        stage('Dependency Check') {
            steps {
                // اسم أداة Dependency Check التي ثبتتها في Jenkins هو DP
                dependencyCheck additionalArguments: '', odcInstallation: 'DP', scanSet: '**/*.jar', skipOnError: false
            }
        }

        stage('OWASP ZAP DAST Scan') {
            steps {
                sh """
                mkdir -p zap-report
                docker run -u root --network=host \
                    -v \$(pwd)/zap-report:/zap/wrk \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py \
                    -t http://localhost:${HOST_PORT} \
                    -r /zap/wrk/zap-report.html
                """
            }
        }

        stage('Publish Reports') {
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
