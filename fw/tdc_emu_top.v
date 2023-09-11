
`include "./uart_bridge/dbg_bridge_uart.v"
`include "./uart_bridge/dbg_bridge_fifo.v"
`include "./uart_bridge/dbg_bridge.v"

`include "../src/basil-daq/basil/firmware/modules/utils/clock_divider.v"

`include "tdc_fw_core.sv"
`include "../dut/tdc_top.sv"

module tdc_emu_top (
    input  wire      clk,

    input   wire    uart_rxd,
    output  wire    uart_txd
);

    wire clk_bufg;

    IBUF clk_ibufg_inst (
        .I(clk),
        .O(clk_bufg)
    );

    wire clk_pll_fb;
    wire clk0_pll, clk1_pll;
    wire pll_locked;

    PLLE2_ADV #(
        .CLKFBOUT_MULT(14),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DIVIDE(49),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.01),
        .STARTUP_WAIT("FALSE")
    ) PLL (
        .CLKFBIN (clk_pll_fb),
        .CLKIN1  (clk_bufg),
        .CLKFBOUT(clk_pll_fb),
        .CLKOUT0 (clk0_pll),
        .CLKOUT1 (),
        .CLKOUT2 (),
        .CLKOUT3 (),
        .CLKOUT4 (),
        .LOCKED  (pll_locked)
    );


    wire clock;
    BUFG clk0_pll_buf_inst (
        .I(clk0_pll),
        .O(clock)
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

    // wire RX_DATA_CLK;
    // BUFG clk1_pll_buf_inst (
    //     .I(clk_div10),
    //     .O(RX_DATA_CLK)
    // );

    wire reset;
    assign reset = !pll_locked;

    // 115200 x 4 = 460800
    // 100MHz *14 /49 => 28_571_428.57 / 62 => 460829.4931

    reg uart_rx;
    always @(posedge clock) begin
        uart_rx <= uart_rxd;
    end

    localparam CLK_FREQ = 28571428;
    localparam UART_SPEED = 115200;

    wire [31:0] BUS_ADD;
    wire BUS_RD, BUS_WR;
    wire [7:0] BUS_DATA_IN;
    wire [31:0] BUS_DATA_OUT;
    wire BUS_BYTE_ACCESS;

    dbg_bridge #(
        .CLK_FREQ  (CLK_FREQ),
        .UART_SPEED(UART_SPEED)
    ) dbg_bridge (
        // Inputs
        .clk_i(clock),
        .rst_i(reset),

        .uart_rxd_i(uart_rx),
        .uart_txd_o(uart_txd),

        .BUS_WR (BUS_WR),
        .BUS_RD (BUS_RD),
        .BUS_ADD(BUS_ADD),

        .BUS_DATA_IN (BUS_DATA_IN),
        .BUS_DATA_OUT(BUS_DATA_OUT),
        .BUS_BYTE_ACCESS(BUS_BYTE_ACCESS)
    );

    wire BUS_CLK;
    wire BUS_RST;

    assign BUS_CLK = clock;
    assign BUS_RST = reset;

    wire TS_RESET;
    wire SIGNAL;
    wire RX_DATA;

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
        .SIGNAL(SIGNAL),

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

endmodule
