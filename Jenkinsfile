pipeline {
  agent any

  environment {
    DEPLOY_PORT = (env.BRANCH_NAME == 'dev') ? '3001' : '3000'
    IMAGE_NAME = (env.BRANCH_NAME == 'dev') ? 'nodedev' : 'nodemain'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    
    stage('Build') {
      steps {
        echo "Building the NodeJS application..."
        sh 'npm install'
        sh 'npm run build'
      }
    }
    
    stage('Test') {
      steps {
        echo "Running tests..."
        sh 'npm test'
      }
    }
    
    stage('Build Docker Image') {
      steps {
        script {
          def imageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Building Docker image with tag: ${imageTag}"
          sh "docker build -t ${imageTag} ."
        }
      }
    }
    
    stage('Stop Existing Container for Selected Environment') {
      steps {
        script {
          echo "Stopping and removing any running containers on port ${DEPLOY_PORT}..."
          
          sh """
            containers=\$(docker ps -q --filter "publish=${DEPLOY_PORT}")
            if [ ! -z "\$containers" ]; then
              docker stop \$containers
              docker rm \$containers
            else
              echo "No running containers found for ${env.BRANCH_NAME} (port ${DEPLOY_PORT})"
            fi
          """
        }
      }
    }
    
    stage('Deploy Selected Image') {
      steps {
        script {
          def imageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Running container: ${imageTag} on port ${DEPLOY_PORT}..."
          sh "docker run -d --expose ${DEPLOY_PORT} -p ${DEPLOY_PORT}:3000 ${imageTag}"
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline execution completed."
    }
  }
}
