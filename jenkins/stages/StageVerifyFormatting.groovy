def name = 'StageVerifyFormatting'
return {
	echo "Entering ${name}"
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