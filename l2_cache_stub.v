`include "tl_params.vh"

// Stub module representing an L2 cache (TileLink Slave)
module l2_cache_stub (
    input clk,
    input rst_n,

    // TileLink Interface (Slave Port)
    // Channel A (Master -> Slave)
    input              a_valid,
    output             a_ready, // Keep combinational
    input [2:0]        a_opcode,
    input [2:0]        a_param,
    input [`TL_SZW-1:0] a_size,
    input [`TL_AIW-1:0] a_source,
    input [`TL_AW-1:0] a_address,
    input [`TL_BEW-1:0] a_mask,
    input [`TL_DW-1:0] a_data,
    input              a_corrupt,

    // Channel D (Slave -> Master)
    output reg         d_valid,
    input              d_ready,
    output reg [3:0]   d_opcode,
    output reg [1:0]   d_param,
    output reg [`TL_SZW-1:0] d_size,
    output reg [`TL_AIW-1:0] d_source,
    output reg [`TL_DIW-1:0] d_sink,
    output reg         d_denied,
    output reg [`TL_DW-1:0] d_data,
    output reg         d_corrupt
);

    // --- Internal Logic ---

    // State machine for handling requests and sending responses
    localparam RESP_IDLE      = 2'b00;
    localparam RESP_SEND_ACK = 2'b01; // State to send AccessAck (for Put)
    localparam RESP_SEND_ACK_DATA = 2'b10; // State to send AccessAckData (for Get)
    // Could add more states for multi-beat responses later

    reg [1:0] resp_state, resp_next_state;

    // Registers to store incoming request info needed for the response
    reg [`TL_AIW-1:0] resp_source_reg;
    reg [`TL_SZW-1:0] resp_size_reg;
    reg [2:0]         req_opcode_reg; // Store opcode to determine response type
    reg [`TL_AW-1:0] resp_address_reg; // Add register to store address

    // Simple memory model (optional, just for display/debug)
    reg [`TL_DW-1:0] mem [1023:0]; // Small memory array

    // Internal variables for memory simulation (declared at module scope)
    reg [`TL_DW-1:0] current_mem_val;
    reg [`TL_DW-1:0] next_mem_val;
    integer i;

    // -- State Machine Logic --

    // State transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_state <= RESP_IDLE;
            resp_source_reg <= `TL_AIW'd0;
            resp_size_reg <= `TL_SZW'd0;
            req_opcode_reg <= 3'bxxx; // Unknown opcode initially
            resp_address_reg <= `TL_AW'd0; // Initialize address register
        end else begin
            resp_state <= resp_next_state;
            // Latch request info when accepting it and moving to a send state
            if ((resp_next_state == RESP_SEND_ACK || resp_next_state == RESP_SEND_ACK_DATA) && resp_state == RESP_IDLE) begin
                if (a_valid && a_ready) begin // Ensure request is accepted
                    resp_source_reg <= a_source;
                    resp_size_reg   <= a_size;
                    req_opcode_reg  <= a_opcode;
                    resp_address_reg <= a_address;

                    // Optional: Simulate memory write for Put
                    if (a_opcode == `TL_A_OP_PUT_FULL_DATA || a_opcode == `TL_A_OP_PUT_PARTIAL_DATA) begin
                        // Simple word-aligned address for demo memory
                        // Remove declarations from here
                        // reg [`TL_DW-1:0] current_mem_val;
                        // reg [`TL_DW-1:0] next_mem_val;
                        // integer i;

                        // A real implementation needs proper address decoding
                        current_mem_val = mem[a_address[`TL_AW-1:3]];
                        next_mem_val = current_mem_val; // Start with current value

                        // Apply partial data based on mask
                        for (i = 0; i < `TL_BEW; i = i + 1) begin
                            if (a_mask[i]) begin
                                next_mem_val[i*8 +: 8] = a_data[i*8 +: 8];
                            end
                        end

                        mem[a_address[`TL_AW-1:3]] = next_mem_val;

                        $display("[%0t ns] L2 Stub: Received Put (Op: %h, Addr: %h, Src: %h, Mask: %h, Data: %h), Mem written: %h",
                                 $time, a_opcode, a_address, a_source, a_mask, a_data, next_mem_val);
                    end else if (a_opcode == `TL_A_OP_GET) begin
                         $display("[%0t ns] L2 Stub: Received Get (Op: %h, Addr: %h, Src: %h)",
                                 $time, a_opcode, a_address, a_source);
                    end
                end
            end
        end
    end

    // Next state logic and Channel D outputs
    always @(*) begin
        // Default assignments
        resp_next_state = resp_state;
        d_valid         = 1'b0;
        d_opcode        = `TL_D_OP_ACCESS_ACK; // Default response type
        d_param         = 2'b0;
        d_size          = resp_size_reg; // Use stored size
        d_source        = resp_source_reg; // Use stored source
        d_sink          = `TL_DIW'd0; // Default Sink ID
        d_denied        = 1'b0;
        d_data          = 64'd0; // Default data (overridden for AckData)
        d_corrupt       = 1'b0;

        case (resp_state)
            RESP_IDLE: begin
                // If a valid request arrives and we are ready, determine response type and go to send state
                if (a_valid && a_ready) begin
                    if (a_opcode == `TL_A_OP_GET) begin
                        resp_next_state = RESP_SEND_ACK_DATA;
                    end
                    else if (a_opcode == `TL_A_OP_PUT_FULL_DATA || a_opcode == `TL_A_OP_PUT_PARTIAL_DATA) begin
                        resp_next_state = RESP_SEND_ACK;
                    end
                    // Handle other opcodes later (Atomics, etc.)
                end
            end

            RESP_SEND_ACK: begin // Sending AccessAck for Put
                d_valid = 1'b1; // Assert response valid
                d_opcode= `TL_D_OP_ACCESS_ACK;
                d_size  = resp_size_reg;  // Reflect original size
                d_source= resp_source_reg;
                d_data  = 64'd0; // Data not valid for AccessAck

                // If response is accepted, go back to IDLE
                if (d_valid && d_ready) begin
                    resp_next_state = RESP_IDLE;
                end else begin
                    resp_next_state = RESP_SEND_ACK; // Keep trying to send
                end
            end

            RESP_SEND_ACK_DATA: begin // Sending AccessAckData for Get
                d_valid = 1'b1; // Assert response valid
                d_opcode= `TL_D_OP_ACCESS_ACK_DATA;
                d_size  = resp_size_reg;   // Reflect original size
                d_source= resp_source_reg;
                // Use latched address to read from mem array
                // Simple word-aligned read for demo memory
                d_data  = mem[resp_address_reg[`TL_AW-1:3]]; // <<< Read from mem using latched address

                // If response is accepted, go back to IDLE
                if (d_valid && d_ready) begin
                    resp_next_state = RESP_IDLE;
                end else begin
                    resp_next_state = RESP_SEND_ACK_DATA; // Keep trying to send
                end
            end

            default: begin
                resp_next_state = RESP_IDLE;
            end
        endcase
    end

    // -- Channel A Handling --
    // Ready to accept a new request only when idle
    assign a_ready = (resp_state == RESP_IDLE);

endmodule 