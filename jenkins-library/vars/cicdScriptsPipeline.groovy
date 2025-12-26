def call(Map config = [:], Closure body) {
  def agentLabel = config.agentLabel ?: 'any'

  pipeline {
    // Use agent label from config if provided
    agent {
      label agentLabel == 'any' ? '' : agentLabel
    }

    // Global options
    options {
      timestamps()
    }

    stages {
      stage('PipelineWrapper') {
        steps {
          script {
            // Set build name
            buildName(sh(script: "${env.CICD_SCRIPTS_DIR}/job/get_build_name.sh", returnStdout: true))

            def wrapperEnvs = []
            if (config.environment) {
              config.environment.each{ key, value -> wrapperEnvs << "$key=$value" }
            }
            if (config.setDockerRegistryEnvVars) {
              echo '### [cicdScriptsPipeline] config.setDockerRegistryEnvVars enabled, setting Docker Registry vars'
              withCredentials([string(credentialsId: 'DOCKER_REGISTRY_HOSTNAME', variable: 'DOCKER_REGISTRY_HOSTNAME')]) {
                def AERIUS_REGISTRY_PATH = sh(script: "${env.CICD_SCRIPTS_DIR}/docker/get_registry_path.sh", returnStdout: true)
                wrapperEnvs << "AERIUS_REGISTRY_PATH=${AERIUS_REGISTRY_PATH}"
                wrapperEnvs << "AERIUS_REGISTRY_URL=${DOCKER_REGISTRY_HOSTNAME}/${AERIUS_REGISTRY_PATH}/"
                wrapperEnvs << "AERIUS_IMAGE_TAG=" + sh(script: "${env.CICD_SCRIPTS_DIR}/docker/get_image_tag.sh", returnStdout: true)
              }
            }
            withEnv(wrapperEnvs) {
              body()
            }
          }
        }
      }
    }

    post {
      always {
        script {
          echo "### [cicdScriptsPipeline] Finished. Current Status: ${currentBuild.currentResult}"
          def notify = true
          if (env.JOB_NAME.toUpperCase().startsWith('PULLREQUESTCHECKER-')
            || (currentBuild.result == 'SUCCESS' && !env.JOB_NAME.toUpperCase().startsWith('QA-'))) {
            notify = false
          }
          if (notify) {
            withBuildUser {
              mattermostSend(
                channel: (env.MATTERMOST_CHANNEL ? "#${env.MATTERMOST_CHANNEL}" : null),
                color: sh(script: """${CICD_SCRIPTS_DIR}/job/notify_mattermost_color.sh "${currentBuild.result}" """, returnStdout: true),
                message: sh(script: """${CICD_SCRIPTS_DIR}/job/notify_mattermost_message.sh "${currentBuild.result}" "${currentBuild.durationString}" build """, returnStdout: true)
              )
            }
          }
        }
      }
    }
  }
}
