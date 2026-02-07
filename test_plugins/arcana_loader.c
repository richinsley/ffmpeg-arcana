#include "test_enc.h"
#include "test_mux.h"
#ifndef DISABLE_TEST_FILTER
#include "test_filter.h"
#endif
#include "test_desc.h"
// #include "test_proto.h"

void arcana_register(char * conf_string)
{
    // arcana_register_protocol((void*)&ff_file2_protocol);
    arcana_register_muxer((void*)&ff_nut2_muxer);
    arcana_register_codec((void*)&ff_rawvideo_encoder2);
#ifndef DISABLE_TEST_FILTER
    arcana_register_filter((void*)&ff_vsrc_solidcolor);
#endif

    /* Register custom codec descriptor with a generated ID */
    arcana_test_descriptor.id = arcana_codec_id_generate(arcana_test_descriptor.name);
    arcana_register_codec_descriptor((void*)&arcana_test_descriptor);
}
