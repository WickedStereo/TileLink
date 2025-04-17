`timescale 1ns / 1ps
`include "tl_params.vh"

module tb_tl_top;

    // Parameters
    localparam CLK_PERIOD = 10; // Clock period in ns

    // Signals
    reg clk;
    reg rst_n;
    integer i; // Variable for loop

    // Instantiate the Top module (DUT - Design Under Test)
    tl_top dut (
        .clk    (clk),
        .rst_n  (rst_n)
    );

    // Clock generation
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2);
        clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // Reset generation and simulation sequence
    initial begin

        $display("Starting Testbench for tl_top");

        // Dump waves (optional, for waveform viewer like GTKWave)
        $dumpfile("tb_tl_top.vcd");
        $dumpvars(0, tb_tl_top); // Dump all signals in the testbench scope and below

        // Initialize signals
        rst_n = 1'b0; // Assert reset
        clk = 1'b0;   // Ensure clock starts low

        // --- Initialize L2 memory --- 
        // Use hierarchical path: tb_tl_top -> dut -> l2_stub -> mem
        $display("[%0t ns] Initializing L2 Stub Memory...", $time);
        for (i = 0; i < 1024; i = i + 1) begin
            // Initialize each memory location to 0 (or another value)
            dut.l2_stub.mem[i] = {`TL_DW{1'b0}};
        end
        $display("[%0t ns] L2 Stub Memory Initialized.", $time);
        // --- End Memory Initialization ---

        // Apply reset for a few cycles
        repeat (5) @(posedge clk);
        rst_n = 1'b1; // Deassert reset
        $display("[%0t ns] Reset deasserted", $time);

        // Let the simulation run for a while to see the transaction
        // Increase runtime slightly to ensure all transactions complete
        repeat (30) @(posedge clk); 

        $display("[%0t ns] Simulation finished", $time);
        $finish;
    end

    // Optional: Monitor key signals
    /*
    initial begin
        $monitor("[%0t ns] clk=%b rst_n=%b | A: valid=%b ready=%b op=%h addr=%h src=%h | D: valid=%b ready=%b op=%h data=%h src=%h",
                 $time, clk, rst_n,
                 dut.l1_stub.a_valid, dut.l1_stub.a_ready, dut.l1_stub.a_opcode, dut.l1_stub.a_address, dut.l1_stub.a_source, // L1 <-> Interconnect signals (using L1 stub view)
                 dut.l1_stub.d_valid, dut.l1_stub.d_ready, dut.l1_stub.d_opcode, dut.l1_stub.d_data, dut.l1_stub.d_source);
    end
    */

endmodule 