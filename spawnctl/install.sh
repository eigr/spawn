#!/bin/sh

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    arm64) ARCH="m1" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Determine the correct binary name
case "$OS" in
    "linux")
        case "$ARCH" in
            "x86_64")
                FILENAME="spawnctl_linux"
                ;;
            "aarch64")
                FILENAME="spawnctl_linux_aarch64"
                ;;
            *)
                echo "Unsupported architecture: $ARCH"; exit 1
                ;;
        esac
        ;;
    "darwin")
        case "$ARCH" in
            "x86_64")
                FILENAME="spawnctl_macos"
                ;;
            "m1")
                FILENAME="spawnctl_macos_m1"
                ;;
            *)
                echo "Unsupported architecture: $ARCH"; exit 1
                ;;
        esac
        ;;
    "windows_nt")
        FILENAME="spawnctl_windows.exe"
        ;;
    *)
        echo "Unsupported OS: $OS"; exit 1
        ;;
esac


# Check if spawn is already installed and run maintenance uninstall
if command -v spawn &> /dev/null; then
    echo "Previous version of Spawn CLI detected. Running 'spawn maintenance uninstall' to remove cached files."
    yes | spawn maintenance uninstall
fi

# Download the binary
URL="https://github.com/eigr/spawn/releases/download/v2.0.0-RC1/$FILENAME"
curl -LO "$URL"

# Determine installation directory
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ]; then
    echo "No write access to $INSTALL_DIR. Installing to ~/bin instead."
    INSTALL_DIR="$HOME/.spawn/bin"
    mkdir -p "$INSTALL_DIR"
    # Ensure ~/.spawn/bin is in PATH
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.bashrc
        echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.zshrc
        source ~/.bashrc
        source ~/.zshrc
    fi
fi

# Move the binary to the installation directory
mv "$FILENAME" "$INSTALL_DIR/spawn"
chmod +x "$INSTALL_DIR/spawn"

echo "Spawn CLI installed successfully in $INSTALL_DIR"

# Instruct the user on how to use the CLI
echo "To start using Spawn CLI, open a new terminal or run the following command:"
echo ""
echo "    source ~/.bashrc  # For Bash users"
echo "    source ~/.zshrc   # For Zsh users"
echo ""
echo "Then, you can use the CLI with the command: spawn"
