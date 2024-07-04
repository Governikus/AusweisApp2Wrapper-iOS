def name = 'StageStaticAnalysis'
return {
	echo "Entering ${name}"
	sh 'swiftlint --strict'
}