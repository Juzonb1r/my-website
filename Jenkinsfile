pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "juzonb1r"
    IMAGE_NAME     = "my-website"
    IMAGE_TAG      = "${BUILD_NUMBER}"
    FULL_IMAGE     = "docker.io/${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }


    stage('Build Docker Image') {
      steps {
         sh '''
           docker buildx build \
            --platform linux/amd64 \
            -t juzonb1r/my-website:${BUILD_NUMBER} \
            --push .
           '''
      }
    }


    stage('Login to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            docker logout || true
            printf "%s" "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
          '''
        }
      }
    }

    stage('Push Image') {
      steps {
        sh '''
          docker push "$FULL_IMAGE"
        '''
      }
    }
  }
}
