# mabna
this is mabna code challenge

## available commands

we use `justfile` as command runner here is available commands:
```sh
Available recipes:
    build                   # clean and build project
    buildimg tag="latest" cache="enable" # build service docker image
    buildimg-bin            # build service docker image from built binary
    clean                   # clean build directory
    default                 # list of available commands
    gen-changelog           # generate changelog file
    gorelease local="false" # release using goreleaser
    install-tools           # installs required tools
    linter                  # run golang linter
    linter-fix              # run golang linter and fix it
    list-tags               # prints list of all tags
    migrateimg tag="latest" # build migration docker image
    publishimg tag="latest" # publish builds and pushes docker image to registry
    pushimg                 # push docker image to registry with tag
    registries              # prints list of all registries
    release target="patch" gorelease="false" publishimg="false" # release target=major/minor/patch
    rm-last-tag             # removes last tag from local and remote
    test                    # run go tests
    upx                     # build and compress binary

```