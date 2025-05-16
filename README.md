# typical build scenario
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

# test ffmpeg bin
```bash
LD_LIBRARY_PATH=$HOME/arcana_install/lib $HOME/arcana_install/bin/ffmpeg_arcana
```