#!/bin/bash

# Create branches from repos
#
# Intended for creating "shortcut" branches in sample app repo
#   from master branches in separate repos
#
#   e.g. Given source repos:
#        https://github.com/my-org/go-sample-app-scenario-1-finished.git
#        https://github.com/my-org/go-sample-app-scenario-2-finished.git
#   e.g. Creates:
#        https://github.com/springone-tour-2020-cicd/go-sample-app.git --> branch: scenario-1-finished
#        https://github.com/springone-tour-2020-cicd/go-sample-app.git --> branch: scenario-2-finished
#
# Hard-coded to work for:
#        https://github.com/springone-tour-2020-cicd/go-sample-app.git (scenarios 1-5)
#        https://github.com/springone-tour-2020-cicd/go-sample-app-ops.git (scenario 5)

SOURCE_ORG=${1:-andreasevers}
DEST_ORG=springone-tour-2020-cicd

function create_branch() {
  rm -rf $REPO-scenario-$NUM-finished
  git clone https://github.com/$SOURCE_ORG/$REPO-scenario-$NUM-finished.git

  cd $REPO-scenario-$NUM-finished

  find . -type f -name "*.yaml" -print0 | xargs -0 sed -i '' -e "s/\/$SOURCE_ORG/\/$DEST_ORG/g"
  find . -type f -name "*.yaml" -print0 | xargs -0 sed -i '' -e "s/ $SOURCE_ORG/ $DEST_ORG/g"

  git add -A
  git commit -m "Reset to scenario-$NUM-finished"
  git remote add dest https://github.com/$DEST_ORG/$REPO.git
  if [ $(git ls-remote --heads https://github.com/$DEST_ORG/$REPO.git scenario-$NUM-finished | wc -l) = 1 ]; then
    # if branch exists, delete it before re-creating it
    git push dest :scenario-$NUM-finished
  fi
  git push -u dest master:scenario-$NUM-finished

  cd ..
}

rm -rf temp/git_create_branches_workdir
mkdir -p temp/git_create_branches_workdir
cd temp/git_create_branches_workdir

# Move app repos to branches
REPO=go-sample-app
for NUM in $(seq 1 5); do
  create_branch
done

# Move app-ops repo to branch
REPO=go-sample-app-ops
NUM=5
create_branch

cd ..
#rm -rf temp/git_create_branches_workdir