def name = 'StageCompileWrapper'
def commonBuildPrefix = 'cd AusweisApp2SDKWrapper; xcodebuild archive -workspace SDKWrapper.xcworkspace -scheme AusweisApp2SDKWrapper'
def osNameBuildCmdStemMap = [
	"iphoneos" : "${commonBuildPrefix} -sdk iphoneos -destination \"platform=iOS,name=Any iOS Device\" -configuration MinSizeRel ARCHS='arm64'",
	"iphonesimulator-arm64" : "${commonBuildPrefix} -sdk iphonesimulator -destination \"platform=iOS Simulator,name=Any iOS Simulator Device\" -configuration MinSizeRel ARCHS='arm64'",
	"iphonesimulator-x86_64" : "${commonBuildPrefix} -sdk iphonesimulator -destination \"platform=iOS Simulator,name=Any iOS Simulator Device\" -configuration MinSizeRel ARCHS='x86_64'"
]

return {
	echo "Entering ${name}"
	sh 'security unlock-keychain ${KEYCHAIN_CREDENTIALS} ${HOME}/Library/Keychains/login.keychain-db'
	osNameBuildCmdStemMap.each{entry -> sh "rm -rf ${entry.key}; rm -rf AusweisApp2SDKWrapper/build/${entry.key}" }
	osNameBuildCmdStemMap.each{osName, buildCmdStem -> sh "${buildCmdStem} -derivedDataPath build/${osName} -clonedSourcePackagesDirPath ../${osName} -archivePath build/AusweisApp2SDKWrapper-${osName}.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES" }
}