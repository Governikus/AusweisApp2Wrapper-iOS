def name = 'StageSonar'
return { pIsReviewBuild ->
	echo "Entering ${name}"
	def pullRequestParams = pIsReviewBuild ? '-Dsonar.pullrequest.key=${REVIEWBOARD_REVIEW_ID} -Dsonar.pullrequest.branch=${REVIEWBOARD_REVIEW_ID} -Dsonar.pullrequest.base=${MERCURIAL_REVISION_BRANCH}' : '-Dsonar.branch.name=${MERCURIAL_REVISION_BRANCH}'
	catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
		sh "sonar-scanner -Dsonar.scanner.metadataFilePath=\${WORKSPACE}/tmp/sonar-metadata.txt ${pullRequestParams} -Dsonar.token=\${SONARQUBE_TOKEN} -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=90"
	}
}
