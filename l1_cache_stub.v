`include "tl_params.vh"

// Stub module representing an L1 cache (TileLink Master)
module l1_cache_stub (
    input clk,
    input rst_n,

    // TileLink Interface (Master Port)
    // Channel A (Master -> Slave)
    output reg         a_valid,
    input              a_ready,
    output reg [2:0]   a_opcode,
    output reg [2:0]   a_param,
    output reg [`TL_SZW-1:0] a_size,
    output reg [`TL_AIW-1:0] a_source,
    output reg [`TL_AW-1:0] a_address,
    output reg [`TL_BEW-1:0] a_mask,
    output reg [`TL_DW-1:0] a_data,
    output reg         a_corrupt,

    // Channel D (Slave -> Master)
    input              d_valid,
    output reg         d_ready,
    input [3:0]        d_opcode,
    input [1:0]        d_param,
    input [`TL_SZW-1:0] d_size,
    input [`TL_AIW-1:0] d_source,
    input [`TL_DIW-1:0] d_sink,
    input              d_denied,
    input [`TL_DW-1:0] d_data,
    input              d_corrupt
);

    // --- Internal Logic ---

    // State machine to send Get, wait, send PutFull, wait, send PutPartial, wait
    localparam S_IDLE           = 4'b0000;
    localparam S_SEND_GET       = 4'b0001;
    localparam S_WAIT_GET_RESP  = 4'b0010;
    localparam S_SEND_PUT_FULL  = 4'b0011;
    localparam S_WAIT_PUT_RESP  = 4'b0100;
    localparam S_SEND_PUT_PART  = 4'b0101;
    localparam S_WAIT_PUTP_RESP = 4'b0110;
    localparam S_DONE           = 4'b0111; // Stay here once finished

    reg [3:0] state, next_state;

    // Request parameters
    parameter GET_ADDR    = 32'h1000;
    parameter GET_SIZE    = `TL_SZW'd3; // 8 bytes
    parameter GET_SOURCE  = `TL_AIW'd1;

    parameter PUTF_ADDR   = 32'h2000;
    parameter PUTF_SIZE   = `TL_SZW'd3; // 8 bytes
    parameter PUTF_SOURCE = `TL_AIW'd2;
    parameter PUTF_DATA   = 64'h11223344AABBCCDD;

    parameter PUTP_ADDR   = 32'h3004; // Address for partial put (e.g., upper 4 bytes)
    parameter PUTP_SIZE   = `TL_SZW'd3; // Size still refers to the whole 8-byte block
    parameter PUTP_SOURCE = `TL_AIW'd3; // New source ID
    parameter PUTP_DATA   = 64'hFFFFFFFF00000000; // Only upper bytes are valid
    parameter PUTP_MASK   = 8'b11110000; // Mask indicating upper 4 bytes (bytes 4-7)

    // Registers for stable output values
    reg [`TL_AW-1:0] req_address;
    reg [`TL_SZW-1:0] req_size;
    reg [`TL_AIW-1:0] req_source;
    reg [`TL_DW-1:0] req_data;
    reg [`TL_BEW-1:0] req_mask;

    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state and output logic
    always @(*) begin
        // Default assignments for outputs
        next_state = state;
        a_valid    = 1'b0;
        a_opcode   = `TL_A_OP_GET; // Default, will be overridden
        a_param    = 3'b0;
        a_size     = req_size;
        a_source   = req_source;
        a_address  = req_address;
        a_mask     = req_mask;
        a_data     = req_data;
        a_corrupt  = 1'b0;

        d_ready    = 1'b0; // Default: Don't accept responses unless in wait state

        // Default assignments for registers (hold values)
        req_address = req_address;
        req_size    = req_size;
        req_source  = req_source;
        req_data    = req_data;
        req_mask    = req_mask;

        case (state)
            S_IDLE: begin
                // Prepare for Get request
                req_address = GET_ADDR;
                req_size    = GET_SIZE;
                req_source  = GET_SOURCE;
                req_mask    = {`TL_BEW{1'b1}};
                req_data    = 64'd0;
                next_state  = S_SEND_GET;
            end

            S_SEND_GET: begin
                a_valid   = 1'b1;
                a_opcode  = `TL_A_OP_GET;
                if (a_valid && a_ready) begin
                    next_state = S_WAIT_GET_RESP;
                end else begin
                    next_state = S_SEND_GET;
                end
            end

            S_WAIT_GET_RESP: begin
                d_ready = 1'b1;
                if (d_valid && d_ready) begin
                    if (d_source == GET_SOURCE && (d_opcode == `TL_D_OP_ACCESS_ACK_DATA)) begin
                        $display("[%0t ns] L1 Stub: Received AccessAckData for Get (Source %d)", $time, d_source);
                        // Prepare for Put Full request
                        req_address = PUTF_ADDR;
                        req_size    = PUTF_SIZE;
                        req_source  = PUTF_SOURCE;
                        req_mask    = {`TL_BEW{1'b1}}; // Full mask
                        req_data    = PUTF_DATA;
                        next_state  = S_SEND_PUT_FULL;
                    end else begin
                        $display("[%0t ns] L1 Stub: ERROR - Unexpected response in WAIT_GET_RESP state (Op: %h, Src: %h)", $time, d_opcode, d_source);
                        next_state = S_DONE;
                    end
                end else begin
                    next_state = S_WAIT_GET_RESP;
                end
            end

            S_SEND_PUT_FULL: begin
                a_valid  = 1'b1;
                a_opcode = `TL_A_OP_PUT_FULL_DATA;
                if (a_valid && a_ready) begin
                    next_state = S_WAIT_PUT_RESP;
                end else begin
                    next_state = S_SEND_PUT_FULL;
                end
            end

            S_WAIT_PUT_RESP: begin
                d_ready = 1'b1;
                if (d_valid && d_ready) begin
                    if (d_source == PUTF_SOURCE && (d_opcode == `TL_D_OP_ACCESS_ACK)) begin
                         $display("[%0t ns] L1 Stub: Received AccessAck for PutFull (Source %d)", $time, d_source);
                        // Prepare for Put Partial request
                        req_address = PUTP_ADDR;
                        req_size    = PUTP_SIZE;
                        req_source  = PUTP_SOURCE;
                        req_mask    = PUTP_MASK; // Partial mask
                        req_data    = PUTP_DATA;
                        next_state  = S_SEND_PUT_PART;
                    end else begin
                        $display("[%0t ns] L1 Stub: ERROR - Unexpected response in WAIT_PUT_RESP state (Op: %h, Src: %h)", $time, d_opcode, d_source);
                        next_state = S_DONE;
                    end
                end else begin
                    next_state = S_WAIT_PUT_RESP;
                end
            end

            S_SEND_PUT_PART: begin
                 a_valid  = 1'b1;
                 a_opcode = `TL_A_OP_PUT_PARTIAL_DATA;
                 if (a_valid && a_ready) begin
                     next_state = S_WAIT_PUTP_RESP;
                 end else begin
                     next_state = S_SEND_PUT_PART;
                 end
            end

            S_WAIT_PUTP_RESP: begin
                 d_ready = 1'b1;
                 if (d_valid && d_ready) begin
                     if (d_source == PUTP_SOURCE && (d_opcode == `TL_D_OP_ACCESS_ACK)) begin
                          $display("[%0t ns] L1 Stub: Received AccessAck for PutPartial (Source %d)", $time, d_source);
                          next_state = S_DONE;
                     end else begin
                         $display("[%0t ns] L1 Stub: ERROR - Unexpected response in WAIT_PUTP_RESP state (Op: %h, Src: %h)", $time, d_opcode, d_source);
                         next_state = S_DONE;
                     end
                 end else begin
                     next_state = S_WAIT_PUTP_RESP;
                 end
            end

            S_DONE: begin
                next_state = S_DONE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule 