def name = 'StageResolveSwiftPkgDependencies'
def derivedDataDir = 'ResolvedDerivedData'
return {
	echo "Entering ${name}"
	sh "rm -rf ${derivedDataDir}; rm -rf AusweisApp2SDKWrapper/build/${derivedDataDir}"
	sh "cd AusweisApp2SDKWrapper; xcodebuild -scheme AusweisApp2SDKWrapper -resolvePackageDependencies -derivedDataPath build/${derivedDataDir} -clonedSourcePackagesDirPath ../${derivedDataDir}"
}