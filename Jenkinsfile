pipeline{
    agent any

    stages {
        stage("Test") {
            steps {
                echo "Running Tests..."
                sh "pwd"
                sh "./Tests/main_test.sh"
            }
        }

    }
}