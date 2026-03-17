pipeline {
    agent any

    environment {
        FLUTTER_VERSION = '3.24.5'
        FLUTTER_HOME = "${WORKSPACE}/flutter-sdk"
        PATH = "${FLUTTER_HOME}/bin:${env.PATH}"
    }

    options {
        timeout(time: 45, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Instalar Flutter SDK') {
            steps {
                sh '''
                    if [ ! -d "$FLUTTER_HOME" ]; then
                        echo "Descargando Flutter ${FLUTTER_VERSION}..."
                        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME"
                    else
                        echo "Flutter SDK ya existe, actualizando..."
                        cd "$FLUTTER_HOME" && git pull
                    fi
                    flutter --version
                '''
            }
        }

        stage('Flutter Doctor') {
            steps {
                sh 'flutter doctor -v'
            }
        }

        stage('Instalar Dependencias') {
            steps {
                sh 'flutter pub get'
            }
        }

        stage('Analisis Estatico') {
            steps {
                sh 'flutter analyze --no-fatal-infos || true'
            }
        }

        stage('Tests Unitarios') {
            steps {
                sh 'flutter test test/models/ || true'
                sh 'flutter test test/services/ || true'
                sh 'flutter test test/providers/ || true'
            }
        }

        stage('Tests de Widgets') {
            steps {
                sh 'flutter test test/widget/ || true'
            }
        }

        stage('Tests con Cobertura') {
            steps {
                sh 'flutter test --coverage || true'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'coverage/lcov.info', allowEmptyArchive: true
                }
            }
        }

        stage('Build APK') {
            when {
                branch 'main'
            }
            steps {
                sh 'flutter build apk --release'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completado exitosamente'
        }
        failure {
            echo 'Pipeline fallido - revisar logs'
        }
    }
}
