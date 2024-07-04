pipeline {
	agent {
		node {
			label 'iOS'
			customWorkspace params.WORKSPACE ?: env.WORKSPACE
		}
	}
	parameters {
		string( name: 'REVIEWBOARD_REVIEW_ID', defaultValue: '', description: 'ID of the Review' )
		string( name: 'REVIEWBOARD_REVIEW_BRANCH', defaultValue: 'default', description: 'Branch/Revision' )
		string( name: 'REVIEWBOARD_SERVER', defaultValue: '', description: 'Server' )
		string( name: 'REVIEWBOARD_STATUS_UPDATE_ID', defaultValue: '', description: '' )
		string( name: 'REVIEWBOARD_DIFF_REVISION', defaultValue: '', description: '' )
		booleanParam( name: 'performSonarScan', defaultValue: false, description: 'Perform a sonar scan')
		string( name: 'spmSource', defaultValue: 'github', description: 'Source of the AA2 Swift Package.\nExamples: github, local repositories' )
		booleanParam( name: 'activateReviewBuildParams', defaultValue: false, description: 'Will enable certain params/options that are specific to review builds')
		booleanParam( name: 'runReviewBoardUpdate', defaultValue: true, description: 'Update the corresponding ReviewBoard review.')
	}
	options {
		skipStagesAfterUnstable()
		disableConcurrentBuilds()
		timeout(time: 30, unit: 'MINUTES')
	}
	stages {
		stage('Checkout') {
			steps {
				script {
					currentBuild.description = "${params.spmSource}"
				}
				checkout( [
					$class : 'MercurialSCM',
					revisionType: 'TAG',
					revision: "${params.REVIEWBOARD_REVIEW_BRANCH}",
					clean  : true,
					source : 'https://hg.governikus.de/AusweisApp/SDKWrapper-iOS'
				] )
			}
		}
		stage('Patch') {
			when { expression { params.REVIEWBOARD_REVIEW_ID != '' } }
			steps {
				executeParameterLessStageScript('StagePatch')
			}
		}
		stage('Static analysis') {
			steps {
				executeParameterLessStageScript('StageStaticAnalysis')
			}
		}
		stage('Sonar') {
			when { expression { params.performSonarScan } }
			steps {
				script {
					def executor = load 'jenkins/stages/StageSonar.groovy'
					executor(params.activateReviewBuildParams)
				}
			}
		}
		stage('Copy Swift Package') {
			when { expression { params.spmSource != 'github' } }
			steps {
				script {
					def executor = load 'jenkins/stages/StageCopySwiftPkg.groovy'
					executor(params.spmSource)
				}
			}
		}
		stage('Resolve Swift Package dependencies') {
			steps {
				executeParameterLessStageScript('StageResolveSwiftPkgDependencies')
			}
		}
		stage('Compile SDKWrapper') {
			steps {
				executeParameterLessStageScript('StageCompileWrapper')
			}
		}
		stage('Test') {
			steps {
				executeParameterLessStageScript('StageTest')
			}
		}
		stage('Package xcframework') {
			steps {
				executeParameterLessStageScript('StagePackageXcframework')
			}
		}
		stage('Verify formatting') {
			steps {
				executeParameterLessStageScript('StageVerifyFormatting')
			}
		}
	}

	post {
		always {
			script {
				if (params.runReviewBoardUpdate && params.REVIEWBOARD_REVIEW_ID != '') {
					def rb_result = "error"
					def rb_desc = "build failed."
					if (currentBuild.result == 'SUCCESS') {
						rb_result = "done-success"
						rb_desc = "build succeeded."
					}

					withCredentials([string(credentialsId: 'RBToken', variable: 'RBToken')]) {
						sh "rbt status-update set --state ${rb_result} --description '${rb_desc}' -r ${params.REVIEWBOARD_REVIEW_ID} -s ${params.REVIEWBOARD_STATUS_UPDATE_ID} --server ${params.REVIEWBOARD_SERVER} --username jenkins --api-token $RBToken"
					}
				}
			}
		}
	}
}

def executeParameterLessStageScript(String stageFilePath) {
	script {
		def executor = load "jenkins/stages/${stageFilePath}.groovy"
		executor()
	}
}