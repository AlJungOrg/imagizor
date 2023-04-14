pipeline{
    agent any

    environment{
        TEST_DIR = "Test"
        TEST_SCRIPT = "main_test.sh"
    }

    options{
        // enabling timestamps in console output of log
        timestamps ()
    }

    stages {
        stage("Test") {
            steps {
                echo "Running Tests..."
                dir("${env.TEST_DIR}"){
                    sh "./${env.TEST_SCRIPT}"
                }
            }
        }

        stage("Build") {
            steps {
                script {
                    currentBuild.displayName = "#${BUILD_NUMBER}-${BRANCH_NAME}-${GIT_COMMIT}"
                    currentBuild.description = "Built #${BUILD_NUMBER}" + 
                                               "from branch '${BRANCH_NAME}' @ ${NODE_NAME}" + 
                                               "with commit ${GIT_COMMIT}"
                }
            }
        }

    }

       // post step
    post {
        success {
            echo "Build #${BUILD_NUMBER} succeeded for branch ${BRANCH_NAME} and commit ${GIT_COMMIT}. Current build status: ${currentBuild.currentResult}."
        }
        unstable {
            echo "Build #${BUILD_NUMBER} is unstable for branch ${BRANCH_NAME} and commit ${GIT_COMMIT}. Current build status: ${currentBuild.currentResult}."
        }
        failure {
            echo "Build #${BUILD_NUMBER} failed for branch ${BRANCH_NAME} and commit ${GIT_COMMIT}. Current build status: ${currentBuild.currentResult}."
        }
        always {

            echo "Cleaning workspace ..."
            // clean workspace
            cleanWs()
        }
    }
}