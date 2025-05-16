#ifndef GENERIC_ENCODER_H
#define GENERIC_ENCODER_H

#ifdef __cplusplus
extern "C" {
#endif

#include "libavutil/common.h"
#include "libavutil/imgutils.h"
#include "libavutil/intreadwrite.h"
#include "libavutil/opt.h"
#include "avcodec.h"
#include "libavprivate/libavcodec/codec_internal.h"
#include "libavprivate/libavcodec/encode.h"

typedef struct LibOpenJPHContext {
    AVClass *avclass;
    void *encoder;
    // opj_cparameters_t enc_params;
    // int format;
    // int profile;
    // int prog_order;
    // int cinema_mode;
    // int numresolution;
    int irreversible;
    // int disto_alloc;
    // int fixed_quality;
} LibOpenJPHContext;

#ifdef __cplusplus
}
#endif

// visible only to c++
#ifdef __cplusplus
#include "ojph_arg.h"
#include "ojph_mem.h"
#include "ojph_img_io.h"
#include "ojph_file.h"
#include "ojph_codestream.h"
#include "ojph_params.h"
#include "ojph_message.h"

#define PROFILE_STRING_NONE         "\0\0\0\0\0\0\0\0\0"
#define PROFILE_STRING_BROADCAST    "BROADCAST"
#define PROFILE_STRING_IMF          "IMF\0\0\0\0\0\0"

class base_encoder
{
    public:
    base_encoder();
    virtual ~base_encoder(){}

    virtual int init(AVCodecContext *avctx);
    virtual int encode(AVCodecContext *avctx, AVPacket *pkt, const AVFrame *frame, int *got_packet);
    private:
    ojph::codestream codestream;
    ojph::ppm_in ppm;
    ojph::yuv_in yuv;
    ojph::image_in_base *base;

    char prog_order_store[5];
    char *prog_order;
    char profile_string_store[10];
    char *profile_string;
    ojph::ui32 num_decompositions;
    float quantization_step;
    bool reversible;
    int employ_color_transform;

    const int max_precinct_sizes = 33; //maximum number of decompositions is 32
    ojph::size precinct_size[33];
    int num_precincts;

    ojph::size block_size;
    ojph::size dims;
    ojph::size tile_size;
    ojph::point tile_offset;
    ojph::point image_offset;
    const ojph::ui32 initial_num_comps = 4;
    ojph::ui32 max_num_comps;
    ojph::ui32 num_components;
    ojph::ui32 num_is_signed;
    ojph::si32 is_signed_store[4];
    ojph::si32 *is_signed = is_signed_store;
    ojph::ui32 num_bit_depths;
    ojph::ui32 bit_depth_store[4];
    ojph::ui32 *bit_depth;
    ojph::ui32 num_comp_downsamps;
    ojph::point downsampling_store[4];
    ojph::point *comp_downsampling;
    bool tlm_marker;
    bool tileparts_at_resolutions;
    bool tileparts_at_components;
};
#endif

// visible to c and c++
#ifdef __cplusplus
extern "C" {
#endif

av_cold int libopenjph_encode_init(AVCodecContext *avctx);
int libopenjph_encode_frame(AVCodecContext *avctx, AVPacket *pkt, const AVFrame *frame, int *got_packet);
av_cold int libopenjph_encode_free(AVCodecContext *avctx);

#ifdef __cplusplus
}
#endif

#endif