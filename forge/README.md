## clone original ffmpeg release versions to forge patches
```bash
git clone -b release/5.1 https://github.com/FFmpeg/FFmpeg.git FFmpeg_51
git clone -b release/6.0 https://github.com/FFmpeg/FFmpeg.git FFmpeg_60
git clone -b release/6.1 https://github.com/FFmpeg/FFmpeg.git FFmpeg_61
git clone -b release/7.0 https://github.com/FFmpeg/FFmpeg.git FFmpeg_70
git clone -b release/7.1 https://github.com/FFmpeg/FFmpeg.git FFmpeg_71
```

## re-apply previous patches
```bash
cd FFmpeg_51
patch -p1 < ../../patches/ffmpeg_arcana_patch_5.1.patch
cd ../FFmpeg_60
patch -p1 < ../../patches/ffmpeg_arcana_patch_6.0.patch
cd ../FFmpeg_61
patch -p1 < ../../patches/ffmpeg_arcana_patch_6.1.patch
cd ../FFmpeg_70
patch -p1 < ../../patches/ffmpeg_arcana_patch_7.0.patch
cd ../FFmpeg_71
patch -p1 < ../../patches/ffmpeg_arcana_patch_7.1.patch
```

## copy current toml-c.h into the avutil of each
```bash
cp toml-c.h FFmpeg_51/libavutil
cp toml-c.h FFmpeg_60/libavutil
cp toml-c.h FFmpeg_61/libavutil
cp toml-c.h FFmpeg_70/libavutil
cp toml-c.h FFmpeg_71/libavutil
```

## apply patch
```bash
# dry run
cd FFMpeg_51
patch --dry-run -p1 < ../../patches/ffmpeg_arcana_patch_5.1.patch

# do patch
patch -p1 < ../../patches/ffmpeg_arcana_patch_5.1.patch
```

## if patch fails
When forward patching a previous patch to a new version of ffmpeg, you can force the patch with '-f' then fix required changes
```bash
patch -f -p1 < ../../patches/ffmpeg_arcana_patch_5.1.patch
```

## to create patch from modified files
```bash
# make patch and place in ../patches
export ARCANA_PATCH_VERSION=5.1
cd FFmpeg_Arcana${ARCANA_PATCH_VERSION}
echo $(date) `uuidgen` > Arcana_Patch_Date.md
git diff > ffmpeg_arcana_patch_${ARCANA_PATCH_VERSION}.patch
mv *.patch ../../patches
```

## get current toml-c.h header for plugin loader configuration
```bash
cd libavutil
curl https://raw.githubusercontent.com/arp242/toml-c/refs/heads/master/header/toml-c.h > toml-c.h
# toml-c.h requires minor mods to build with macos.
```

## create patch while specifying modified files and select untracked files
```bash
export ARCANA_PATCH_VERSION=5.1
export ARCANA_FOLDER=51
cd FFmpeg_$ARCANA_FOLDER
cd FFmpeg_Arcana${ARCANA_PATCH_VERSION}
echo $(date) `uuidgen` > Arcana_Patch_Date.md
# stage modified files
git add -u
# stage untracked files
git add Arcana_Patch_Date.md libavutil/toml-c.h
# create patch
git diff --cached > ffmpeg_arcana_patch_${ARCANA_PATCH_VERSION}.patch
mv *.patch ../../patches
# Remove all changes from the staging area
git restore --staged .
cd ..
```