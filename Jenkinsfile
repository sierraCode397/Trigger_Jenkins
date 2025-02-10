pipeline {
  agent any

  environment {
    // Set default branch to 'main' if BRANCH_NAME is not defined
    BRANCH = "${env.BRANCH_NAME ?: 'main'}"
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
        // Optionally, you may run "npm run build" if your app requires a build step.
        // If the requirement is just "npm install" for building, remove the following line.
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
          // Use different image names based on branch
          def imageTag = (BRANCH == 'dev') ? 'nodedev:v1.0' : 'nodemain:v1.0'
          echo "Building Docker image with tag: ${imageTag}"
          sh "docker build -t ${imageTag} ."
        }
      }
    }
    
    stage('Pre-Deploy Cleanup') {
      steps {
        script {
          // Stop and remove any running containers using the same image
          def imageTag = (BRANCH == 'dev') ? 'nodedev:v1.0' : 'nodemain:v1.0'
          echo "Stopping and removing any running containers for image ${imageTag}..."
          // List container IDs running this image and stop/remove them if they exist
          sh '''
            containers=$(docker ps -q --filter "ancestor=''' + imageTag + '''")
            if [ ! -z "$containers" ]; then
              docker stop $containers
              docker rm $containers
            else
              echo "No running containers found for image ''' + imageTag + '''"
            fi
          '''
        }
      }
    }
    
    stage('Deploy') {
      steps {
        script {
          if (BRANCH == 'dev') {
            echo "Deploying dev branch on port 3001..."
            // For dev branch, expose port 3001 externally, mapping it to container port 3000
            sh "docker run -d --expose 3001 -p 3001:3000 nodedev:v1.0"
          } else {
            echo "Deploying main branch on port 3000..."
            sh "docker run -d --expose 3000 -p 3000:3000 nodemain:v1.0"
          }
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
