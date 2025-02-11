pipeline {
  agent any

  // Hardcoded Docker Hub credentials
  environment {
    DOCKER_USER = 'isaacluisjuan107'
    DOCKER_PASS = 'Maverick$@1'
  }

  stages {

    stage('Set Deployment Variables') {
      steps {
        script {
          // Set variables based on branch (env.BRANCH_NAME is automatically set in a multibranch pipeline)
          env.DEPLOY_PORT = (env.BRANCH_NAME == 'dev') ? '3001' : '3000'
          env.IMAGE_NAME  = (env.BRANCH_NAME == 'dev') ? 'nodedev' : 'nodemain'
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
          def localImageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Building Docker image with tag: ${localImageTag}"
          sh "docker build -t ${localImageTag} ."
        }
      }
    }

    stage('Push Docker Image to Docker Hub') {
      steps {
        script {
          echo "Logging in to Docker Hub as ${DOCKER_USER}..."
          // Login non-interactively using the hardcoded credentials.
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
          '''

          // Define the full image tags for v1.0 and latest.
          def fullImageTag = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"
          def latestTag   = "${DOCKER_USER}/${env.IMAGE_NAME}:latest"

          echo "Tagging local image ${env.IMAGE_NAME}:v1.0 as ${fullImageTag} and ${latestTag}"
          
          // Tag and push the image.
          sh "docker tag ${env.IMAGE_NAME}:v1.0 ${fullImageTag}"
          sh "docker push ${fullImageTag}"

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
          def localImageTag = "${env.IMAGE_NAME}:v1.0"
          echo "Running container locally: ${localImageTag} on port ${env.DEPLOY_PORT}..."
          // Run the container locally from the built image.
          sh "docker run -d --expose ${env.DEPLOY_PORT} -p ${env.DEPLOY_PORT}:3000 ${localImageTag}"
        }
      }
    }

    stage('Trigger Deployment Pipeline') {
      steps {
        script {
          // Construct the full image tag using the hardcoded DOCKER_USER.
          def fullImageTag = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"

          if (env.BRANCH_NAME == 'dev') {
            echo "Triggering Deploy_to_dev job with image ${fullImageTag}..."
            build job: 'Deploy_to_dev', parameters: [
              string(name: 'FULL_IMAGE', value: fullImageTag)
            ], wait: false
          } else {
            echo "Triggering Deploy_to_main job with image ${fullImageTag}..."
            build job: 'Deploy_to_main', parameters: [
              string(name: 'FULL_IMAGE', value: fullImageTag)
            ], wait: false
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
