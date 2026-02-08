/*
 * Arcana Test Codec Descriptor
 *
 * Demonstrates registering a custom AVCodecDescriptor with a
 * dynamically generated AVCodecID via arcana_codec_id_generate().
 *
 * Note: The ARCANA_CODEC_ID() macro provides compile-time ID generation
 * for C++ plugins. In C, use arcana_codec_id_generate() at runtime.
 */

#include "test_desc.h"
#include "arcana/libavcodec/codec_desc.h"
#include "arcana/libavutil/avutil.h"

AVCodecDescriptor arcana_test_descriptor = {
    .id        = AV_CODEC_ID_NONE,   /* set at runtime via arcana_codec_id_generate() */
    .type      = AVMEDIA_TYPE_VIDEO,
    .name      = "arcana_test_video",
    .long_name = "Arcana Test Video Codec",
    .props     = AV_CODEC_PROP_INTRA_ONLY | AV_CODEC_PROP_LOSSY,
    .mime_types = NULL,
    .profiles   = NULL,
};
