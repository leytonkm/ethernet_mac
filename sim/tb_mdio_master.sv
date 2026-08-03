`timescale 1ns / 1ps

module tb_mdio_master;

    localparam int         CLK_FREQ_HZ = 25_000_000;
    localparam int         MDC_FREQ_HZ = 2_500_000;
    localparam logic [4:0] PHY_ADDR    = 5'b00001;

    localparam real CLK_HALF_NS = 20.0;
    localparam real T_SETUP_NS  = 10.0;
    localparam real T_HOLD_NS   = 10.0;

    localparam logic [1:0] ST_XFER = 2'd2;

    logic clk = 1'b0;
    logic rst_n;

    always #(CLK_HALF_NS) clk = ~clk;

    logic        start;
    logic        we;
    logic  [4:0] reg_addr;
    logic [15:0] wdata;

    wire         busy;
    wire         done;
    wire  [15:0] rdata;
    wire         mdc;
    wire         mdio_o;
    wire         mdio_t;
    wire   [5:0] dbg_bit_idx;
    wire   [1:0] dbg_state;

    wire mdio_bus;
    assign mdio_bus = mdio_t ? 1'bz : mdio_o;
    pullup pu_mdio (mdio_bus);

    logic phy_enabled;

    int  errors;
    bit  checks_en;
    bit  expect_read;

    mdio_master #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .MDC_FREQ_HZ (MDC_FREQ_HZ),
        .PHY_ADDR    (PHY_ADDR)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .we          (we),
        .reg_addr    (reg_addr),
        .wdata       (wdata),
        .busy        (busy),
        .done        (done),
        .rdata       (rdata),
        .mdc         (mdc),
        .mdio_o      (mdio_o),
        .mdio_t      (mdio_t),
        .mdio_i      (mdio_bus),
        .dbg_bit_idx (dbg_bit_idx),
        .dbg_state   (dbg_state)
    );

    mock_dp83848 #(
        .PHY_ADDR (PHY_ADDR)
    ) phy (
        .enabled (phy_enabled),
        .mdc     (mdc),
        .mdio    (mdio_bus)
    );

    realtime last_change = 0;
    logic    held;
    always @(mdio_bus) last_change = $realtime;

    always @(posedge mdc) begin
        if (checks_en && mdio_t === 1'b0) begin
            if (($realtime - last_change) < T_SETUP_NS) begin
                $display("[FAIL] MDIO setup violation at %0t ns (last change %0t ns)",
                         $realtime, last_change);
                errors++;
            end
        end
    end

    always @(posedge mdc) begin
        if (checks_en && mdio_t === 1'b0) begin
            held = mdio_bus;
            #(T_HOLD_NS);
            if (mdio_bus !== held) begin
                $display("[FAIL] MDIO hold violation at %0t ns", $realtime);
                errors++;
            end
        end
    end

    always @(posedge clk) begin
        if (checks_en && expect_read && dbg_state == ST_XFER &&
            dbg_bit_idx >= 6'd14 && mdio_t !== 1'b1) begin
            $display("[FAIL] bus not released during turnaround/data, bit_idx=%0d at %0t ns",
                     dbg_bit_idx, $realtime);
            errors++;
        end
    end

    task automatic check16(input string name, input logic [15:0] got, input logic [15:0] exp);
        if (got === exp) begin
            $display("[PASS] %-34s got=0x%04h", name, got);
        end else begin
            $display("[FAIL] %-34s got=0x%04h expected=0x%04h", name, got, exp);
            errors++;
        end
    endtask

    task automatic mdio_read(input logic [4:0] addr, output logic [15:0] data);
        @(posedge clk);
        reg_addr    <= addr;
        we          <= 1'b0;
        wdata       <= 16'h0000;
        start       <= 1'b1;
        expect_read <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        do @(posedge clk); while (done !== 1'b1);
        data        = rdata;
        expect_read <= 1'b0;
    endtask

    task automatic mdio_write(input logic [4:0] addr, input logic [15:0] val);
        @(posedge clk);
        reg_addr <= addr;
        we       <= 1'b1;
        wdata    <= val;
        start    <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        do @(posedge clk); while (done !== 1'b1);
    endtask

    logic [15:0] got;

    initial begin
        errors      = 0;
        checks_en   = 0;
        expect_read = 0;
        start       = 1'b0;
        we          = 1'b0;
        reg_addr    = 5'd0;
        wdata       = 16'h0000;
        phy_enabled = 1'b1;
        rst_n       = 1'b0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);
        checks_en = 1;

        $display("=== mdio_master vs mock DP83848 ===");

        mdio_read(5'h02, got);  check16("PHYIDR1 (reg 0x02)",            got, 16'h2000);
        mdio_read(5'h03, got);  check16("PHYIDR2 (reg 0x03)",            got, 16'h5C90);
        mdio_read(5'h01, got);  check16("BMSR (reg 0x01)",               got, 16'h7849);
        mdio_read(5'h00, got);  check16("BMCR (reg 0x00)",               got, 16'h3100);

        mdio_write(5'h00, 16'h1200);
        mdio_read(5'h00, got);  check16("BMCR after write 0x1200",       got, 16'h1200);

        phy_enabled = 1'b0;
        mdio_read(5'h02, got);  check16("absent PHY reads all ones",     got, 16'hFFFF);

        phy_enabled = 1'b1;
        mdio_read(5'h02, got);  check16("PHYIDR1 after PHY returns",     got, 16'h2000);

        if (phy.frames_for_me != 7) begin
            $display("[FAIL] mock PHY decoded %0d frames addressed to it, expected 7",
                     phy.frames_for_me);
            errors++;
        end else begin
            $display("[PASS] %-34s %0d", "frames decoded by mock PHY", phy.frames_for_me);
        end

        $display("=== %0d error(s) ===", errors);
        if (errors == 0) $display("*** TEST PASSED ***");
        else             $display("*** TEST FAILED ***");
        $finish;
    end

    initial begin
        #2_000_000;
        $display("[FAIL] testbench timeout");
        $display("*** TEST FAILED ***");
        $finish;
    end

endmodule
