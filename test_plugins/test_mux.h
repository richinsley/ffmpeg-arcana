#ifndef TEST_MUX_H
#define TEST_MUX_H

#include <libavformat/mux.h>
#include "arcana/libavprivate/libavformat/version_major.h"

// AVOutputFormat was changed to FFOutputFormat in libavformat version 60
#if LIBAVFORMAT_VERSION_MAJOR == 59
extern const AVOutputFormat ff_nut2_muxer;
#else
extern const FFOutputFormat ff_nut2_muxer;
#endif


#endif