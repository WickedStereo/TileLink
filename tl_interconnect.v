`include "tl_params.vh"

// Basic TileLink Interconnect
// Connects 1 Master (e.g., L1) to 1 Slave (e.g., L2)
module tl_interconnect (
    input clk,
    input rst_n,

    // --- Master Port 0 (Input from L1) ---
    // Channel A (Master -> Interconnect)
    input          m0_a_valid,
    output         m0_a_ready,
    input [2:0]    m0_a_opcode,
    input [2:0]    m0_a_param,
    input [`TL_SZW-1:0] m0_a_size,
    input [`TL_AIW-1:0] m0_a_source, // Master must assign unique source ID
    input [`TL_AW-1:0] m0_a_address,
    input [`TL_BEW-1:0] m0_a_mask,
    input [`TL_DW-1:0] m0_a_data,
    input          m0_a_corrupt,
    // Channel D (Interconnect -> Master)
    output         m0_d_valid,
    input          m0_d_ready,
    output [3:0]   m0_d_opcode,
    output [1:0]   m0_d_param,
    output [`TL_SZW-1:0] m0_d_size,
    output [`TL_AIW-1:0] m0_d_source,
    output [`TL_DIW-1:0] m0_d_sink,
    output         m0_d_denied,
    output [`TL_DW-1:0] m0_d_data,
    output         m0_d_corrupt,

    // --- Slave Port 0 (Output to L2) ---
    // Channel A (Interconnect -> Slave)
    output         s0_a_valid,
    input          s0_a_ready,
    output [2:0]   s0_a_opcode,
    output [2:0]   s0_a_param,
    output [`TL_SZW-1:0] s0_a_size,
    output [`TL_AIW-1:0] s0_a_source,
    output [`TL_AW-1:0] s0_a_address,
    output [`TL_BEW-1:0] s0_a_mask,
    output [`TL_DW-1:0] s0_a_data,
    output         s0_a_corrupt,
    // Channel D (Slave -> Interconnect)
    input          s0_d_valid,
    output         s0_d_ready,
    input [3:0]    s0_d_opcode,
    input [1:0]    s0_d_param,
    input [`TL_SZW-1:0] s0_d_size,
    input [`TL_AIW-1:0] s0_d_source,
    input [`TL_DIW-1:0] s0_d_sink,
    input          s0_d_denied,
    input [`TL_DW-1:0] s0_d_data,
    input          s0_d_corrupt
);

    // --- Basic 1-to-1 Connection Logic ---

    // Channel A: Master Port 0 -> Slave Port 0
    assign s0_a_valid   = m0_a_valid;
    assign m0_a_ready   = s0_a_ready;
    assign s0_a_opcode  = m0_a_opcode;
    assign s0_a_param   = m0_a_param;
    assign s0_a_size    = m0_a_size;
    assign s0_a_source  = m0_a_source; // Pass through source ID
    assign s0_a_address = m0_a_address;
    assign s0_a_mask    = m0_a_mask;
    assign s0_a_data    = m0_a_data;
    assign s0_a_corrupt = m0_a_corrupt;

    // Channel D: Slave Port 0 -> Master Port 0
    assign m0_d_valid   = s0_d_valid;
    assign s0_d_ready   = m0_d_ready;
    assign m0_d_opcode  = s0_d_opcode;
    assign m0_d_param   = s0_d_param;
    assign m0_d_size    = s0_d_size;
    assign m0_d_source  = s0_d_source; // Pass through source ID
    assign m0_d_sink    = s0_d_sink;
    assign m0_d_denied  = s0_d_denied;
    assign m0_d_data    = s0_d_data;
    assign m0_d_corrupt = s0_d_corrupt;

    // TODO: Add logic for multiple masters/slaves and arbitration later
    // TODO: Add logic for Channels B, C, E later

endmodule 