`timescale 1ns / 1ps

module reset_sequencer #(
    parameter int RESET_LOW_CYCLES   = 250,
    parameter int STABLE_WAIT_CYCLES = 4_175_000
)(
    input  logic clk,
    input  logic rst_n,

    output logic eth_rstn,
    output logic phy_ready
);

    localparam int CNT_W = $clog2(STABLE_WAIT_CYCLES + 1);

    typedef enum logic [1:0] {
        S_ASSERT_RESET,
        S_WAIT_STABLE,
        S_READY
    } state_t;

    state_t           state;
    logic [CNT_W-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_ASSERT_RESET;
            counter   <= '0;
            eth_rstn  <= 1'b0;
            phy_ready <= 1'b0;
        end else begin
            case (state)

                S_ASSERT_RESET: begin
                    eth_rstn  <= 1'b0;
                    phy_ready <= 1'b0;
                    if (counter == CNT_W'(RESET_LOW_CYCLES - 1)) begin
                        counter  <= '0;
                        eth_rstn <= 1'b1;
                        state    <= S_WAIT_STABLE;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                S_WAIT_STABLE: begin
                    if (counter == CNT_W'(STABLE_WAIT_CYCLES - 1)) begin
                        counter   <= '0;
                        phy_ready <= 1'b1;
                        state     <= S_READY;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                S_READY: begin
                    phy_ready <= 1'b1;
                end

                default: state <= S_ASSERT_RESET;

            endcase
        end
    end

endmodule
