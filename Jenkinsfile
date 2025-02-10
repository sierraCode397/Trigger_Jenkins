pipeline {
  agent any

  // Optionally, you can add environment variables if needed
  environment {
    // Define a default value for the branch in case env.BRANCH_NAME is not set (e.g., in a manual build)
    BRANCH = "${env.BRANCH_NAME ?: 'main'}"
  }

  stages {
    stage('Checkout') {
      steps {
        // Checkout the code from the branch that triggered the build
        checkout scm
      }
    }
    
    stage('Build') {
      steps {
        echo "Building the application..."
        // For example, if using Node.js: install dependencies and build the app.
        sh 'npm install'
        sh 'npm run build'
      }
    }
    
    stage('Test') {
      steps {
        echo "Running tests..."
        // Run your tests (update command based on your test framework)
        sh 'npm test'
      }
    }
    
    stage('Build Docker Image') {
      steps {
        script {
          // Determine the image tag based on the branch
          def imageTag = (BRANCH == 'dev') ? 'myapp:dev' : 'myapp:latest'
          echo "Building Docker image with tag: ${imageTag}"
          // Build the Docker image (update Dockerfile as needed)
          sh "docker build -t ${imageTag} ."
        }
      }
    }
    
    stage('Deploy') {
      steps {
        script {
          // Set the deployment port based on the branch:
          // For 'dev' branch use port 3001, for 'main' branch use port 3000.
          def deployPort = (BRANCH == 'dev') ? 3001 : 3000
          echo "Deploying the application on port: ${deployPort}"
          // Deploy the application using the Docker image built earlier.
          // For example, run a Docker container mapping deployPort to container port (assumed here as 8080):
          sh "docker run -d -p ${deployPort}:8080 ${BRANCH == 'dev' ? 'myapp:dev' : 'myapp:latest'}"
        }
      }
    }
  }

  // Optionally add post actions (e.g., notifications or clean up)
  post {
    always {
      echo "Pipeline execution completed."
    }
  }
}
