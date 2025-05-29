#!/bin/bash

# Build script for DOOM 404 page
# Based on Guillermo Rauch's doom-captcha engine

set -e

DOOM_DIR="./doom-build"
ASSETS_DIR="./docs/assets/doom404"

echo "Building DOOM engine for 404 page..."

# Clean up previous builds if starting fresh
if [ ! -d "$DOOM_DIR/doom-captcha" ]; then
    rm -rf "$DOOM_DIR"
    mkdir -p "$DOOM_DIR"
    
    # Clone the doom-captcha repository
    echo "Cloning doom-captcha repository..."
    git clone https://github.com/rauchg/doom-captcha.git "$DOOM_DIR/doom-captcha"
    
    # Download the shareware WAD file
    echo "Downloading DOOM shareware WAD..."
    curl -L -o "$DOOM_DIR/doom-captcha/sdldoom-1.10/doom1.wad" "https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad"
fi

mkdir -p "$ASSETS_DIR"

# Navigate to the correct engine directory
cd "$DOOM_DIR/doom-captcha/sdldoom-1.10"

# Check if Emscripten is available
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten not found. Please install Emscripten SDK first:"
    echo "https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

echo "Found Emscripten: $(emcc --version | head -n1)"

# Create a custom callback integration file
cat > callback_integration.c << 'EOF'
#include <emscripten.h>
#include <stdio.h>

// Function to be called when an enemy is killed
EMSCRIPTEN_KEEPALIVE
void notify_enemy_killed() {
    // Call JavaScript callback
    EM_ASM({
        if (typeof Module !== 'undefined' && typeof Module.onEnemyKilled === 'function') {
            console.log('Enemy killed!');
            Module.onEnemyKilled();
        } else {
            console.log('No onEnemyKilled callback found');
        }
    });
}

// Function to call when player spawns (optional)
EMSCRIPTEN_KEEPALIVE
void notify_player_spawn() {
    EM_ASM({
        if (typeof Module !== 'undefined' && typeof Module.onPlayerSpawn === 'function') {
            Module.onPlayerSpawn();
        }
    });
}
EOF

# Configure and build with Emscripten
echo "Configuring build with Emscripten..."
export EMCC_CFLAGS="-std=gnu89 -sUSE_SDL"
emconfigure ./configure

# Patch the video initialization to remove SDL_HWPALETTE flag
echo "Patching i_video.c to fix SDL surface locking issues..."
sed -i.bak 's/SDL_HWPALETTE/0/g' i_video.c
sed -i.bak 's/SDL_HWSURFACE/SDL_SWSURFACE/g' i_video.c

echo "Building DOOM engine..."
emmake make

echo "Creating WebAssembly bundle..."
emcc -o index.html ./*.o callback_integration.c --preload-file doom1.wad \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s INITIAL_MEMORY=134217728 \
    -s EXPORTED_FUNCTIONS='["_main", "_notify_enemy_killed", "_notify_player_spawn"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
    -s MODULARIZE=0 \
    -s EXPORT_NAME="Module" \
    -s USE_SDL=1 \
    -s LEGACY_GL_EMULATION=1 \
    -s TOTAL_STACK=32MB \
    -O2 \
    --shell-file ../shell.html

# Verify that the files were created
if [[ ! -f "index.js" || ! -f "index.wasm" || ! -f "index.data" ]]; then
    echo "Error: Build failed - missing output files"
    echo "Available files:"
    ls -la index.*
    exit 1
fi

# Copy the generated files to our assets directory
echo "Copying files to assets directory..."
cp index.js "../../../$ASSETS_DIR/"
cp index.wasm "../../../$ASSETS_DIR/"
cp index.data "../../../$ASSETS_DIR/"

# Return to project root
cd ../../..

echo "✅ DOOM engine built successfully!"
echo "Files generated in $ASSETS_DIR:"
ls -la "$ASSETS_DIR"

# Show file sizes
echo ""
echo "File sizes:"
echo "JavaScript: $(du -h "$ASSETS_DIR/index.js" | cut -f1)"
echo "WebAssembly: $(du -h "$ASSETS_DIR/index.wasm" | cut -f1)" 
echo "Game data: $(du -h "$ASSETS_DIR/index.data" | cut -f1)"

echo ""
echo "Next steps:"
echo "1. Test locally with: mkdocs serve"
echo "2. Navigate to a non-existent page (e.g., /test-404)"
echo "3. Kill 3 demons to test the redirect functionality"
echo "4. Commit and push to deploy to GitHub Pages" 