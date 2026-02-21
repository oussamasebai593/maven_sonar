pipeline {
    agent any

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
                sh 'docker run -d -p 9090:9090 --name devops-app-container devops-app:latest'
            }
        }

        stage('OWASP ZAP DAST Scan') {
            steps {
                sh '''
                docker run --network="host" \
                owasp/zap2docker-stable \
                zap-baseline.py \
                -t http://localhost:9090 \
                -r zap-report.html
                '''
            }
        }

        stage('Stop Container') {
            steps {
                sh 'docker stop devops-app-container || true'
                sh 'docker rm devops-app-container || true'
            }
        }
    }
}
