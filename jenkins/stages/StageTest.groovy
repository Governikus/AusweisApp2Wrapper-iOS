def name = 'StageTest'
def cacheDir = 'test'
return {
	echo "Entering ${name}"
	sh "rm -rf ${cacheDir}; rm -rf AusweisApp2SDKWrapper/build/${cacheDir}"
	sh "cd AusweisApp2SDKWrapper; xcodebuild test -scheme SDKWrapperTests -destination \"platform=iOS Simulator,name=iPhone 15\" -derivedDataPath build/${cacheDir} -clonedSourcePackagesDirPath ../${cacheDir}"
}