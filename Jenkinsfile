pipeline {
  agent any

  stages {

    stage('Set Deployment Variables') {
      steps {
        script {
          // Set variables based on branch (env.BRANCH_NAME is automatically set in a multibranch pipeline)
          env.DEPLOY_PORT = (env.BRANCH_NAME == 'dev') ? '3001' : '3000'
          env.IMAGE_NAME = (env.BRANCH_NAME == 'dev') ? 'nodedev' : 'nodemain'
          env.FULL_IMAGE = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"  // We'll set DOCKER_USER below via credentials.
          echo "Branch: ${env.BRANCH_NAME} -> Will deploy image ${env.IMAGE_NAME}:v1.0 on port ${env.DEPLOY_PORT}"
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
    
    stage('Push Docker Image to Docker Hub') {
      steps {
        script {
          // Use Docker credentials to log in and push the image.
          // We need to retrieve the DOCKER_USER from credentials.
          withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            echo "Logging in to Docker Hub as ${DOCKER_USER}..."
            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
            def imageTag = "${env.IMAGE_NAME}:v1.0"
            def fullImage = "${DOCKER_USER}/${imageTag}"
            echo "Pushing image ${fullImage} to Docker Hub..."
            sh "docker tag ${imageTag} ${fullImage}"
            sh "docker push ${fullImage}"
            sh "docker logout"
            // Save the full image name for later use (for triggering downstream jobs)
            env.FULL_IMAGE = fullImage
          }
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
              echo "No running containers found for port ${env.DEPLOY_PORT}"
            fi
          """
        }
      }
    }
    
    stage('Deploy Local Container') {
      steps {
        script {
          def imageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Running container locally: ${imageTag} on port ${env.DEPLOY_PORT}..."
          // This stage deploys the container locally from the built image.
          // (This may be optional if your goal is to rely on the deployment pipelines below.)
          sh "docker run -d --expose ${env.DEPLOY_PORT} -p ${env.DEPLOY_PORT}:3000 ${imageTag}"
        }
      }
    }
    
    stage('Trigger Deployment Pipeline') {
      steps {
        script {
          // Automatically trigger the downstream deployment job based on branch.
          if (env.BRANCH_NAME == 'dev') {
            echo "Triggering Deploy_to_dev job..."
            build job: 'Deploy_to_dev', parameters: [string(name: 'FULL_IMAGE', value: env.FULL_IMAGE)], wait: false
          } else {
            echo "Triggering Deploy_to_main job..."
            build job: 'Deploy_to_main', parameters: [string(name: 'FULL_IMAGE', value: env.FULL_IMAGE)], wait: false
          }
        }
      }
    }
  }

  post {
    always {
      echo "Multibranch Pipeline execution completed."
    }
  }
}
