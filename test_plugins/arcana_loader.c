#include "test_enc.h"
#include "test_mux.h"
#include "test_filter.h"
// #include "test_proto.h"

void arcana_register(char * conf_string)
{
    // arcana_register_protocol((void*)&ff_file2_protocol);
    arcana_register_muxer((void*)&ff_nut2_muxer);
    arcana_register_codec((void*)&ff_rawvideo_encoder2);
    arcana_register_filter((void*)&ff_vsrc_solidcolor);
}
