// tl_params.vh
// Defines common parameters for the TileLink interface

// Adjust these parameters based on the specific system requirements

// Width of the address bus in bits
`define TL_AW 32
// Width of the data bus in bits
`define TL_DW 64
// Width of the source ID field in bits (identifies inflight transactions)
// Needs to be wide enough to hold unique IDs from all potential masters (L1s)
`define TL_AIW 4  // Can support 2^4 = 16 unique sources
// Width of the sink ID field in bits (used for tracking responses, relevant for TL-C)
`define TL_DIW 1  // For now, L2 is the only sink
// Width of the size field in bits (log2(Bytes))
`define TL_SZW 3  // log2(TL_DW/8) = log2(64/8) = log2(8) = 3

// Derived parameter: Number of bytes in the data bus
`define TL_DBW (`TL_DW / 8)
// Derived parameter: Width of the byte mask
`define TL_BEW (`TL_DW / 8)

// Opcodes for Channel A (Requests) - TL-UL subset
`define TL_A_OP_PUT_FULL_DATA  3'b000
`define TL_A_OP_PUT_PARTIAL_DATA 3'b001
`define TL_A_OP_GET             3'b100

// Opcodes for Channel D (Responses) - TL-UL subset
`define TL_D_OP_ACCESS_ACK      4'b0000
`define TL_D_OP_ACCESS_ACK_DATA 4'b0001

// Parameters for Channel A Messages (e.g., permissions for Get) - Simplified for UL
// `define TL_A_PARAM_???

// Parameters for Channel D Messages (e.g., permissions for Grant/AckData) - Simplified for UL
// `define TL_D_PARAM_??? 