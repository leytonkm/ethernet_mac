`timescale 1ns / 1ps

module phy_link_mgr #(
    parameter logic [4:0] BRINGUP_REG_ADDR = 5'b00010,
    parameter int         POLL_CYCLES      = 250_000
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        phy_ready,

    output logic        mdio_start,
    output logic        mdio_we,
    output logic  [4:0] mdio_reg_addr,
    output logic [15:0] mdio_wdata,
    input  logic        mdio_busy,
    input  logic        mdio_done,
    input  logic [15:0] mdio_rdata,

    output logic        bringup_done,
    output logic [15:0] bringup_rdata,
    output logic        link_up
);

    localparam int POLL_W = $clog2(POLL_CYCLES + 1);

    typedef enum logic [1:0] {
        S_WAIT_READY,
        S_ISSUE_START,
        S_WAIT_DONE,
        S_POLL_WAIT
    } state_t;

    state_t            state;
    logic [POLL_W-1:0] poll_cnt;

    assign mdio_reg_addr = BRINGUP_REG_ADDR;
    assign mdio_we       = 1'b0;
    assign mdio_wdata    = 16'h0000;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_WAIT_READY;
            poll_cnt      <= '0;
            mdio_start    <= 1'b0;
            bringup_done  <= 1'b0;
            bringup_rdata <= '0;
            link_up       <= 1'b0;
        end else begin
            mdio_start   <= 1'b0;
            bringup_done <= 1'b0;

            case (state)

                S_WAIT_READY: begin
                    if (phy_ready) begin
                        state <= S_ISSUE_START;
                    end
                end

                S_ISSUE_START: begin
                    if (!mdio_busy) begin
                        mdio_start <= 1'b1;
                        state      <= S_WAIT_DONE;
                    end
                end

                S_WAIT_DONE: begin
                    if (mdio_done) begin
                        bringup_rdata <= mdio_rdata;
                        bringup_done  <= 1'b1;
                        poll_cnt      <= '0;
                        state         <= S_POLL_WAIT;
                    end
                end

                S_POLL_WAIT: begin
                    if (poll_cnt == POLL_W'(POLL_CYCLES - 1)) begin
                        state <= S_ISSUE_START;
                    end else begin
                        poll_cnt <= poll_cnt + 1'b1;
                    end
                end

            endcase
        end
    end

endmodule
