`include "spi_core_conf.sv"
`include "output_data.sv"
`include "reset_sync.sv"

module tdc_top (


    input wire RESETB,  // async, active low

    input  wire SCLK,
    output wire SDO,
    input  wire SDI,

    input wire CLK,
    input wire TS_RESET,
    input wire SIGNAL,

    output wire DATA_OUT
);

    wire [7:0] conf;
    spi_core_conf spi_core_conf (
        .RESETB(RESETB),
        .SCLK(SCLK),
        .SDO(SDO),
        .SDI(SDI),
        .OUT(conf)
    );

    wire conf_en;
    assign conf_en = conf[0];

    wire reset_sys;
    reset_sync reset_sync (
        .clk(CLK),
        .reset_b(RESETB),
        .rst(reset_sys)
    );

    reg [15:0] bx_cnt;
    always @(posedge CLK) begin
        if (TS_RESET | reset_sys) bx_cnt <= 0;
        else bx_cnt <= bx_cnt + 1;
    end

    reg [1:0] signal_sample;
    always @(posedge CLK) begin
        if (TS_RESET | reset_sys) signal_sample <= 0;
        else signal_sample <= {signal_sample[0], SIGNAL & conf_en};
    end

    wire signal_start, signal_stop;
    assign signal_start = signal_sample[1:0] == 2'b01;
    assign signal_stop  = signal_sample[1:0] == 2'b10;

    reg [15:0] bx_start_store;

    always @(posedge CLK) begin
        if (signal_start) bx_start_store <= bx_cnt;
    end

    reg [7:0] tot_cnt;
    always @(posedge CLK) begin
        if (signal_start) tot_cnt <= 0;
        else if (signal_sample[0] & tot_cnt != 8'hff) tot_cnt <= tot_cnt + 1;
    end

    wire clk_data;

    wire fifo_read;
    wire fifo_full;  //TODO : also send out
    wire fifo_empty;
    wire [23:0] fifo_data;

    cdc_syncfifo #(
        .DSIZE(24),
        .ASIZE(4)
    ) fifo (
        .rdata (fifo_data),
        .wfull (fifo_full),
        .rempty(fifo_empty),
        .wdata ({bx_start_store, tot_cnt}),
        .winc  (signal_stop),
        .wclk  (CLK),
        .wrst  (reset_sys),
        .rinc  (fifo_read),
        .rclk  (clk_data),
        .rrst  (reset_sys)
    );

    output_data output_data (
        .reset(reset_sys),
        .clk_ser(CLK),
        .emptyFifo(fifo_empty),
        .data(fifo_data),
        .readFifo(fifo_read),
        .clkReadFifo(clk_data),
        .out(DATA_OUT),
        .sof(1'b0)
    );

endmodule

