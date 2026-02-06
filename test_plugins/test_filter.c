/*
 * Solid Color Video Source Filter Plugin
 *
 * Generates video frames filled with a single RGB color.
 * Demonstrates the arcana_register_filter() plugin API.
 *
 * Usage:
 *   ffmpeg_arcana -f lavfi -i "solidcolor=color=0xFF0000:size=640x480:rate=30:duration=5" output.mp4
 */

#include "test_filter.h"
#include "arcana/libavfilter/avfilter.h"
#include "arcana/libavprivate/libavfilter/filters.h"
#include "arcana/libavprivate/libavfilter/video.h"
#include "arcana/libavutil/opt.h"
#include "arcana/libavutil/pixfmt.h"
#include "arcana/libavutil/imgutils.h"
#include "libavutil/internal.h"

#include <float.h>
#include <string.h>
#include <stdlib.h>

typedef struct SolidColorContext {
    const AVClass *class;
    int w, h;
    AVRational frame_rate;
    char *color_str;
    double duration;
    uint8_t r, g, b;
    uint64_t pts;
    int64_t max_pts;
} SolidColorContext;

static int parse_hex_color(SolidColorContext *ctx)
{
    const char *s = ctx->color_str;
    unsigned long val;
    char *end;

    if (!s || !*s) {
        ctx->r = ctx->g = ctx->b = 0;
        return 0;
    }

    /* skip optional 0x or # prefix */
    if (s[0] == '#')
        s++;
    else if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
        s += 2;

    val = strtoul(s, &end, 16);
    if (*end != '\0')
        return AVERROR(EINVAL);

    ctx->r = (val >> 16) & 0xFF;
    ctx->g = (val >>  8) & 0xFF;
    ctx->b = (val >>  0) & 0xFF;
    return 0;
}

static av_cold int solidcolor_init(AVFilterContext *fctx)
{
    SolidColorContext *ctx = fctx->priv;
    int ret;

    ret = parse_hex_color(ctx);
    if (ret < 0) {
        av_log(fctx, AV_LOG_ERROR, "Invalid color string: '%s'. Use hex format like 0xFF0000 or #00FF00.\n",
               ctx->color_str);
        return ret;
    }

    av_log(fctx, AV_LOG_INFO, "solidcolor: %dx%d @ %d/%d fps, color=#%02X%02X%02X",
           ctx->w, ctx->h, ctx->frame_rate.num, ctx->frame_rate.den,
           ctx->r, ctx->g, ctx->b);
    if (ctx->duration > 0)
        av_log(fctx, AV_LOG_INFO, ", duration=%.2fs", ctx->duration);
    av_log(fctx, AV_LOG_INFO, "\n");

    return 0;
}

static int solidcolor_config_props(AVFilterLink *outlink)
{
    SolidColorContext *ctx = outlink->src->priv;
    FilterLink *fl = ff_filter_link(outlink);

    outlink->w = ctx->w;
    outlink->h = ctx->h;
    outlink->time_base = av_inv_q(ctx->frame_rate);
    fl->frame_rate = ctx->frame_rate;

    if (ctx->duration > 0)
        ctx->max_pts = (int64_t)(ctx->duration * ctx->frame_rate.num / ctx->frame_rate.den);
    else
        ctx->max_pts = -1;

    ctx->pts = 0;
    return 0;
}

static int solidcolor_request_frame(AVFilterLink *outlink)
{
    AVFilterContext *fctx = outlink->src;
    SolidColorContext *ctx = fctx->priv;
    AVFrame *frame;
    int y;

    /* check if we've exceeded the requested duration */
    if (ctx->max_pts >= 0 && (int64_t)ctx->pts >= ctx->max_pts) {
        ff_outlink_set_status(outlink, AVERROR_EOF, ctx->pts);
        return AVERROR_EOF;
    }

    frame = ff_get_video_buffer(outlink, ctx->w, ctx->h);
    if (!frame)
        return AVERROR(ENOMEM);

    /* fill each row with the solid RGB color */
    for (y = 0; y < ctx->h; y++) {
        uint8_t *row = frame->data[0] + y * frame->linesize[0];
        int x;
        for (x = 0; x < ctx->w; x++) {
            row[x * 3 + 0] = ctx->r;
            row[x * 3 + 1] = ctx->g;
            row[x * 3 + 2] = ctx->b;
        }
    }

    frame->sample_aspect_ratio = (AVRational){1, 1};
    frame->pts = ctx->pts++;
    frame->duration = 1;
    frame->flags |= AV_FRAME_FLAG_KEY;
    frame->pict_type = AV_PICTURE_TYPE_I;

    return ff_filter_frame(outlink, frame);
}

#define OFFSET(x) offsetof(SolidColorContext, x)
#define FLAGS (AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_FILTERING_PARAM)

static const AVOption solidcolor_options[] = {
    { "color",    "set fill color (hex RGB)",  OFFSET(color_str),  AV_OPT_TYPE_STRING, {.str = "0x000000"}, 0, 0, FLAGS },
    { "c",        "set fill color (hex RGB)",  OFFSET(color_str),  AV_OPT_TYPE_STRING, {.str = "0x000000"}, 0, 0, FLAGS },
    { "size",     "set video size",            OFFSET(w),          AV_OPT_TYPE_IMAGE_SIZE, {.str = "320x240"}, 0, 0, FLAGS },
    { "s",        "set video size",            OFFSET(w),          AV_OPT_TYPE_IMAGE_SIZE, {.str = "320x240"}, 0, 0, FLAGS },
    { "rate",     "set video frame rate",      OFFSET(frame_rate), AV_OPT_TYPE_VIDEO_RATE, {.str = "25"},     0, INT_MAX, FLAGS },
    { "r",        "set video frame rate",      OFFSET(frame_rate), AV_OPT_TYPE_VIDEO_RATE, {.str = "25"},     0, INT_MAX, FLAGS },
    { "duration", "set video duration (s)",    OFFSET(duration),   AV_OPT_TYPE_DOUBLE,     {.dbl = 0},        0, DBL_MAX, FLAGS },
    { "d",        "set video duration (s)",    OFFSET(duration),   AV_OPT_TYPE_DOUBLE,     {.dbl = 0},        0, DBL_MAX, FLAGS },
    { NULL }
};

AVFILTER_DEFINE_CLASS(solidcolor);

static const AVFilterPad solidcolor_outputs[] = {
    {
        .name          = "default",
        .type          = AVMEDIA_TYPE_VIDEO,
        .request_frame = solidcolor_request_frame,
        .config_props  = solidcolor_config_props,
    },
};

const AVFilter ff_vsrc_solidcolor = {
    .name        = "solidcolor",
    .description = NULL_IF_CONFIG_SMALL("Generate solid color video frames"),
    .priv_size   = sizeof(SolidColorContext),
    .priv_class  = &solidcolor_class,
    .init        = solidcolor_init,
    .inputs      = NULL,
    FILTER_OUTPUTS(solidcolor_outputs),
    FILTER_SINGLE_PIXFMT(AV_PIX_FMT_RGB24),
};
