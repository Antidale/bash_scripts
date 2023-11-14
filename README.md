# bash_scripts
A small collection of bash scripts. To use them, make sure to add this directory to your PATH and add the execute permission for youself on the scrips. For example `chmod u+x git-*` will give only the owner of the file permission to exectute files matching `git-`.

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

## git-new-repo

This script will:

* create a new remote repository in GitHub
* initialize a new git repository in the current directory
* add the remote repository as origin (ssh, not https syntax)
* create develop and main branches
* add a basic README.md
* set develop as the default branch in github
* set develop as the active local branch

### Requirements
This requires following environment variables:
* GITHUB_ACCESS_TOKEN
* GITHUB_USERNAME

You also must pass the new name as an argument to the function.  See below for an example

Visit [here](https://github.com/settings/tokens) to generate an access token.  See [this](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line) for official documentation.

### Usage Example
`git new-repo MyNewRepoName`


## git-fetch-all

This script will iterate through the first level child directories of a directory and use `git fetch -pt --all` to fetch and prune code for all branches, as well as fetching and pruning tags.  Set the chosen directory by using the SOURCE_FOLDER environment variable

### Requirements
This requires following environment variable:
* SOURCE_FOLDER

### Usage Example
git fetch-all
