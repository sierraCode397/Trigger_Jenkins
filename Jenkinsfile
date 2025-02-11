pipeline {
  agent any

  stages {
    stage('Set Deployment Variables') {
      steps {
        script {
          env.DEPLOY_PORT = (env.BRANCH_NAME == 'dev') ? '3001' : '3000'
          env.IMAGE_NAME = (env.BRANCH_NAME == 'dev') ? 'nodedev' : 'nodemain'
          echo "Branch: ${env.BRANCH_NAME} → Deploying on port ${env.DEPLOY_PORT} using image ${env.IMAGE_NAME}:v1.0"
        }
      }
    }

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
          echo "Stopping and removing any running containers on port ${env.DEPLOY_PORT}..."
          
          sh """
            containers=\$(docker ps -q --filter "publish=${env.DEPLOY_PORT}")
            if [ ! -z "\$containers" ]; then
              docker stop \$containers
              docker rm \$containers
            else
              echo "No running containers found for ${env.BRANCH_NAME} (port ${env.DEPLOY_PORT})"
            fi
          """
        }
      }
    }
    
    stage('Deploy Selected Image') {
      steps {
        script {
          def imageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Running container: ${imageTag} on port ${env.DEPLOY_PORT}..."
          sh "docker run -d --expose ${env.DEPLOY_PORT} -p ${env.DEPLOY_PORT}:3000 ${imageTag}"
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
