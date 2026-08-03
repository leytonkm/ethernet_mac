`timescale 1ns / 1ps

module crc32_eth (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        init,
    input  logic        en,
    input  logic  [7:0] data,

    output logic [31:0] fcs
);

    localparam logic [31:0] POLY    = 32'hEDB88320;
    localparam logic [31:0] INIT_V  = 32'hFFFFFFFF;
    localparam logic [31:0] XOR_OUT = 32'hFFFFFFFF;

    logic [31:0] crc;

    function automatic logic [31:0] next_crc(input logic [31:0] c, input logic [7:0] d);
        logic [31:0] r;
        r = c;
        for (int i = 0; i < 8; i++) begin
            if (r[0] ^ d[i]) r = (r >> 1) ^ POLY;
            else             r = (r >> 1);
        end
        return r;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)    crc <= INIT_V;
        else if (init) crc <= INIT_V;
        else if (en)   crc <= next_crc(crc, data);
    end

    assign fcs = crc ^ XOR_OUT;

endmodule
