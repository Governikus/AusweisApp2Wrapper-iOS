return {
	sh 'hg --config extensions.strip= strip -r "secret() or draft()" --no-backup --force || exit 0'
	publishReview downloadOnly: true, installRBTools: false
	sh "hg --config patch.eol=auto import --no-commit patch.diff"
}
