pipeline {
    agent any

    environment {
        HOST_PORT = "9090"       // Port على السيرفر
        CONTAINER_PORT = "8080"  // Port التطبيق داخل Docker
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube_test_server') {
                    sh 'mvn clean package sonar:sonar'
                }
            }
        }

        stage('Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'DP'
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

        stage('Run App Container') {
            steps {
                sh """
                    # إزالة أي container قديم
                    docker rm -f devops-app-container || true

                    # تشغيل container جديد
                    docker run -d --name devops-app-container -p ${HOST_PORT}:${CONTAINER_PORT} devops-app:latest
                """

                // التأكد أن التطبيق جاهز قبل ZAP
                sh """
                    for i in {1..15}; do
                        curl -s http://localhost:${HOST_PORT} && break || sleep 2
                    done
                """
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                // استخدام ZAP Plugin مباشرة
                zap baseline: true,
                    failBuildOnHigh: true,
                    reportFileName: 'zap-report.html',
                    scanTarget: "http://localhost:${HOST_PORT}",
                    zapInstallation: 'ZAP_CLI'
            }
        }

        stage('Publish Reports') {
            steps {
                publishHTML(target: [
                    reportName: 'OWASP ZAP Report',
                    reportDir: '.',
                    reportFiles: 'zap-report.html',
                    keepAll: true
                ])

                publishHTML(target: [
                    reportName: 'Dependency Check Report',
                    reportDir: 'dependency-check-report',
                    reportFiles: 'dependency-check-report.html',
                    keepAll: true
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
