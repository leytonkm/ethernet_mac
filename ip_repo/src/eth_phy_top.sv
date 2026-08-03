`timescale 1ns / 1ps

module eth_phy_bringup_top #(
    parameter int         CLK_FREQ_HZ        = 25_000_000,
    parameter int         MDC_FREQ_HZ        = 2_500_000,
    parameter logic [4:0] PHY_ADDR           = 5'b00001,
    parameter logic [4:0] BRINGUP_REG_ADDR   = 5'b00010,
    parameter int         RESET_LOW_CYCLES   = 250,
    parameter int         STABLE_WAIT_CYCLES = 4_175_000,
    parameter int         POLL_CYCLES        = 250_000
)(
    input  logic        clk,
    input  logic        rst_n,

    output logic        eth_rstn,
    output logic        eth_mdc,
    inout  wire         eth_mdio,

    output logic        bringup_done,
    output logic [15:0] bringup_rdata,
    output logic        link_up,
    output logic [15:0] dbg
);

    logic        phy_ready;

    logic        mdio_start;
    logic        mdio_we;
    logic  [4:0] mdio_reg_addr;
    logic [15:0] mdio_wdata;
    logic        mdio_busy;
    logic        mdio_done;
    logic [15:0] mdio_rdata;

    logic        mdio_o;
    logic        mdio_t;
    logic        mdio_i;

    logic  [5:0] dbg_bit_idx;
    logic  [1:0] dbg_state;

    reset_sequencer #(
        .RESET_LOW_CYCLES   (RESET_LOW_CYCLES),
        .STABLE_WAIT_CYCLES (STABLE_WAIT_CYCLES)
    ) u_reset_sequencer (
        .clk       (clk),
        .rst_n     (rst_n),
        .eth_rstn  (eth_rstn),
        .phy_ready (phy_ready)
    );

    mdio_master #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .MDC_FREQ_HZ (MDC_FREQ_HZ),
        .PHY_ADDR    (PHY_ADDR)
    ) u_mdio_master (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (mdio_start),
        .we          (mdio_we),
        .reg_addr    (mdio_reg_addr),
        .wdata       (mdio_wdata),
        .busy        (mdio_busy),
        .done        (mdio_done),
        .rdata       (mdio_rdata),
        .mdc         (eth_mdc),
        .mdio_o      (mdio_o),
        .mdio_t      (mdio_t),
        .mdio_i      (mdio_i),
        .dbg_bit_idx (dbg_bit_idx),
        .dbg_state   (dbg_state)
    );

    phy_link_mgr #(
        .BRINGUP_REG_ADDR (BRINGUP_REG_ADDR),
        .POLL_CYCLES      (POLL_CYCLES)
    ) u_phy_link_mgr (
        .clk           (clk),
        .rst_n         (rst_n),
        .phy_ready     (phy_ready),
        .mdio_start    (mdio_start),
        .mdio_we       (mdio_we),
        .mdio_reg_addr (mdio_reg_addr),
        .mdio_wdata    (mdio_wdata),
        .mdio_busy     (mdio_busy),
        .mdio_done     (mdio_done),
        .mdio_rdata    (mdio_rdata),
        .bringup_done  (bringup_done),
        .bringup_rdata (bringup_rdata),
        .link_up       (link_up)
    );

    IOBUF u_mdio_iobuf (
        .O  (mdio_i),
        .IO (eth_mdio),
        .I  (mdio_o),
        .T  (mdio_t)
    );

    assign dbg = {dbg_state,
                  dbg_bit_idx,
                  eth_mdc,
                  mdio_o,
                  mdio_t,
                  mdio_i,
                  mdio_busy,
                  mdio_done,
                  phy_ready,
                  eth_rstn};

endmodule
