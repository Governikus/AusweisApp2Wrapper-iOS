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
		stage('Cleanup') {
			steps {
				cleanWs(
					deleteDirs: true,
					disableDeferredWipeout: true
				)
			}
		}
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
				script {
					def executor = load 'jenkins/Stage_Patch.groovy'
					executor()
				}
			}
		}
		stage('Static analysis') {
			steps {
				script {
					sh 'swiftlint --strict'
				}
			}
		}
		stage('Sonar') {
			when { expression { params.performSonarScan } }
			steps {
				script {
					def pullRequestParams = params.activateReviewBuildParams ? '-Dsonar.pullrequest.key=${REVIEWBOARD_REVIEW_ID} -Dsonar.pullrequest.branch=${REVIEWBOARD_REVIEW_ID} -Dsonar.pullrequest.base=${REVIEWBOARD_REVIEW_BRANCH}' : '-Dsonar.branch.name=${REVIEWBOARD_REVIEW_BRANCH}'
					catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
						sh "sonar-scanner -Dsonar.scanner.metadataFilePath=\${WORKSPACE}/tmp/sonar-metadata.txt -Dsonar.projectName=AusweisApp-SDKWrapper-iOS ${pullRequestParams} -Dsonar.token=\${SONARQUBE_TOKEN} -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=90"
					}
				}
			}
		}
		stage('Copy Swift Package') {
			when { expression { params.spmSource != 'github' } }
			steps {
				script {
					def executor = load 'jenkins/Stage_CopySwiftPkg.groovy'
					executor(params.spmSource)
				}
			}
		}
		stage('Resolve Swift Package dependencies') {
			steps {
				script {
					def derivedDataDir = 'ResolvedDerivedData'
					sh "rm -rf ${derivedDataDir}; rm -rf AusweisApp2SDKWrapper/build/${derivedDataDir}"
					sh "cd AusweisApp2SDKWrapper; xcodebuild -scheme AusweisApp2SDKWrapper -resolvePackageDependencies -derivedDataPath build/${derivedDataDir} -clonedSourcePackagesDirPath ../${derivedDataDir}"
				}
			}
		}
		stage('Compile SDKWrapper') {
			steps {
				script {
					def commonBuildPrefix = 'cd AusweisApp2SDKWrapper; xcodebuild archive -workspace SDKWrapper.xcworkspace -scheme AusweisApp2SDKWrapper'
					def osNameBuildCmdStemMap = [
						"iphoneos" : "${commonBuildPrefix} -sdk iphoneos -destination \"platform=iOS,name=Any iOS Device\" -configuration MinSizeRel ARCHS='arm64'",
						"iphonesimulator-arm64" : "${commonBuildPrefix} -sdk iphonesimulator -destination \"platform=iOS Simulator,name=Any iOS Simulator Device\" -configuration MinSizeRel ARCHS='arm64'",
						"iphonesimulator-x86_64" : "${commonBuildPrefix} -sdk iphonesimulator -destination \"platform=iOS Simulator,name=Any iOS Simulator Device\" -configuration MinSizeRel ARCHS='x86_64'"
					]

					sh 'security unlock-keychain ${KEYCHAIN_CREDENTIALS} ${HOME}/Library/Keychains/login.keychain-db'
					osNameBuildCmdStemMap.each{entry -> sh "rm -rf ${entry.key}; rm -rf AusweisApp2SDKWrapper/build/${entry.key}" }
					osNameBuildCmdStemMap.each{osName, buildCmdStem -> sh "${buildCmdStem} -derivedDataPath build/${osName} -clonedSourcePackagesDirPath ../${osName} -archivePath build/AusweisApp2SDKWrapper-${osName}.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES" }
				}
			}
		}
		stage('Test') {
			steps {
				script {
					def cacheDir = 'test'
					sh "rm -rf ${cacheDir}; rm -rf AusweisApp2SDKWrapper/build/${cacheDir}"
					sh "cd AusweisApp2SDKWrapper; xcodebuild test -scheme SDKWrapperTests -destination \"platform=iOS Simulator,name=iPhone 15\" -derivedDataPath build/${cacheDir} -clonedSourcePackagesDirPath ../${cacheDir}"
				}
			}
		}
		stage('Package xcframework') {
			steps {
				script {
					sh 'cd AusweisApp2SDKWrapper; mkdir -p build/AusweisApp2SDKWrapper-iphoneos.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/Modules'
					sh 'cd AusweisApp2SDKWrapper; cp -r build/iphoneos/Build/Intermediates.noindex/ArchiveIntermediates/AusweisApp2SDKWrapper/BuildProductsPath/MinSizeRel-iphoneos/AusweisApp2SDKWrapper.swiftmodule build/AusweisApp2SDKWrapper-iphoneos.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/Modules/AusweisApp2SDKWrapper.swiftmodule'

					sh 'cd AusweisApp2SDKWrapper; cp -r build/AusweisApp2SDKWrapper-iphonesimulator-arm64.xcarchive build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive'
					sh 'cd AusweisApp2SDKWrapper; lipo -create -output build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/AusweisApp2SDKWrapper build/AusweisApp2SDKWrapper-iphonesimulator-arm64.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/AusweisApp2SDKWrapper build/AusweisApp2SDKWrapper-iphonesimulator-x86_64.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/AusweisApp2SDKWrapper'
					sh 'cd AusweisApp2SDKWrapper; mkdir -p build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/Modules'
					sh 'cd AusweisApp2SDKWrapper; cp -r build/iphonesimulator-arm64/Build/Intermediates.noindex/ArchiveIntermediates/AusweisApp2SDKWrapper/BuildProductsPath/MinSizeRel-iphonesimulator/AusweisApp2SDKWrapper.swiftmodule build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/Modules/'
					sh 'cd AusweisApp2SDKWrapper; cp -r build/iphonesimulator-x86_64/Build/Intermediates.noindex/ArchiveIntermediates/AusweisApp2SDKWrapper/BuildProductsPath/MinSizeRel-iphonesimulator/AusweisApp2SDKWrapper.swiftmodule build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework/Modules/'

					sh 'cd AusweisApp2SDKWrapper; xcodebuild -create-xcframework -framework build/AusweisApp2SDKWrapper-iphoneos.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework -framework build/AusweisApp2SDKWrapper-iphonesimulator.xcarchive/Products/Library/Frameworks/AusweisApp2SDKWrapper.framework -output build/spm/AusweisApp2SDKWrapper.xcframework'

					sh 'cd AusweisApp2SDKWrapper; cp -r Sources/ build/spm'
					sh 'cd AusweisApp2SDKWrapper; cp -r packaging/ build/spm'

					sh 'cd AusweisApp2SDKWrapper; mkdir -p build/dist'
					sh 'cd AusweisApp2SDKWrapper/build/spm; zip -r ../dist/AusweisApp2SDKWrapper.xcframework.zip AusweisApp2SDKWrapper.xcframework Package.swift Sources'
					sh 'cd AusweisApp2SDKWrapper/build; zip -r dist/AusweisApp2SDKWrapper-iphoneos.framework.dSYM.zip AusweisApp2SDKWrapper-iphoneos.xcarchive/dSYMs/AusweisApp2SDKWrapper.framework.dSYM'
					sh 'cd AusweisApp2SDKWrapper/build; zip -r dist/AusweisApp2SDKWrapper-iphonesimulator-arm64.framework.dSYM.zip AusweisApp2SDKWrapper-iphonesimulator-arm64.xcarchive/dSYMs/AusweisApp2SDKWrapper.framework.dSYM'
					sh 'cd AusweisApp2SDKWrapper/build; zip -r dist/AusweisApp2SDKWrapper-iphonesimulator-x86_64.framework.dSYM.zip AusweisApp2SDKWrapper-iphonesimulator-x86_64.xcarchive/dSYMs/AusweisApp2SDKWrapper.framework.dSYM'
				}
			}
		}
		stage('Verify formatting') {
			steps {
				script {
					sh 'hg commit --addremove --secret -u jenkins -m review || exit 0'
					sh 'swiftformat --indent tab --commas inline AusweisApp2SDKWrapper SDKWrapperTester'
					sh('''\
						STATUS=$(hg status | wc -c | xargs)
						if [ "$STATUS" != "0" ]; then
							echo 'FORMATTING FAILED: Patch is not formatted'
							hg diff
							hg revert -a -C
							exit 1
						fi
						'''.stripIndent().trim())
				}
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
