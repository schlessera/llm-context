#!/bin/sh

# Check if html2md is installed.
if ! command -v html2md >/dev/null 2>&1; then
    echo "Error: html2md is not installed. Trying to install it now..."
    # Detect platform and distribution.
    if [ "$(uname)" = "Darwin" ]; then
        brew install html2md
    elif [ "$(uname)" = "Linux" ]; then
        # Check if apt is present.
        if command -v apt >/dev/null 2>&1; then
            curl -1sLf 'https://dl.cloudsmith.io/public/suntong/repo/setup.deb.sh' | sudo -E bash
            sudo apt update
            apt-cache policy html2md
            sudo apt install -y html2md
        else
            echo "Error: Unsupported distribution. Please install html2md manually."
            exit 1
        fi
    else
        echo "Error: Unsupported platform. Please install html2md manually."
        exit 1
    fi
fi

# Test if html2md is working.
if ! html2md --help >/dev/null 2>&1; then
    echo "Error: html2md is not working. Please check your installation."
    exit 1
fi

# Check if shellcheck is installed.
if ! command -v shellcheck >/dev/null 2>&1; then
    echo "Error: shellcheck is not installed. Trying to install it now..."
    # Detect platform and distribution.
    if [ "$(uname)" = "Darwin" ]; then
        brew install shellcheck
    elif [ "$(uname)" = "Linux" ]; then
        # Check if apt is present.
        if command -v apt >/dev/null 2>&1; then
            sudo apt install -y shellcheck
        else
            echo "Error: Unsupported distribution. Please install shellcheck manually."
            exit 1
        fi
    else
        echo "Error: Unsupported platform. Please install shellcheck manually."
        exit 1
    fi
fi

# Test if shellcheck is working.
if ! shellcheck --version >/dev/null 2>&1; then
    echo "Error: shellcheck is not working. Please check your installation."
    exit 1
fi

echo "✅ All dependencies are available."
