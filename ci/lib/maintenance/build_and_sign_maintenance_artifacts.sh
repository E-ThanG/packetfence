#!/bin/bash
set -o nounset -o pipefail -o errexit

die() {
    echo "$(basename $0): $@" >&2 ; exit 1
}

log_section() {
   printf '=%.0s' {1..72} ; printf "\n"
   printf "=\t%s\n" "" "$@" ""
}

log_subsection() {
   printf "=\t%s\n" "" "$@" ""
}


configure_and_check() {
    log_section "Configure and check..."
    # Define RESULT_DIR if in CI
    if [ ! -z "$CI_PROJECT_DIR" ]
    then
    	RESULT_DIR="$CI_PROJECT_DIR/result"
    fi
    RESULT_DIR=${RESULT_DIR:-result}

    # RELEASE_ID is for example : debian ubuntu mint
    # RELEASE_NAME is for example : jessie xenial
    RELEASE=$(ci-release)
    RELEASE_ID=$(cut -d/ -f1 <<< $RELEASE)
    RELEASE_NAME=$(cut -d/ -f2 <<< $RELEASE)
    RELEASE_DIR=$RESULT_DIR/$RELEASE_ID/$RELEASE_NAME
    # CI_COMMIT_REF_NAME = branch name = maintenance/X.Y
    # we drop "maintenance/" prefix
    MAINT_DIR=${RELEASE_DIR}/${CI_COMMIT_REF_NAME#maintenance/}

    declare -p RELEASE RELEASE_ID RELEASE_NAME RESULT_DIR RELEASE_DIR MAINT_DIR

    [ -z "$RELEASE_ID" ] && die "not set: RELEASE_ID"
    [ -z "$RELEASE_NAME" ] && die "not set: RELEASE_NAME"
    [ -z "$RESULT_DIR" ] && die "not set: RESULT_DIR"
    [ -z "$MAINT_DIR" ] && die "not set: MAINT_DIR"
    
    mkdir -vp ${MAINT_DIR} || die "mkdir failed: $MAINT_DIR"
}

configure_gpg() {
    log_section "Configure GPG.."
    GPG_KEY_ID=${GPG_KEY_ID:-${GPG_USER_ID}}
}

build_old_golang_binaries() {
    log_section "Build old Golang binaries..."    
    ./addons/packages/build-go.sh build ${PWD} ${MAINT_DIR}
}

# build old artifacts for each distribution
build_old_artifacts() {
    configure_and_check
    build_old_golang_binaries
    tree $RELEASE_DIR
}

# sign artifacts for all distributions using artifacts
# of previous build jobs
sign_artifacts() {
    if [ ! -z "$CI_PROJECT_DIR" ]; then
        RESULT_DIR="$CI_PROJECT_DIR/result"
    fi
    RESULT_DIR=${RESULT_DIR:-result}
    configure_gpg
    log_section "Display artifacts.."
    tree $RESULT_DIR
    log_section "Sign all artifacts.."
    find $RESULT_DIR -type f -not -name "*.sig" -exec \
         gpg -v -u $GPG_KEY_ID --batch --yes --output {}.sig --sign {} \;
    tree $RESULT_DIR
}

case $1 in
    build_old) build_old_artifacts ;;
    sign) sign_artifacts ;;
    *)   die "Wrong argument"
esac