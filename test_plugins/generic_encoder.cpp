#include "generic_encoder.h"

base_encoder::base_encoder() : base(nullptr),
    prog_order_store("RPCL"),
    prog_order(prog_order_store),
    profile_string_store(PROFILE_STRING_NONE),
    profile_string(profile_string_store),
    num_decompositions(5),
    quantization_step(-1.0f),
    reversible(false),
    employ_color_transform(-1),
    num_precincts(-1),
    block_size(64, 64),
    dims(0,0),
    max_num_comps(initial_num_comps),
    num_components(0),
    num_is_signed(0),
    is_signed_store{-1, -1, -1, -1},
    num_bit_depths(0),
    bit_depth_store{0, 0, 0, 0},
    bit_depth(bit_depth_store),
    num_comp_downsamps(0),
    comp_downsampling(downsampling_store),
    tlm_marker(false),
    tileparts_at_resolutions(false),
    tileparts_at_components(false)
{
    tile_size.w = tile_size.h = 0;
    tile_offset.x = tile_offset.y = image_offset.x = image_offset.y = 0;
}

int base_encoder::init(AVCodecContext *avctx) 
{
    printf("thingy init\n");
    /*
    dims.w = avctx->width;
    dims.h = avctx->height;

    ojph::param_siz siz = codestream.access_siz();
    siz.set_image_extent(ojph::point(image_offset.x + dims.w, image_offset.y + dims.h));

    // get these from settings
    block_size.w = 64;
    block_size.h = 64;
    reversible = true;
    num_decompositions = 5;

    if(avctx->pix_fmt == AV_PIX_FMT_YUV420P)
    {
        // yuv is comprised of 3 components
        num_components = 3;

        // When the source is a .yuv file, use -downsamp {1,1} for 4:4:4 sources. 
        // For 4:2:2 downsampling, specify -downsamp {1,1},{2,1}, and for 4:2:0 subsampling specify -downsamp {1,1},{2,2}. 
        // The source must have already been downsampled (i.e., OpenJPH does not downsample the source before compression, 
        // but can compress downsampled sources).
        num_comp_downsamps = 2; // how many points are in comp_downsampling 
        comp_downsampling[0].x = 1;
        comp_downsampling[0].y = 1;
        comp_downsampling[1].x = 2;
        comp_downsampling[1].y = 2;

        num_bit_depths = 1;     // how many bit depths are in bit_depth (up to 4)
        bit_depth[0] = 8;

        num_is_signed = 1;      // how many signed are in is_signed (up to 4)
        is_signed[0] = 0;

        yuv.set_img_props(dims, num_components, num_comp_downsamps, comp_downsampling);
        yuv.set_bit_depth(num_bit_depths, bit_depth);

        ojph::ui32 last_signed_idx = 0, last_bit_depth_idx = 0;
        ojph::ui32 last_downsamp_idx = 0;
        siz.set_num_components(num_components);
        for (ojph::ui32 c = 0; c < num_components; ++c)
        {
          ojph::point cp_ds = comp_downsampling
              [c < num_comp_downsamps ? c : last_downsamp_idx];
          last_downsamp_idx += last_downsamp_idx+1 < num_comp_downsamps ? 1:0;
          ojph::ui32 bd = bit_depth[c<num_bit_depths ? c : last_bit_depth_idx];
          last_bit_depth_idx += last_bit_depth_idx + 1 < num_bit_depths ? 1:0;
          int is = is_signed[c < num_is_signed ? c : last_signed_idx];
          last_signed_idx += last_signed_idx + 1 < num_is_signed ? 1 : 0;
          siz.set_component(c, cp_ds, bd, is == 1);
        }
        siz.set_image_offset(image_offset);
        siz.set_tile_size(tile_size);
        siz.set_tile_offset(tile_offset);

        ojph::param_cod cod = codestream.access_cod();
        cod.set_num_decomposition(num_decompositions);
        cod.set_block_dims(block_size.w, block_size.h);
        if (num_precincts != -1)
          cod.set_precinct_size(num_precincts, precinct_size);
        cod.set_progression_order(prog_order);
        if (employ_color_transform == -1)
          cod.set_color_transform(false);
        else
          OJPH_ERROR(0x01000031,
            "We currently do not support color transform on raw(yuv) files."
            " In any case, this not a normal usage scenario.  The OpenJPH "
            "library however does support that, but ojph_compress.cpp must be "
            "modified to send all lines from one component before moving to "
            "the next component;  this requires buffering components outside"
            " of the OpenJPH library");
        cod.set_reversible(reversible);
        if (!reversible && quantization_step != -1.0f)
          codestream.access_qcd().set_irrev_quant(quantization_step);
        codestream.set_planar(true);
        if (profile_string[0] != '\0')
          codestream.set_profile(profile_string);
        codestream.set_tilepart_divisions(tileparts_at_resolutions, 
                                          tileparts_at_components);
        codestream.request_tlm_marker(tlm_marker);          

        // we'll use mem_infile
        // yuv.open(input_filename);
        base = &yuv;
    }
    */
    return 0;
}

int base_encoder::encode(AVCodecContext *avctx, AVPacket *pkt, const AVFrame *frame, int *got_packet)
{
    // mem_outfile in /home/rich/ffmpeg_cradle/test_plugs/OpenJPH/src/core/common/ojph_file.h handles output memory buffer
    // yuv_in in /home/rich/ffmpeg_cradle/test_plugs/OpenJPH/src/apps/common/ojph_img_io.h holds yuv image data

    int ret = av_image_get_buffer_size((AVPixelFormat)frame->format,
                                       frame->width, frame->height, 1);

    ojph::mem_outfile j2c_file;
    j2c_file.open(ret);
    codestream.write_headers(&j2c_file);


    ojph::ui32 next_comp;
    ojph::line_buf* cur_line = codestream.exchange(NULL, next_comp);

    /*
    if (ret < 0)
        return ret;

    if ((ret = ff_get_encode_buffer(avctx, pkt, ret, 0)) < 0)
        return ret;
    if ((ret = av_image_copy_to_buffer(pkt->data, pkt->size,
                                       (const uint8_t **)frame->data, frame->linesize,
                                       (AVPixelFormat)frame->format,
                                       frame->width, frame->height, 1)) < 0)
        return ret;

    if(avctx->codec_tag == AV_RL32("yuv2") && ret > 0 &&
       frame->format   == AV_PIX_FMT_YUYV422) {
        int x;
        for(x = 1; x < frame->height*frame->width*2; x += 2)
            pkt->data[x] ^= 0x80;
    } else if (avctx->codec_tag == AV_RL32("b64a") && ret > 0 &&
        frame->format == AV_PIX_FMT_RGBA64BE) {
        uint64_t v;
        int x;
        for (x = 0; x < frame->height * frame->width; x++) {
            v = AV_RB64(&pkt->data[8 * x]);
            AV_WB64(&pkt->data[8 * x], v << 48 | v >> 16);
        }
    }
    */

    *got_packet = 1;
    return 0;
}

extern "C"
{

av_cold int libopenjph_encode_init(AVCodecContext *avctx)
{
    base_encoder * encoder = new base_encoder();
    LibOpenJPHContext *context = (LibOpenJPHContext*)avctx->priv_data;
    context->encoder = encoder;
    return encoder->init(avctx);
}

int libopenjph_encode_frame(AVCodecContext *avctx, AVPacket *pkt, const AVFrame *frame, int *got_packet)
{
    LibOpenJPHContext *context = (LibOpenJPHContext*)avctx->priv_data;
    base_encoder * encoder = static_cast<base_encoder*>(context->encoder);
    return encoder->encode(avctx, pkt, frame, got_packet);
}

av_cold int libopenjph_encode_free(AVCodecContext *avctx)
{
    LibOpenJPHContext *context = (LibOpenJPHContext*)avctx->priv_data;
    base_encoder * encoder = static_cast<base_encoder*>(context->encoder);
    delete encoder;
    return 0;
}
}
