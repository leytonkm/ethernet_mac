`timescale 1ns / 1ps

module mdio_master #(
    parameter int         CLK_FREQ_HZ = 25_000_000,
    parameter int         MDC_FREQ_HZ = 2_500_000,
    parameter logic [4:0] PHY_ADDR    = 5'b00001
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic        we,
    input  logic  [4:0] reg_addr,
    input  logic [15:0] wdata,

    output logic        busy,
    output logic        done,
    output logic [15:0] rdata,

    output logic        mdc,
    output logic        mdio_o,
    output logic        mdio_t,
    input  logic        mdio_i,

    output logic  [5:0] dbg_bit_idx,
    output logic  [1:0] dbg_state
);

    localparam int HALF_CYCLES = CLK_FREQ_HZ / (2 * MDC_FREQ_HZ);
    localparam int DIV_W       = (HALF_CYCLES < 2) ? 1 : $clog2(HALF_CYCLES);

    localparam logic [1:0] ST       = 2'b01;
    localparam logic [1:0] OP_READ  = 2'b10;
    localparam logic [1:0] OP_WRITE = 2'b01;
    localparam logic [1:0] TA_WRITE = 2'b10;
    localparam logic [1:0] TA_READ  = 2'b00;

    localparam int PREAMBLE_BITS = 33;
    localparam int OE_LAST_BIT   = 13;
    localparam int DATA_FIRST    = 15;
    localparam int DATA_LAST     = 30;
    localparam int FRAME_LAST    = 31;

    logic [DIV_W-1:0] div_cnt;
    logic             mdc_r;
    logic             mdc_falling;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= '0;
            mdc_r   <= 1'b0;
        end else if (div_cnt == DIV_W'(HALF_CYCLES - 1)) begin
            div_cnt <= '0;
            mdc_r   <= ~mdc_r;
        end else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end

    assign mdc         = mdc_r;
    assign mdc_falling = mdc_r && (div_cnt == DIV_W'(HALF_CYCLES - 1));

    logic mdio_i_meta, mdio_i_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdio_i_meta <= 1'b1;
            mdio_i_sync <= 1'b1;
        end else begin
            mdio_i_meta <= mdio_i;
            mdio_i_sync <= mdio_i_meta;
        end
    end

    typedef enum logic [1:0] {S_IDLE, S_PREAMBLE, S_XFER, S_DONE} state_t;
    state_t state;

    logic [5:0]  bit_idx;
    logic [5:0]  next_bit;
    logic [31:0] frame;
    logic        drive_en;
    logic        wr_mode;

    assign next_bit    = bit_idx + 6'd1;
    assign mdio_t      = ~drive_en;
    assign dbg_bit_idx = bit_idx;
    assign dbg_state   = state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            bit_idx  <= '0;
            frame    <= '0;
            drive_en <= 1'b0;
            wr_mode  <= 1'b0;
            mdio_o   <= 1'b1;
            busy     <= 1'b0;
            done     <= 1'b0;
            rdata    <= '0;
        end else begin
            done <= 1'b0;

            case (state)

                S_IDLE: if (start) begin
                    busy     <= 1'b1;
                    bit_idx  <= '0;
                    drive_en <= 1'b1;
                    mdio_o   <= 1'b1;
                    wr_mode  <= we;
                    frame    <= we ? {ST, OP_WRITE, PHY_ADDR, reg_addr, TA_WRITE, wdata}
                                   : {ST, OP_READ,  PHY_ADDR, reg_addr, TA_READ,  16'h0000};
                    state    <= S_PREAMBLE;
                end

                S_PREAMBLE: if (mdc_falling) begin
                    if (bit_idx == 6'(PREAMBLE_BITS - 1)) begin
                        bit_idx <= '0;
                        mdio_o  <= frame[FRAME_LAST];
                        state   <= S_XFER;
                    end else begin
                        bit_idx <= next_bit;
                    end
                end

                S_XFER: if (mdc_falling) begin
                    if (!wr_mode && bit_idx >= 6'(DATA_FIRST) && bit_idx <= 6'(DATA_LAST)) begin
                        rdata <= {rdata[14:0], mdio_i_sync};
                    end

                    if (bit_idx == 6'(FRAME_LAST)) begin
                        drive_en <= 1'b0;
                        state    <= S_DONE;
                    end else begin
                        bit_idx  <= next_bit;
                        mdio_o   <= frame[FRAME_LAST - next_bit];
                        drive_en <= wr_mode || (next_bit <= 6'(OE_LAST_BIT));
                    end
                end

                S_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule
