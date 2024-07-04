def name = 'StagePackageXcframework'
return {
	echo "Entering ${name}"
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