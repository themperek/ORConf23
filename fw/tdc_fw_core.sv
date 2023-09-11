


`include "./extra/spi_sbus.v"
`include "./extra/spi_core.v"
`include "../src/basil-daq/basil/firmware/modules/utils/CG_MOD_pos.v"

`include "../src/basil-daq/basil/firmware/modules/utils/sbus_to_ip.v"
`include "../src/basil-daq/basil/firmware/modules/utils/cdc_pulse_sync.v"
`include "../src/basil-daq/basil/firmware/modules/utils/cdc_syncfifo.v"

`include "./extra/pulse_gen_sbus.v"
`include "../src/basil-daq/basil/firmware/modules/pulse_gen/pulse_gen_core.v"
`include "../src/basil-daq/basil/firmware/modules/utils/3_stage_synchronizer.v"

`include "./extra/seq_gen_sbus.v"
`include "../src/basil-daq/basil/firmware/modules/seq_gen/seq_gen_core.v"
`include "../src/basil-daq/basil/firmware/modules/utils/ramb_8_to_n.v"

`include "./extra/bram_fifo_sbus.v"
`include "../src/basil-daq/basil/firmware/modules/bram_fifo/bram_fifo_core.v"

`include "./tdc_rx/tdc_rx_sbus.v"
`include "./tdc_rx/tdc_rx_core.v"
`include "../src/basil-daq/basil/firmware/modules/utils/generic_fifo.v"
`include "./tdc_rx/decode_8b10b.v"
`include "./tdc_rx/rec_sync.v"
`include "./tdc_rx/receiver_logic.v"
`include "../src/basil-daq/basil/firmware/modules/utils/flag_domain_crossing.v"
`include "../src/basil-daq/basil/firmware/modules/utils/cdc_reset_sync.v"

module tdc_fw_core (
    input wire BUS_CLK,

    input  wire        BUS_RST,
    input  wire [31:0] BUS_ADD,
    input  wire [ 7:0] BUS_DATA_IN,
    output wire [31:0] BUS_DATA_OUT,
    input  wire        BUS_RD,
    input  wire        BUS_WR,
    output wire        BUS_BYTE_ACCESS,

    input  wire SPI_CLK,
    output wire SCLK,
    input  wire SDO,
    output wire SDI,
    output wire SLD,

    output wire TS_RESET,

    input wire RX_CLK,
    input wire RX_DATA_CLK,

    output wire SIGNAL,
    input  wire RX_DATA
);

    /* -------  MODULE ADREESSES  ------- */
    localparam SPI_BASEADDR = 32'h3000;
    localparam SPI_HIGHADDR = 32'h4000 - 1;

    localparam RX_BASEADDR = 32'h4000;
    localparam RX_HIGHADDR = 32'h5000 - 1;

    localparam PULSE_BASEADDR = 32'h5000;
    localparam PULSE_HIGHADDR = 32'h6000 - 1;

    localparam SEQ_GEN_BASEADDR = 32'h6000;
    localparam SEQ_GEN_HIGHADDR = 32'h7000 - 1;

    localparam FIFO_BASEADDR = 32'h8000;
    localparam FIFO_HIGHADDR = 32'h9000 - 1;

    localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
    localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;

    assign BUS_BYTE_ACCESS = (BUS_ADD < 32'h8000_0000) ? 1'b1 : 1'b0;

    wire [31:0] BRAM_FIFO_DATA_OUT;
    wire [7:0] SPI_DATA_OUT, PULSE_GEN_DATA_OUT, SEQ_GEN_DATA_OUT, TDC_RX_DATA_OUT;
    assign BUS_DATA_OUT = {24'b0, {SPI_DATA_OUT | PULSE_GEN_DATA_OUT | SEQ_GEN_DATA_OUT | TDC_RX_DATA_OUT }} | BRAM_FIFO_DATA_OUT ;

    //------- MODULES   ------- //
    spi_sbus #(
        .BASEADDR (SPI_BASEADDR),
        .HIGHADDR (SPI_HIGHADDR),
        .ABUSWIDTH(32),
        .MEM_BYTES(16)
    ) spi (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN(BUS_DATA_IN[7:0]),
        .BUS_DATA_OUT(SPI_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .SPI_CLK  (SPI_CLK),
        .EXT_START(1'b0),

        .SCLK(SCLK),
        .SDI (SDI),
        .SDO (SDO),
        .SEN (),
        .SLD (SLD)
    );

    pulse_gen_sbus #(
        .BASEADDR (PULSE_BASEADDR),
        .HIGHADDR (PULSE_HIGHADDR),
        .ABUSWIDTH(32)
    ) rst_pulse_gen (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN(BUS_DATA_IN),
        .BUS_DATA_OUT(PULSE_GEN_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .PULSE_CLK(BUS_CLK),
        .EXT_START(1'b0),
        .PULSE(TS_RESET)
    );

    seq_gen_sbus #(
        .BASEADDR (SEQ_GEN_BASEADDR),
        .HIGHADDR (SEQ_GEN_HIGHADDR),
        .ABUSWIDTH(32),
        .MEM_BYTES(32),
        .OUT_BITS (1)
    ) signal_seq_gen (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN(BUS_DATA_IN),
        .BUS_DATA_OUT(SEQ_GEN_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .SEQ_EXT_START(TS_RESET),
        .SEQ_CLK(BUS_CLK),
        .SEQ_OUT(SIGNAL)
    );

    wire        FIFO_READY;
    wire        FIFO_EMPTY;
    wire [31:0] FIFO_DATA;
    wire        FIFO_FULL;

    tdc_rx_sbus #(
        .BASEADDR (RX_BASEADDR),
        .HIGHADDR (RX_HIGHADDR),
        .ABUSWIDTH(32)
    ) tdc_rx (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN(BUS_DATA_IN),
        .BUS_DATA_OUT(TDC_RX_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .RX_CLK  (RX_CLK),
        .DATA_CLK(RX_DATA_CLK),

        .RX_DATA(RX_DATA),

        .RX_READY(),
        .RX_8B10B_DECODER_ERR(),
        .RX_FIFO_OVERFLOW_ERR(),

        .FIFO_READ (FIFO_READY),
        .FIFO_EMPTY(FIFO_EMPTY),
        .FIFO_DATA (FIFO_DATA),

        .RX_FIFO_FULL(),
        .RX_ENABLED  ()
    );

    bram_fifo_sbus #(
        .BASEADDR(FIFO_BASEADDR),
        .HIGHADDR(FIFO_HIGHADDR),
        .BASEADDR_DATA(FIFO_BASEADDR_DATA),
        .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
        .ABUSWIDTH(32),
        .DEPTH(32'd64)
    ) bram_fifo (
        .BUS_CLK(BUS_CLK),
        .BUS_RST(BUS_RST),
        .BUS_ADD(BUS_ADD),
        .BUS_DATA_IN({24'b0, BUS_DATA_IN}),
        .BUS_DATA_OUT(BRAM_FIFO_DATA_OUT),
        .BUS_RD(BUS_RD),
        .BUS_WR(BUS_WR),

        .FIFO_READ_NEXT_OUT(FIFO_READY),
        .FIFO_EMPTY_IN(FIFO_EMPTY),
        .FIFO_DATA(FIFO_DATA),

        .FIFO_NOT_EMPTY(),
        .FIFO_FULL(FIFO_FULL),
        .FIFO_NEAR_FULL(),
        .FIFO_READ_ERROR()
    );

endmodule
