/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
`timescale 1ps/1ps
`default_nettype none

module tdc_rx_sbus #(
    parameter   BASEADDR = 32'h0000,
    parameter   HIGHADDR = 32'h0000,
    parameter   DSIZE = 10,
    parameter   DATA_IDENTIFIER = 0,
    parameter   ABUSWIDTH = 16
) (
    input wire RX_CLK,
    input wire DATA_CLK,
    input wire RX_DATA,
    output wire RX_READY,
    output wire RX_8B10B_DECODER_ERR,
    output wire RX_FIFO_OVERFLOW_ERR,

    input wire FIFO_READ,
    output wire FIFO_EMPTY,
    output wire [31:0] FIFO_DATA,

    output wire RX_FIFO_FULL,
    output wire RX_ENABLED,

    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [ABUSWIDTH-1:0]  BUS_ADD,
    input wire  [7:0]   BUS_DATA_IN,
    output wire [7:0]   BUS_DATA_OUT,
    input wire          BUS_RD,
    input wire          BUS_WR
);


wire IP_RD, IP_WR;
wire [ABUSWIDTH-1:0] IP_ADD;
wire [7:0] IP_DATA_IN;
wire [7:0] IP_DATA_OUT;

sbus_to_ip #(
    .BASEADDR(BASEADDR),
    .HIGHADDR(HIGHADDR),
    .ABUSWIDTH(ABUSWIDTH)
) sbus_to_ip (
    .BUS_CLK(BUS_CLK),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA_IN(BUS_DATA_IN),
    .BUS_DATA_OUT(BUS_DATA_OUT),

    .IP_RD(IP_RD),
    .IP_WR(IP_WR),
    .IP_ADD(IP_ADD),
    .IP_DATA_IN(IP_DATA_IN),
    .IP_DATA_OUT(IP_DATA_OUT)
);


tdc_rx_core #(
    .DSIZE(DSIZE),
    .DATA_IDENTIFIER(DATA_IDENTIFIER),
    .ABUSWIDTH(ABUSWIDTH)
) tdc_rx_core (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(IP_ADD),
    .BUS_DATA_IN(IP_DATA_IN),
    .BUS_RD(IP_RD),
    .BUS_WR(IP_WR),
    .BUS_DATA_OUT(IP_DATA_OUT),

    .RX_CLK(RX_CLK),
    .DATA_CLK(DATA_CLK),
    .RX_DATA(RX_DATA),
    .RX_READY(RX_READY),
    .RX_8B10B_DECODER_ERR(RX_8B10B_DECODER_ERR),
    .RX_FIFO_OVERFLOW_ERR(RX_FIFO_OVERFLOW_ERR),

    .FIFO_CLK(BUS_CLK),
    .FIFO_READ(FIFO_READ),
    .FIFO_EMPTY(FIFO_EMPTY),
    .FIFO_DATA(FIFO_DATA),

    .RX_FIFO_FULL(RX_FIFO_FULL),
    .RX_ENABLED(RX_ENABLED)
);

endmodule
