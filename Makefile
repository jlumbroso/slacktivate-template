
researchers:
	pipenv run python scripts/update_postdocs.py
	echo "Researchers updated!"

updateData: researchers
    pipenv run python scripts/process_data.py
	echo "Data updated!"

validate:
	pipenv run slacktivate validate
	echo "Specification valid!"

slackAdd: validate
	pipenv run slacktivate users activate
	pipenv run slacktivate users synchronize
	pipenv run slacktivate channels ensure
	echo "Slack memberships updated! (except deletions)"

slackRemove: validate
	pipenv run slacktivate users deactivate
	pipenv run slacktivate users synchronize
	pipenv run slacktivate channels ensure
	echo "Slack member deletions completed!"
