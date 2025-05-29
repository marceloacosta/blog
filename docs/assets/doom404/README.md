# DOOM 404 Page

This directory contains the WebAssembly build of DOOM Shareware that powers the custom 404 page for this blog.

## Overview

When visitors navigate to a non-existent page, they're presented with a playable DOOM level. After killing 3 enemies, they're automatically redirected to the blog homepage.

## Files

- `index.js` - Emscripten-generated JavaScript wrapper
- `index.wasm` - WebAssembly binary containing the DOOM engine
- `index.data` - Game assets including the shareware doom1.wad

## Functionality

### Game Settings
- **Difficulty**: Skill level 2 (Hurt Me Plenty)
- **Level**: E1M1 (Hangar)
- **Auto-respawn**: Enabled to maintain 3-kill objective
- **Sound/Music**: Disabled for faster loading

### Redirect Logic
- Counter tracks enemy kills via `onEnemyKilled` callback
- Redirects to `/` after exactly 3 kills
- Timeout fallback: redirects after 120 seconds if no kills
- Graceful degradation for browsers without WebAssembly support

## Building from Source

### Prerequisites

1. **Emscripten SDK**: Install from [emscripten.org](https://emscripten.org/docs/getting_started/downloads.html)
   ```bash
   git clone https://github.com/emscripten-core/emsdk.git
   cd emsdk
   ./emsdk install latest
   ./emsdk activate latest
   source ./emsdk_env.sh
   ```

2. **Verify installation**:
   ```bash
   emcc --version
   ```

### Build Process

From the project root, run:

```bash
./build_doom.sh
```

This script will:
1. Clone the [doom-captcha repository](https://github.com/rauchg/doom-captcha)
2. Navigate to the engine subdirectory
3. Compile DOOM with Emscripten using custom flags
4. Copy the generated files (`index.js`, `index.wasm`, `index.data`) to this directory
5. Clean up temporary build files

### Manual Build (Alternative)

If the script fails, you can build manually:

```bash
# Clone the source
git clone https://github.com/rauchg/doom-captcha.git
cd doom-captcha/engine

# Compile with Emscripten
emcc -O2 \
  -s USE_SDL=1 \
  -s LEGACY_GL_EMULATION=1 \
  -s GL_UNSAFE_OPTS=0 \
  -s ASSERTIONS=0 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s EXPORTED_FUNCTIONS='["_main"]' \
  -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
  -s MODULARIZE=0 \
  -s EXPORT_NAME="Module" \
  --preload-file doom1.wad \
  --shell-file minimal.html \
  -DFEATURE_SOUND=0 \
  -DFEATURE_MUSIC=0 \
  -DHAVE_LIBPNG=0 \
  -DHAVE_LIBJPEG=0 \
  src/*.c \
  -o index.js

# Copy files to assets directory
cp index.js ../../docs/assets/doom404/
cp index.wasm ../../docs/assets/doom404/
cp index.data ../../docs/assets/doom404/
```

## Customization

### Modifying Game Parameters

To change game settings, edit the compilation flags in `build_doom.sh`:

- **Skill level**: Modify `-skill` parameter in the source
- **Starting level**: Change the level parameter
- **Enable sound**: Remove `-DFEATURE_SOUND=0`
- **Enable music**: Remove `-DFEATURE_MUSIC=0`

### Adjusting Kill Count

To change the number of required kills, modify the redirect logic in `/overrides/404.html`:

```javascript
if (killCount >= 3) {  // Change this number
    redirected = true;
    // ...
}
```

### Timeout Duration

To adjust the 120-second timeout, modify this line in the 404 template:

```javascript
setTimeout(() => {
    // ...
}, 120000);  // Change this value (in milliseconds)
```

## Testing

### Local Testing

1. Build the site: `mkdocs serve`
2. Navigate to a non-existent page: `http://localhost:8000/test-404`
3. Play the game and verify redirect after 3 kills

### Deployment Testing

1. Deploy to GitHub Pages
2. Test on your live domain with a non-existent URL
3. Verify WebAssembly files load correctly (check browser dev tools)

## Troubleshooting

### Common Issues

**"WebAssembly not supported" error**:
- The browser doesn't support WebAssembly
- The fallback 404 message should display automatically

**Assets fail to load (404 errors)**:
- Check that files exist in `/assets/doom404/`
- Verify GitHub Pages is serving WASM files with correct MIME type
- Check browser console for specific error messages

**Game loads but kills don't count**:
- Verify the `onEnemyKilled` callback is properly exposed
- Check browser console for JavaScript errors
- Ensure the kill counter logic is working

**Build fails**:
- Verify Emscripten is properly installed and in PATH
- Check that all source files are present in the doom-captcha repo
- Review compilation flags for compatibility

### Browser Support

- **Chrome**: Full support
- **Firefox**: Full support  
- **Safari**: Full support (macOS/iOS)
- **Edge**: Full support
- **Older browsers**: Graceful fallback to standard 404 page

## Legal Notes

This implementation uses the shareware version of DOOM, which is freely redistributable. The original game is © 1993 id Software LLC, a ZeniMax Media company.

The doom-captcha engine is based on work by Guillermo Rauch and contributors, used under its original license terms.

## Architecture

```
404 Request Flow:
┌─ Non-existent URL ─→ GitHub Pages ─→ 404.html
├─ Load WASM assets ─→ /assets/doom404/
├─ Initialize DOOM ─→ Start E1M1 level  
├─ Track kills ─→ JavaScript counter
└─ Redirect after 3 kills ─→ Homepage (/)
```

For questions or issues, please refer to the main blog repository. 