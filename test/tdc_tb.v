
`timescale 1ps / 1ps

`include "fw/tdc_fw_core.sv"
`include "dut/tdc_top.sv"

`include "../src/basil-daq/basil/firmware/modules/utils/clock_divider.v"

module tb (
    input  wire        BUS_CLK,
    input  wire        BUS_RST,
    input  wire [31:0] BUS_ADD,
    input  wire [ 7:0] BUS_DATA_IN,
    output wire [31:0] BUS_DATA_OUT,
    input  wire        BUS_RD,
    input  wire        BUS_WR,
    output wire        BUS_BYTE_ACCESS
);

    wire RX_DATA_CLK;
    clock_divider #(
        .DIVISOR(10)
    ) clock_divisor_rx_data (
        .CLK(BUS_CLK),
        .RESET(1'b0),
        .CE(),
        .CLOCK(RX_DATA_CLK)
    );

    wire TS_RESET, SIGNAL, RX_DATA;

    wire SCLK, SDO, SDI, SLD;

    tdc_fw_core tdc_fw_core (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN(BUS_DATA_IN),
        .BUS_DATA_OUT(BUS_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),
        .BUS_BYTE_ACCESS(BUS_BYTE_ACCESS),

        .SPI_CLK(RX_DATA_CLK),
        .SCLK(SCLK), 
        .SDO(SDO), 
        .SDI(SDI), 
        .SLD(SLD),

        .TS_RESET(TS_RESET),
        .SIGNAL  (SIGNAL),

        .RX_CLK(BUS_CLK),
        .RX_DATA_CLK(RX_DATA_CLK),

        .RX_DATA(RX_DATA)
    );

    tdc_top tdc_top (
        .CLK(BUS_CLK),
        .RESETB(!BUS_RST),
        .TS_RESET(TS_RESET),
        .SIGNAL(SIGNAL),

        .SCLK(SCLK),
        .SDO(SDO),
        .SDI(SDI),

        .DATA_OUT(RX_DATA)
    );



// `ifdef WAVES
    initial begin
        $dumpfile("/tmp/tdc.vcd");
        $dumpvars(0);
    end
// `endif

endmodule
