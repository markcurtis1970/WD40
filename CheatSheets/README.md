# Cheat sheets

Any things that might be useful as a cheat sheet

## GitHub

`git rm --cached <file>` - removes the file from your staged list for the next commit

### New branches

Theres probably easier ways but this is what I usually do

```
git checkout -b versionX
git add <files>
git commit -m "Initial changes for versionX"
git push origin versionX
```

### Cloning only a branch

Useful if you like to compare two different branches locally

```
git clone -b Version1 https://github.com/markcurtis1970/WD40.git WD40-Version1
git clone -b Version2 https://github.com/markcurtis1970/WD40.git WD40-Version2

diff -rq WD40-Version1 WD40-Version2
```



