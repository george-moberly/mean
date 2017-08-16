pipeline {
    agent any
    environment { 
        FOO = 'bar'
    }
    parameters {
        string(name: 'Greeting', defaultValue: 'Hello', description: 'How should I greet the world?')
    }
        stages {
        stage('Deploy Mongo Cluster') {
            steps {
                echo "Running ${env.JOB_NAME} build ${env.BUILD_ID} on ${env.JENKINS_URL}"
                echo "${params.Greeting} World!"
                echo 'Deploy Mongo Cluster..'
                sh '''
cd jenkins
sh -x ./demo_run.sh -x $SCRIPT_ARGS
                '''
            }
        }
        stage('Deploy Web Cluster') {
            steps {
                echo 'Deploy Web Cluster..'
                sh '''
cd jenkins
sh -x ./demo_run.sh -y $SCRIPT_ARGS
                '''
            }
        }
        stage('Build Web Application') {
            steps {
                echo 'Build Web Application....'
                sh '''
cd jenkins
sh -x ./demo_run.sh $SCRIPT_ARGS
                '''
            }
        }
    }
    post {
        always {
            echo 'This will always run'
        }
        success {
            echo 'This will run only if successful'
            slackSend channel: '#ops-room',
                  color: 'good',
                  message: "The pipeline ${currentBuild.fullDisplayName} completed successfully."
        }
        failure {
            echo 'This will run only if failed'
        }
        unstable {
            echo 'This will run only if the run was marked as unstable'
        }
        changed {
            echo 'This will run only if the state of the Pipeline has changed'
            echo 'For example, if the Pipeline was previously failing but is now successful'
        }
    }
}

