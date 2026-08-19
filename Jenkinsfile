pipeline {
    agent any

    // Define variables for ECR and generate the Git Commit Hash tag
    environment {
        AWS_REGION = "ap-south-1"
        ECR_REGISTRY = "998461586572.dkr.ecr.ap-south-1.amazonaws.com"
        ECR_REPO = "go-app"
        
        // Grabs the short Git commit hash to use as the unique image tag
        IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim() 
        FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
    }

    stages {
        stage('Git CheckOut') {
            steps {
                git branch: 'main', credentialsId: 'git-creds', url: 'https://github.com/19bcs22Ravi/Go-Application.git'
            }
        }
        
        stage('Go Test') {
            steps {
                sh '''
                     export CGO_ENABLED=0
                     go test -v -coverprofile=coverage.out ./...
                     go vet ./...
                   '''
            }
        }
        
        stage('Go Build') {
            steps {
                sh '''
                     export CGO_ENABLED=0
                     export GOOS=linux
                     export GOARCH=amd64
                     go build -o go-app .
                   '''
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh '''
                   trivy fs \
                   --scanners vuln \
                   --severity HIGH,CRITICAL \
                   --exit-code 1 \
                   .
                   '''
            }
        }
        
        stage('SonarQube Analysis') {
            environment {
                SCANNER_HOME = tool 'sonar-scanner' 
            }
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=Go-App \
                        -Dsonar.projectName=Go-App \
                        -Dsonar.sources=. \
                        -Dsonar.go.coverage.reportPaths=coverage.out \
                        -Dsonar.exclusions=**/vendor/**,**/static/**
                        '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    echo "Building Docker image: $FULL_IMAGE_NAME"
                    docker build -t $FULL_IMAGE_NAME .
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    echo "Scanning Docker image for critical vulnerabilities..."
                    trivy image \
                    --scanners vuln \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    $FULL_IMAGE_NAME
                '''
            }
        }

        stage('Push to Private AWS ECR') {
            steps {
                sh '''
                    echo "Authenticating with private AWS ECR..."
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                    
                    echo "Pushing image to ECR..."
                    docker push $FULL_IMAGE_NAME
                '''
            }
        }
        stage('Update Helm Values') {
            steps {
                sh '''
                    echo "Updating image tag in values.yaml to $IMAGE_TAG"
                    # This replaces whatever comes after 'tag: ' with your new IMAGE_TAG
                    sed -i "s/tag: .*/tag: $IMAGE_TAG/g" HelmCharts/go-app/values.yaml
                '''
            }
        }
        stage('Commit and Push to GitHub') {
            steps {
                // Use the same credentials you used in the checkout stage
                withCredentials([usernamePassword(credentialsId: 'git-creds', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh '''
                        git config user.email "jenkins@server.local"
                        git config user.name "Jenkins CI"
                        
                        git add HelmCharts/go-app/values.yaml
                        git commit -m "chore: update image tag to $IMAGE_TAG [skip ci]"
                        
                        # Push back to main branch securely
                        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/19bcs22Ravi/Go-Application.git HEAD:main
                    '''
                }
            }
        }
    }
}