#!groovy

def commit_sha = 'UNKNOWN'

pipeline {

  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  agent {
    node {
      label 'docker'
    }
  }

  parameters {
    string(name: 'version', description: 'SCM-Manager Version to build')
  }  

  stages {

    stage('Environment') {
      steps {
        script {
          commit_sha = sh(returnStdout: true, script: 'git rev-parse HEAD')
        }
      }
    }

    stage('Build') {
      when {
        expression { params.version != null && !params.version.isEmpty() }
      }
      steps {
        echo "build image ${params.version} from ${commit_sha}"
        script {
          docker.withRegistry('', 'hub.docker.com-cesmarvin') {
            sh "./build.sh ${params.version} ${commit_sha}"
          }
        }
      }
    }

  }

}
