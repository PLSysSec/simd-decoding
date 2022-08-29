#include <stdio.h>
#include <stdlib.h>
#include <decode_mod.h>

/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
    wasm2c_sandbox_funcs_t sbx_details = get_wasm2c_sandbox_info();
    sbx_details.wasm_rt_sys_init();
    int max_wasm_page = 0;
    wasm2c_sandbox_t* sbx_instance = (wasm2c_sandbox_t*) sbx_details.create_wasm2c_sandbox(max_wasm_page);
    double dt = w2c_timed_decode(sbx_instance, argv[1], argv[2]);
    printf("time: %f\n", dt);
    sbx_details.destroy_wasm2c_sandbox(sbx_instance);
    return 0;
}