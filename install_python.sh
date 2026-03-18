#!/bin/bash

# Usage: ./install.sh [MAJOR] [MINOR]
# Example: ./install.sh 3.11 4

MAJOR=${1:-3.10}
MINOR=${2:-18}

echo "=== Installing Python $MAJOR.$MINOR ==="

# Step 1: Install all build dependencies in single apt command
echo "[1/6] Installing dependencies..."
apt update && \ 
apt install -y \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libsqlite3-dev \
    wget \
    libbz2-dev \
    lzma-dev\
    libgdbm-compat-dev \
    liblzma-dev \
    tk-dev \
    uuid-dev \
    libnsl-dev

# Step 2: Download Python source
echo "[2/6] Downloading source..."
FILE="Python-$MAJOR.$MINOR.tgz"
URL="https://www.python.org/ftp/python/$MAJOR.$MINOR/$FILE"

if [ ! -f "$FILE" ]; then
    wget "$URL"
else
    echo "Using existing $FILE"
fi

# Step 3: Extract
echo "[3/6] Extracting..."
tar -xf "$FILE"
cd "Python-$MAJOR.$MINOR/" || exit

# Step 4: Configure and compile
echo "[4/6] Configuring..."
./configure --enable-optimizations

echo "[5/6] Compiling..."
make -j "$(nproc)"

# Step 5: Install
echo "[6/6] Installing..."
make altinstall

# Verify critical modules (ssl, lzma, sqlite3, ctypes)
echo "Verifying modules..."
python$MAJOR -c "import ssl, lzma, sqlite3, ctypes; print('All modules OK')"

# Step 6: Setup aliases
echo "Setting up aliases..."
echo "alias python='python$MAJOR'" >> ~/.bash_aliases
echo "alias pip='python$MAJOR -m pip'" >> ~/.bash_aliases

echo "Done. Run 'source ~/.bashrc' to use 'python' command"
