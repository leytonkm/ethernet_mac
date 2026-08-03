`timescale 1ns / 1ps

module mock_dp83848 #(
    parameter logic [4:0] PHY_ADDR       = 5'b00001,
    parameter real        T_MDIO_OUT_NS  = 20.0
)(
    input  logic enabled,
    input  logic mdc,
    inout  wire  mdio
);

    logic [15:0] regs [0:31];

    logic drive;
    logic drive_val;

    assign mdio = (enabled && drive) ? drive_val : 1'bz;

    int frames_seen;
    int frames_for_me;

    initial begin
        drive         = 1'b0;
        drive_val     = 1'b0;
        frames_seen   = 0;
        frames_for_me = 0;
        for (int i = 0; i < 32; i++) regs[i] = 16'h0000;
        regs[0]  = 16'h3100;
        regs[1]  = 16'h7849;
        regs[2]  = 16'h2000;
        regs[3]  = 16'h5C90;
        regs[16] = 16'h0100;
    end

    logic [1:0]  op;
    logic [4:0]  phyad;
    logic [4:0]  regad;
    logic [15:0] wdata;
    int          ones;

    initial begin
        forever begin
            ones = 0;
            forever begin
                @(posedge mdc);
                if (mdio === 1'b1) begin
                    ones++;
                end else begin
                    if (ones >= 32) break;
                    ones = 0;
                end
            end

            @(posedge mdc);
            if (mdio !== 1'b1) continue;

            @(posedge mdc); op[1] = mdio;
            @(posedge mdc); op[0] = mdio;
            for (int i = 4; i >= 0; i--) begin @(posedge mdc); phyad[i] = mdio; end
            for (int i = 4; i >= 0; i--) begin @(posedge mdc); regad[i] = mdio; end

            frames_seen++;
            if (phyad !== PHY_ADDR) continue;
            frames_for_me++;

            if (op === 2'b10) begin
                @(posedge mdc);
                #(T_MDIO_OUT_NS) begin
                    drive     = 1'b1;
                    drive_val = 1'b0;
                end
                for (int i = 15; i >= 0; i--) begin
                    @(posedge mdc);
                    #(T_MDIO_OUT_NS) drive_val = regs[regad][i];
                end
                @(posedge mdc);
                #(T_MDIO_OUT_NS) drive = 1'b0;
            end else if (op === 2'b01) begin
                @(posedge mdc);
                @(posedge mdc);
                for (int i = 15; i >= 0; i--) begin @(posedge mdc); wdata[i] = mdio; end
                regs[regad] = wdata;
            end
        end
    end

endmodule
