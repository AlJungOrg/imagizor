pipeline{
    agent any

    environment{
        TEST_DIR = "Test"
        TEST_SCRIPT = "main_test.sh"
    }

    stages {
        stage("Test") {
            steps {
                echo "Running Tests..."
                sh "(cd ${env.TEST_DIR}; ./${env.TEST_SCRIPT})"
            }
        }

        stage("Build") {
            steps {
                script {
                    currentBuild.displayName = "${BUILD_NUMBER}-${GIT_COMMIT}"
                    currentBuild.description = "Built ${BUILD_NUMBER}-${GIT_COMMIT}" + 
                                               "From Branch ${BRANCH_NAME} @ ${NODE_NAME}"
                }
            }
        }

    }
}