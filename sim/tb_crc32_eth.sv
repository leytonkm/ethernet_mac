`timescale 1ns / 1ps

module tb_crc32_eth;

    localparam logic [31:0] RESIDUE = 32'h2144DF1C;

    logic        clk = 1'b0;
    logic        rst_n;
    logic        init;
    logic        en;
    logic  [7:0] data;
    wire  [31:0] fcs;

    always #5 clk = ~clk;

    crc32_eth dut (
        .clk   (clk),
        .rst_n (rst_n),
        .init  (init),
        .en    (en),
        .data  (data),
        .fcs   (fcs)
    );

    int errors = 0;

    byte unsigned msg [$];
    byte unsigned frm [$];

    task automatic run_crc(input byte unsigned b [$], output logic [31:0] result);
        @(posedge clk);
        init <= 1'b1;
        en   <= 1'b0;
        @(posedge clk);
        init <= 1'b0;
        for (int i = 0; i < b.size(); i++) begin
            en   <= 1'b1;
            data <= b[i];
            @(posedge clk);
        end
        en <= 1'b0;
        @(posedge clk);
        result = fcs;
    endtask

    task automatic check(input string name, input byte unsigned b [$], input logic [31:0] exp);
        logic [31:0] got;
        run_crc(b, got);
        if (got === exp) begin
            $display("[PASS] %-38s fcs=0x%08h", name, got);
        end else begin
            $display("[FAIL] %-38s fcs=0x%08h expected=0x%08h", name, got, exp);
            errors++;
        end
    endtask

    task automatic append_fcs(ref byte unsigned b [$], input logic [31:0] f);
        b.push_back(f[7:0]);
        b.push_back(f[15:8]);
        b.push_back(f[23:16]);
        b.push_back(f[31:24]);
    endtask

    logic [31:0] frame_fcs;

    initial begin
        rst_n = 1'b0;
        init  = 1'b0;
        en    = 1'b0;
        data  = 8'h00;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("=== crc32_eth ===");

        msg.delete();
        check("empty message", msg, 32'h00000000);

        msg.delete();
        for (int i = 0; i < 9; i++) msg.push_back(8'h31 + i[7:0]);
        check("canonical check \"123456789\"", msg, 32'hCBF43926);

        frm.delete();
        for (int i = 0; i < 6; i++) frm.push_back(8'hFF);
        frm.push_back(8'h02);
        for (int i = 0; i < 4; i++) frm.push_back(8'h00);
        frm.push_back(8'h01);
        frm.push_back(8'h88);
        frm.push_back(8'hB5);
        for (int i = 0; i < 46; i++) frm.push_back(i[7:0]);

        if (frm.size() != 60) begin
            $display("[FAIL] test frame is %0d bytes, expected 60", frm.size());
            errors++;
        end else begin
            $display("[PASS] %-38s %0d", "test frame length", frm.size());
        end

        check("60-byte broadcast test frame", frm, 32'hF88C2AEA);

        run_crc(frm, frame_fcs);
        append_fcs(frm, frame_fcs);
        check("frame+FCS residue", frm, RESIDUE);

        $display("=== %0d error(s) ===", errors);
        if (errors == 0) $display("TEST PASSED");
        else             $display("*** TEST FAILED ***");
        $finish;
    end

    initial begin
        #200_000;
        $display("[FAIL] testbench timeout");
        $display("*** TEST FAILED ***");
        $finish;
    end

endmodule
