# bash_scripts
A small collection of bash scripts. To use them, make sure to add this directory to your PATH.

## git-remove-merged

This will compare all of your local branches to make sure that the commits (by commit-sha) have been merged into develop. It only deletes local branches.

If the directory has been added to your path, executable by running `git remove-merged`

Usage notes:
* Branches that end in any of the following are protected from being deleted:
  * main
  * master
  * develop
* the script uses `git branch -d` for the local deletion, which also checks to see if the branch being deleted is fully incorporated in the *current* branch before deleting. It works best if you're executing while in the develop branch.
* If you have merged into develop via squash commit or a rebase, you've changed history, so the commit sha from the branch is different from what's in the develop, and therefore that branch won't be deleted by the script

## github-new-repo

### Requirements
This requires you to have generated a personal access token, and have it saved as an environment variable called GITHUB_ACCESS_TOKEN

### Usage Example
`github-new-repo MyNewRepoName`
