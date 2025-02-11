@Library('JenkinsTesLib') _  // Import the shared library

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
    
    // Stage to verify that the shared library is loaded
    stage('Initialize Shared Library') {
      steps {
        script {
          sharedLib.announce()
        }
      }
    }

    stage('Lint Dockerfile with Hadolint') {
      when {
        changeset "**/Dockerfile"
      }
      steps {
        script {
          echo "Running Hadolint to check Dockerfile..."
          sh 'hadolint Dockerfile'
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

    stage('Vulnerability Scan with Trivy') {
      steps {
        script {
          def imageTag = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"
          echo "Scanning the Docker image ${imageTag} for vulnerabilities..."
          sh """
            trivy image --exit-code 1 --severity HIGH,CRITICAL --no-progress ${imageTag} || echo "Vulnerability scan failed. Proceeding with the pipeline."
          """
        }
      }
    }

    stage('Push Docker Image to Docker Hub') {
      steps {
        script {
          def fullImageTag = "${DOCKER_USER}/${env.IMAGE_NAME}:v1.0"
          // Now call with two parameters only
          dockerUtils.buildAndPushImage(fullImageTag, env.IMAGE_NAME)
        }
      }
    }


    stage('Stop Existing Container for Selected Environment') {
      steps {
        script {
          // Use the shared library function to stop and remove containers on the given port.
          dockerUtils.stopAndRemoveContainers(env.DEPLOY_PORT)
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
