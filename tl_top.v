`include "tl_params.vh"

module tl_top (
    input clk,
    input rst_n
);

    // --- Wires connecting L1 stub to Interconnect Master Port 0 ---
    // Channel A (L1 -> Interconnect)
    wire         l1_a_valid;
    wire         l1_a_ready;
    wire [2:0]   l1_a_opcode;
    wire [2:0]   l1_a_param;
    wire [`TL_SZW-1:0] l1_a_size;
    wire [`TL_AIW-1:0] l1_a_source;
    wire [`TL_AW-1:0] l1_a_address;
    wire [`TL_BEW-1:0] l1_a_mask;
    wire [`TL_DW-1:0] l1_a_data;
    wire         l1_a_corrupt;
    // Channel D (Interconnect -> L1)
    wire         l1_d_valid;
    wire         l1_d_ready;
    wire [3:0]   l1_d_opcode;
    wire [1:0]   l1_d_param;
    wire [`TL_SZW-1:0] l1_d_size;
    wire [`TL_AIW-1:0] l1_d_source;
    wire [`TL_DIW-1:0] l1_d_sink;
    wire         l1_d_denied;
    wire [`TL_DW-1:0] l1_d_data;
    wire         l1_d_corrupt;

    // --- Wires connecting Interconnect Slave Port 0 to L2 stub ---
    // Channel A (Interconnect -> L2)
    wire         l2_a_valid;
    wire         l2_a_ready;
    wire [2:0]   l2_a_opcode;
    wire [2:0]   l2_a_param;
    wire [`TL_SZW-1:0] l2_a_size;
    wire [`TL_AIW-1:0] l2_a_source;
    wire [`TL_AW-1:0] l2_a_address;
    wire [`TL_BEW-1:0] l2_a_mask;
    wire [`TL_DW-1:0] l2_a_data;
    wire         l2_a_corrupt;
    // Channel D (L2 -> Interconnect)
    wire         l2_d_valid;
    wire         l2_d_ready;
    wire [3:0]   l2_d_opcode;
    wire [1:0]   l2_d_param;
    wire [`TL_SZW-1:0] l2_d_size;
    wire [`TL_AIW-1:0] l2_d_source;
    wire [`TL_DIW-1:0] l2_d_sink;
    wire         l2_d_denied;
    wire [`TL_DW-1:0] l2_d_data;
    wire         l2_d_corrupt;

    // --- Instantiations ---

    // Instantiate L1 Cache Stub (Master)
    l1_cache_stub l1_stub (
        .clk        (clk),
        .rst_n      (rst_n),
        // Channel A
        .a_valid    (l1_a_valid),
        .a_ready    (l1_a_ready),
        .a_opcode   (l1_a_opcode),
        .a_param    (l1_a_param),
        .a_size     (l1_a_size),
        .a_source   (l1_a_source),
        .a_address  (l1_a_address),
        .a_mask     (l1_a_mask),
        .a_data     (l1_a_data),
        .a_corrupt  (l1_a_corrupt),
        // Channel D
        .d_valid    (l1_d_valid),
        .d_ready    (l1_d_ready),
        .d_opcode   (l1_d_opcode),
        .d_param    (l1_d_param),
        .d_size     (l1_d_size),
        .d_source   (l1_d_source),
        .d_sink     (l1_d_sink),
        .d_denied   (l1_d_denied),
        .d_data     (l1_d_data),
        .d_corrupt  (l1_d_corrupt)
    );

    // Instantiate L2 Cache Stub (Slave)
    l2_cache_stub l2_stub (
        .clk        (clk),
        .rst_n      (rst_n),
        // Channel A
        .a_valid    (l2_a_valid),
        .a_ready    (l2_a_ready),
        .a_opcode   (l2_a_opcode),
        .a_param    (l2_a_param),
        .a_size     (l2_a_size),
        .a_source   (l2_a_source),
        .a_address  (l2_a_address),
        .a_mask     (l2_a_mask),
        .a_data     (l2_a_data),
        .a_corrupt  (l2_a_corrupt),
        // Channel D
        .d_valid    (l2_d_valid),
        .d_ready    (l2_d_ready),
        .d_opcode   (l2_d_opcode),
        .d_param    (l2_d_param),
        .d_size     (l2_d_size),
        .d_source   (l2_d_source),
        .d_sink     (l2_d_sink),
        .d_denied   (l2_d_denied),
        .d_data     (l2_d_data),
        .d_corrupt  (l2_d_corrupt)
    );

    // Instantiate TileLink Interconnect
    tl_interconnect interconnect (
        .clk        (clk),
        .rst_n      (rst_n),
        // Master Port 0 (Connects to L1)
        .m0_a_valid    (l1_a_valid),
        .m0_a_ready    (l1_a_ready),
        .m0_a_opcode   (l1_a_opcode),
        .m0_a_param    (l1_a_param),
        .m0_a_size     (l1_a_size),
        .m0_a_source   (l1_a_source),
        .m0_a_address  (l1_a_address),
        .m0_a_mask     (l1_a_mask),
        .m0_a_data     (l1_a_data),
        .m0_a_corrupt  (l1_a_corrupt),
        .m0_d_valid    (l1_d_valid),
        .m0_d_ready    (l1_d_ready),
        .m0_d_opcode   (l1_d_opcode),
        .m0_d_param    (l1_d_param),
        .m0_d_size     (l1_d_size),
        .m0_d_source   (l1_d_source),
        .m0_d_sink     (l1_d_sink),
        .m0_d_denied   (l1_d_denied),
        .m0_d_data     (l1_d_data),
        .m0_d_corrupt  (l1_d_corrupt),
        // Slave Port 0 (Connects to L2)
        .s0_a_valid    (l2_a_valid),
        .s0_a_ready    (l2_a_ready),
        .s0_a_opcode   (l2_a_opcode),
        .s0_a_param    (l2_a_param),
        .s0_a_size     (l2_a_size),
        .s0_a_source   (l2_a_source),
        .s0_a_address  (l2_a_address),
        .s0_a_mask     (l2_a_mask),
        .s0_a_data     (l2_a_data),
        .s0_a_corrupt  (l2_a_corrupt),
        .s0_d_valid    (l2_d_valid),
        .s0_d_ready    (l2_d_ready),
        .s0_d_opcode   (l2_d_opcode),
        .s0_d_param    (l2_d_param),
        .s0_d_size     (l2_d_size),
        .s0_d_source   (l2_d_source),
        .s0_d_sink     (l2_d_sink),
        .s0_d_denied   (l2_d_denied),
        .s0_d_data     (l2_d_data),
        .s0_d_corrupt  (l2_d_corrupt)
    );

endmodule 