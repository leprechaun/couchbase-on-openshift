pipeline {

  agent any

  stages {
    stage("Apply OC Build-Time things") {
      steps {
        sh "oc apply -f oc-manifests/build-time/"
      }
    }

    stage('Sanity Checks') {
      steps {
        parallel (
          "Commit message format": {
            sh "git rev-parse HEAD"
          },
          "Dunno": {
            echo 'done'
          },

          "BuildConfigs": {
            sh "oc get bc"
          }
        )
      }
    }

    stage('Tests') {
      steps {
        parallel (
          "Unit Tests": {
            echo 'done'
          },
          "Function Tests": {
            echo 'done'
          },
          "Urine Tests": {
            sh "cat Jenkinsfile"
          }
        )
      }
    }

    stage("Build Images") {
      steps {
        script {
          def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
          def shortCommit = gitCommit.take(8)
          openshiftBuild(
            bldCfg: 'image-leprechaun-couchbase-os',
            showBuildLogs: 'true',
            commit: shortCommit
          )

          openshiftTag(
            sourceStream: 'leprechaun-couchbase-os',
            sourceTag: 'latest',
            destinationStream: 'leprechaun-couchbase-os',
            destinationTag: shortCommit
          )
        }
      }
    }

    stage("Apply OC Run-Time things") {
      steps {
        sh "oc apply -f oc-manifests/run-time/"
      }
    }

    stage("Trigger the nginx build ...") {
      steps {
        script {
          openshiftBuild(
            bldCfg: 'image-leprechaun-jenkins-blue-test',
            showBuildLogs: 'true'
          )

          openshiftTag(
            sourceStream: 'leprechaun-jenkins-blue-test',
            sourceTag: 'latest',
            destinationStream: 'leprechaun-jenkins-blue-test',
            destinationTag: shortCommit
          )
        }
      }
    }



  }
}
