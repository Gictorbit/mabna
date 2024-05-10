#!/usr/bin/env just --justfile
# list of available commands
default:
  @just --list

regFile := "./registries"
tagCommit := `git rev-list --abbrev-commit --tags --max-count=1`
lastVersion := `git describe --tags --abbrev=0 2>/dev/null || git symbolic-ref -q --short HEAD`
lastBranchName := `git describe --tags --exact-match HEAD 2>/dev/null || git symbolic-ref -q --short HEAD`
serviceName := "finance"

# clean build directory
clean:
    @echo "clean bin directory..."
    @[ -d "./bin" ] && rm -r ./bin && echo "bin directory cleaned" || true

# clean and build project
build: clean
    go build -o ./bin/service -ldflags="-s -w" -ldflags="-X 'main.Version={{lastVersion}}' -X 'main.BuildDate=$(date -u '+%Y-%m-%d %H:%M:%S')'" ./cmd

# build and compress binary
upx: build
    upx --best --lzma bin/service

# run go tests
test:
    #!/usr/bin/env bash
    if which gotestsum &> /dev/null; then
        gotestsum --hide-summary="skipped" --junitfile "testout/results.xml" --format "standard-verbose" -- -coverprofile="testout/coverage.out" -race -parallel 1 ./...
        go tool cover -func="testout/coverage.out"
    else
        echo "gotestsum not found!"
        echo "check: https://github.com/gotestyourself/gotestsum#install"
    fi

# run golang linter
linter:
    #!/usr/bin/env bash
    if which golangci-lint &> /dev/null; then
        golangci-lint run --deadline=20m --concurrency 1
    else
        echo "linter not found!"
        echo "check: https://golangci-lint.run/usage/install"
    fi

# run golang linter and fix it
linter-fix:
    #!/usr/bin/env bash
    if which golangci-lint &> /dev/null; then
        golangci-lint run --deadline=20m --concurrency 1 --fix
    else
        echo "linter not found!"
        echo "check: https://golangci-lint.run/usage/install"
    fi

# build service docker image
buildimg tag="latest" cache="enable":
    #!/usr/bin/env bash
    imgtag="{{tag}}"
    if [[ "$imgtag" == "latest" ]];then
        imgtag="{{lastVersion}}"
    fi
    echo "build service docker image..."
    if [ -f "{{regFile}}" ]; then
        mapfile -t registries < "{{regFile}}"
        for registry in "${registries[@]}"; do
            if [[ "{{cache}}" == "enable" ]];then
                docker buildx build -t "$registry/api/{{serviceName}}:$imgtag" -t "$registry/api/{{serviceName}}:latest" -f Dockerfile --build-arg GITHUB_TOKEN="$GITHUB_TOKEN" .
            else
                docker buildx build -t "$registry/api/{{serviceName}}:$imgtag" -t "$registry/api/{{serviceName}}:latest" -f Dockerfile --build-arg GITHUB_TOKEN="$GITHUB_TOKEN"  --no-cache .
            fi
        done
    else
        echo "Error: registries file {{regFile}} not found."
        exit 1
    fi

#build migration docker image
migrateimg tag="latest":
    #!/usr/bin/env bash
    imgtag="{{tag}}"
    if [[ "$imgtag" == "latest" ]];then
        imgtag="{{lastBranchName}}"
    fi
    echo "build migration docker image..."
    if [ -f "{{regFile}}" ]; then
        mapfile -t registries < "{{regFile}}"
        for registry in "${registries[@]}"; do
            docker buildx build -t "$registry/db/{{serviceName}}:$imgtag" -t "$registry/db/{{serviceName}}:latest" -f migration.Dockerfile .
        done
    else
        echo "Error: registries file {{regFile}} not found."
        exit 1
    fi


# build service docker image from built binary
buildimg-bin: upx
    #!/usr/bin/env bash
    echo "build service docker image from binary..."
    if [ -f "{{regFile}}" ]; then
        mapfile -t registries < "{{regFile}}"
        for registry in "${registries[@]}"; do
           docker buildx build -t "$registry/api/{{serviceName}}:{{lastVersion}}" -t "$registry/api/{{serviceName}}:latest" -f binservice.Dockerfile .
        done
    else
        echo "Error: registries file {{regFile}} not found."
        exit 1
    fi

# publish builds and pushes docker image to registry
publishimg tag="latest":
    just buildimg "{{tag}}"
    just migrateimg "{{tag}}"
    just pushimg "{{tag}}"

# push docker image to registry with tag
pushimg:
    #!/usr/bin/env bash
    echo "push docker images..."
    if [ -f "{{regFile}}" ]; then
        mapfile -t registries < "{{regFile}}"
        for registry in "${registries[@]}"; do
            docker login "$registry"
            docker push "$registry/api/{{serviceName}}:latest"
            docker push "$registry/api/{{serviceName}}:{{lastVersion}}"
        done
    else
        echo "Error: registries file {{regFile}} not found."
        exit 1
    fi

# release using goreleaser
gorelease local="false":
    #!/usr/bin/env bash
    echo "run go releaser..."
    if which goreleaser&> /dev/null; then
        if [[ "{{ local }}" == "true" ]];then
            goreleaser release --snapshot --clean
        else
            goreleaser release --clean
        fi
    else
        echo "goreleaser not found!"
        echo "check: https://goreleaser.com/install"
    fi

# generate changelog file
gen-changelog:
    #!/usr/bin/env bash
    if which git-chglog &> /dev/null; then
        if [ -d ".chglog" ]; then
            git-chglog -o "CHANGELOG.md"
        else
            git-chglog --init
            just gen-changelog
        fi
    else
        echo "git-changelog not found!"
        echo "check: https://github.com/git-chglog/git-chglog#installation"
    fi

# release target=major/minor/patch
release target="patch" gorelease="false" publishimg="false":
    #!/usr/bin/env bash
    [[ "{{target}}" =~ "^(major|minor|patch)$" ]] || (echo "invalid target: {{target}}" && echo "target should be major/minor/patch")
    is_version() {
         local pattern="^v[0-9]+\.[0-9]+\.[0-9]+$"
         [[ $1 =~ $pattern ]]
    }
    new_version="v1.0.0"
    if is_version "{{lastVersion}}"; then
        major=$(echo "{{lastVersion}}" | cut -d '.' -f 1 | sed 's/v//')
        minor=$(echo "{{lastVersion}}" | cut -d '.' -f 2)
        patch=$(echo "{{lastVersion}}" | cut -d '.' -f 3)
        case "{{target}}" in
            "major")
                new_major=$((major + 1))
                new_version="v$new_major.0.0"
                ;;
            "minor")
                new_minor=$((minor + 1))
                new_version="v$major.$new_minor.0"
                ;;
            "patch")
                new_patch=$((patch + 1))
                new_version="v$major.$minor.$new_patch"
                ;;
            *)
                ;;
        esac
    fi
    echo "release version: $new_version"
    if which git-chglog &> /dev/null; then
        git-chglog -o CHANGELOG.md --next-tag "$new_version"
    else
        echo "git-changelog not found!"
        echo "check: https://github.com/git-chglog/git-chglog#installation"
        exit 1
    fi
    git add -A && git commit -m "release $new_version"
    git tag -a "$new_version" -m "release $new_version"
    git push --follow-tags

    if [[ "{{ gorelease }}" == "true" ]];then
        just gorelease
    fi
    if [[ "{{ publishimg }}" == "true" ]];then
        just publishimg
    fi

# removes last tag from local and remote
rm-last-tag:
    #!/usr/bin/env bash
    is_version() {
      local pattern="^v[0-9]+\.[0-9]+\.[0-9]+$"
      [[ $1 =~ $pattern ]]
    }
    if is_version "{{lastVersion}}"; then
        echo "remove latest tag on local..."
        git tag -d "{{lastVersion}}"
        echo "remove latest tag on remote..."
        git push --delete origin "{{lastVersion}}" || echo "tag not exists on remote"
    fi


# prints list of all tags
list-tags:
    git tag -l --sort=v:refname

# prints list of all registries
registries:
    #!/usr/bin/env bash
    if [ -f "{{regFile}}" ]; then
        mapfile -t registries < "{{regFile}}"
        for registry in "${registries[@]}"; do
            echo "$registry"
        done
    else
        echo "Error: registries file {{regFile}} not found."
        exit 1
    fi

# installs required tools
install-tools:
    #!/usr/bin/env bash
    if which go &> /dev/null; then
        echo "install goreleaser..."
        go install github.com/goreleaser/goreleaser@latest

        echo "install git-changelog..."
        go install github.com/git-chglog/git-chglog/cmd/git-chglog@latest

        echo "install go testsum..."
        go install gotest.tools/gotestsum@latest

        echo "install golangci-lint"
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

        echo "install swagui..."
        go install github.com/swaggo/swag/cmd/swag@latest
    fi
