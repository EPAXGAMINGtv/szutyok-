#! /bin/sh

cd "src"

clone_repo_commit() {
    if test -d "$2/.git"; then
        git -C "$2" reset --hard
        git -C "$2" clean -fd
        if ! git -C "$2" checkout $3; then
            rm -rf "$2"
        fi
    else
        if test -d "$2"; then
            set +x
            echo "error: '$2' is not a Git repository"
            exit 1
        fi
    fi
    if ! test -d "$2"; then
        git clone $1 "$2"
        if ! git -C "$2" checkout $3; then
            rm -rf "$2"
            exit 1
        fi
    fi
}

download_by_hash() {
    DOWNLOAD_COMMAND="curl -Lo"
    if ! command -v "${DOWNLOAD_COMMAND%% *}" >/dev/null 2>&1; then
        DOWNLOAD_COMMAND="wget -O"
        if ! command -v "${DOWNLOAD_COMMAND%% *}" >/dev/null 2>&1; then
            set +x
            echo "error: Neither curl nor wget found"
            exit 1
        fi
    fi
    SHA256_COMMAND="sha256sum"
    if ! command -v "${SHA256_COMMAND%% *}" >/dev/null 2>&1; then
        SHA256_COMMAND="sha256"
        if ! command -v "${SHA256_COMMAND%% *}" >/dev/null 2>&1; then
            set +x
            echo "error: Cannot find sha256(sum) command"
            exit 1
        fi
    fi
    if ! test -f "$2" || ! $SHA256_COMMAND "$2" | grep $3 >/dev/null 2>&1; then
        rm -f "$2"
        mkdir -p "$2" && rm -rf "$2"
        $DOWNLOAD_COMMAND "$2" $1
        if ! $SHA256_COMMAND "$2" | grep $3 >/dev/null 2>&1; then
            set +x
            echo "error: Cannot download file '$2' by hash"
            echo "incorrect hash:"
            $SHA256_COMMAND "$2"
            rm -f "$2"
            exit 1
        fi
    fi
}

clone_repo_commit \
    https://codeberg.org/osdev/freestnd-c-hdrs-0bsd.git \
    freestnd-c-hdrs \
    a87c192f3eb66b0806740dc67325f9ad23fc2d0b

clone_repo_commit \
    https://codeberg.org/osdev/cc-runtime.git \
    src/cc-runtime \
    b4d3b970b2f6e7d08360c66eea8314e8dd901490