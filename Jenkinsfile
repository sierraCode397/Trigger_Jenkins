pipeline {
  agent any

  stages {

    stage('Set Deployment Variables') {
      steps {
        script {
          // Set variables based on branch (env.BRANCH_NAME is automatically set in a multibranch pipeline)
          env.DEPLOY_PORT = (env.BRANCH_NAME == 'dev') ? '3001' : '3000'
          env.IMAGE_NAME = (env.BRANCH_NAME == 'dev') ? 'nodedev' : 'nodemain'
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
          // Hardcoded Docker credentials (for testing purposes)
          def DOCKER_USER = 'isaacluisjuan107'  // Your Docker Hub username
          def DOCKER_PASS = 'Maverick$@1'     // Your Docker Hub password

          echo "Logging in to Docker Hub as ${DOCKER_USER}..."
          sh """
            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
          """

          // Define the full image name inside the block to ensure DOCKER_USER is accessible
          def imageTag = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"
          def latestTag = "${DOCKER_USER}/${env.IMAGE_NAME}:latest"

          echo "Tagging and pushing ${imageTag} and ${latestTag} to Docker Hub..."
          sh "docker tag ${env.IMAGE_NAME}:v1.0 ${imageTag}"
          sh "docker push ${imageTag}"

          sh "docker tag ${env.IMAGE_NAME}:v1.0 ${latestTag}"
          sh "docker push ${latestTag}"

          sh "docker logout"
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
            build job: 'Deploy_to_dev', parameters: [string(name: 'FULL_IMAGE', value: "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0")], wait: false
          } else {
            echo "Triggering Deploy_to_main job..."
            build job: 'Deploy_to_main', parameters: [string(name: 'FULL_IMAGE', value: "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0")], wait: false
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
