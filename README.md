# FFmpeg Arcana

FFmpeg Arcana is a build system that produces a plugin-enabled version of FFmpeg. It downloads an official FFmpeg release, applies a patch that adds dynamic plugin loading, and builds the result with all of FFmpeg's private headers exposed for plugin development.

Standard FFmpeg has no plugin architecture — codecs, muxers, demuxers, and protocols must all be compiled into the binary at build time. FFmpeg Arcana changes this by patching FFmpeg to load shared libraries at startup via `dlopen()`, allowing custom codecs, muxers, and protocols to be developed and deployed independently without recompiling FFmpeg itself.

## How It Works

The build system performs these steps:

1. **Downloads** an official FFmpeg release tarball from ffmpeg.org
2. **Patches** the source with Arcana modifications that add plugin loading support
3. **Builds** FFmpeg using its native `./configure` and `make` process, orchestrated by CMake
4. **Extracts private headers** that FFmpeg doesn't normally install, placing them under `include/arcana/libavprivate/` so plugins can access internal APIs like `codec_internal.h`
5. **Adjusts pkg-config** files to reference the private headers, making plugin compilation straightforward

The patched FFmpeg reads a TOML configuration file (pointed to by the `ARCANA_CONF` environment variable) at startup. Each entry in the config specifies a shared library to load and an optional configuration string to pass to it. The loaded plugin's `arcana_register()` function is called, which registers its codecs, muxers, or protocols with FFmpeg's internal registries.

## Supported FFmpeg Versions

Patches are provided for FFmpeg 5.1, 6.0, 6.1, 7.0, 7.1, and 8.0.

## Plugin Configuration

Plugins are loaded via a TOML configuration file:

```toml
[[plugins]]
path = "/path/to/my_plugin.so"
config = "optional_config_string"

[[plugins]]
path = "/path/to/another_plugin.so"
```

Set the `ARCANA_CONF` environment variable to point to this file before running the patched FFmpeg binary.

## Building FFmpeg Arcana

### Requirements

- CMake 3.10+
- C compiler
- `patch` utility
- Any FFmpeg dependencies you want to enable (e.g., libx264, libx265)

### Build

```bash
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=$HOME/arcana_install \
  -DARCANA_PATCH_VERSION=7.1 \
  -DFFMPEG_VERSION=7.1 \
  -DFFOPT_enable-gpl=true \
  -DFFOPT_enable-nonfree=true \
  ..
make && make install
```

### Run

```bash
LD_LIBRARY_PATH=$HOME/arcana_install/lib $HOME/arcana_install/bin/ffmpeg_arcana
```

To load plugins at startup:

```bash
export ARCANA_CONF=/path/to/plugins.toml
LD_LIBRARY_PATH=$HOME/arcana_install/lib $HOME/arcana_install/bin/ffmpeg_arcana -i input.mp4 output.mkv
```

## CMake Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `FFMPEG_VERSION` | `6.0` | FFmpeg release version to download and build |
| `ARCANA_PATCH_VERSION` | `6.0` | Which Arcana patch to apply (must match a file in `patches/`) |
| `CMAKE_INSTALL_PREFIX` | — | Final installation directory |
| `ARCANA_SUFFIX` | `_arcana` | Suffix appended to binaries and libraries |
| `ARCANA_STAGING_DIRECTORY` | `${CMAKE_BINARY_DIR}/staging` | Intermediate build output directory |
| `FFMPEG_PKG_CONFIG_PATH` | `$PKG_CONFIG_PATH` | pkg-config search path for FFmpeg dependencies |
| `FFMPEG_CONFIGURE_EXTRAS` | — | Additional arguments passed to FFmpeg's `./configure` |
| `ADDITIONAL_PATCHES` | — | Directory containing extra `.patch` files to apply after the Arcana patch |
| `NO_ARCANA_SUFFIX` | — | If set, omit the `_arcana` suffix from binaries and libraries |
| `INSTALL_FFMPEG_SHARED` | — | If set, also install FFmpeg's `share/` directory |

### FFmpeg Feature Flags (FFOPT_)

Any CMake variable prefixed with `FFOPT_` is converted to an FFmpeg `./configure` flag. Underscores in the variable name become hyphens in the flag:

```bash
-DFFOPT_enable-gpl=true          # → --enable-gpl
-DFFOPT_enable-libx264=true      # → --enable-libx264
-DFFOPT_disable-doc=true         # → --disable-doc
-DFFOPT_extra-cflags="-I/opt/include"  # → --extra-cflags=-I/opt/include
```

Boolean `true` values include the flag; `false` values omit it. Non-boolean values are passed as `--flag=value`.

## Writing Plugins

A plugin is a shared library that exports an `arcana_register()` function. This function is called at FFmpeg startup with an optional configuration string from the TOML file.

```c
#include "libavcodec/codec_internal.h"
#include "libavformat/mux.h"

void arcana_register(char *conf_string)
{
    arcana_register_codec((void *)&my_custom_encoder);
    arcana_register_muxer((void *)&my_custom_muxer);
}
```

Plugins can register codecs, muxers, and protocols using `arcana_register_codec()`, `arcana_register_muxer()`, and `arcana_register_protocol()` respectively.

The build system exposes FFmpeg's private headers under `include/arcana/libavprivate/`, and the installed pkg-config files include them automatically. See `test_plugins/` for complete working examples.

### Building the Test Plugins

```bash
mkdir test_plugins/build
cd test_plugins/build
cmake -DARCANA_PREFIX=$HOME/arcana_install ..
make && make install
```

## Project Structure

```
CMakeLists.txt              Root build configuration
ffmpeg_arcana/              FFmpeg build orchestration
  cmake_include/            CMake modules for each build phase
patches/                    Version-specific Arcana patches
forge/                      Tools for creating and maintaining patches
test_plugins/               Example plugins (encoder, muxer, protocol)
```

## License

MIT
