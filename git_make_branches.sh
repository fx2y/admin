function make_branch() {
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

SOURCE_ORG=${1:-andreasevers}
DEST_ORG=springone-tour-2020-cicd

rm -rf temp
mkdir -p temp
cd temp

# Move app repos to branches
REPO=go-sample-app
for NUM in $(seq 1 5); do
  make_branch
done

# Move app-ops repo to branch
REPO=go-sample-app-ops
NUM=5
make_branch

cd ..
#rm -rf temp