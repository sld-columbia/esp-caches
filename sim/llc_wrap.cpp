#include "llc_wrap.h"

llc_wrapper_conv::thread_llc_req_in_data_conv(){
    llc_req_in_data_conv = llc_req_in.data.read();
}

llc_wrapper_conv::thread_llc_dma_req_in_data_conv(){
    llc_dma_req_in_data_conv = llc_dma_req_in.data.read();
}

llc_wrapper_conv::thread_llc_rsp_in_data_conv(){
    llc_rsp_in_data_conv = llc_rsp_in.data.read();
}

llc_wrapper_conv::thread_llc_mem_rsp_data_conv(){
    llc_mem_rsp_data_conv = llc_mem_rsp.data.read();
}

llc_wrapper_conv::thread_llc_rst_tb_data_conv(){
    llc_rst_tb_data_conv = llc_rst_tb.data.read();
}

llc_wrapper_conv::thread_llc_rsp_out_data_conv(){
    llc_rsp_out_t tmp = llc_rsp_out_data_conv.read();
    llc_rsp_out.data.write(tmp);
}

llc_wrapper_conv::thread_llc_dma_rsp_out_data_conv(){
    llc_rsp_out_t tmp = llc_dma_rsp_out_data_conv.read();
    llc_dma_rsp_out.data.write(tmp);
}

llc_wrapper_conv::thread_llc_fwd_out_data_conv(){
    llc_fwd_out_t tmp = llc_fwd_out_data_conv.read();
    llc_fwd_out.data.write(tmp);
}

llc_wrapper_conv::thread_llc_mem_req_data_conv(){
    llc_mem_req_t tmp = llc_mem_req_data_conv.read();
    llc_mem_req.data.write(tmp);
}

llc_wrapper_conv::thread_llc_rst_tb_done_data_conv(){
    bool tmp = llc_rst_tb_done_data_conv.read();
    llc_rst_tb_done.data.write(tmp);
}

#ifdef STATS_ENABLE
llc_wrapper_conv::thread_llc_stats_data_conv(){
    bool tmp = llc_stats_data_conv.read();
    llc_stats.data.write(tmp);
}
#endif

NCSC_MODULE_EXPORT(llc_wrapper_conv); 
