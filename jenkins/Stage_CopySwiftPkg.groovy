return { pSpmSource ->
	copyArtifacts(
		projectName: "${pSpmSource}",
		filter: '**/*.zip',
		target: '.',
		selector: lastSuccessful()
	)
	script {
		sh 'cd AusweisApp2SDKWrapper; find . -type f -name \'Package.swift\' -exec sed -i "" -e "/url:/d" -e "s/\\.exact\\(.*\\)/path: \\"..\\/AA2SwiftPackage\\"/" {} \\;'
		sh 'find . -type f \\( -iname "*.zip" -not -iname "AusweisApp2SDKWrapper*.zip" -not -path "./shared_workspace/*" \\) -exec unzip -o -d AA2SwiftPackage {} \\;'
	}
}
