//-----------------------------------------------------------------
//                     UART -> AXI Debug Bridge
//                              V1.0
//                        Ultra-Embedded.com
//                        Copyright 2017-2019
//
//                 Email: admin@ultra-embedded.com
//
//                       License: LGPL
//-----------------------------------------------------------------
//
// This source file may be used and distributed without         
// restriction provided that this copyright statement is not    
// removed from the file and that any derivative work contains  
// the original copyright notice and the associated disclaimer. 
//
// This source file is free software; you can redistribute it   
// and/or modify it under the terms of the GNU Lesser General   
// Public License as published by the Free Software Foundation; 
// either version 2.1 of the License, or (at your option) any   
// later version.
//
// This source is distributed in the hope that it will be       
// useful, but WITHOUT ANY WARRANTY; without even the implied   
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
// PURPOSE.  See the GNU Lesser General Public License for more 
// details.
//
// You should have received a copy of the GNU Lesser General    
// Public License along with this source; if not, write to the 
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
// Boston, MA  02111-1307  USA
//-----------------------------------------------------------------

//-----------------------------------------------------------------
//                          Generated File
//-----------------------------------------------------------------

module dbg_bridge
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter CLK_FREQ   = 28571428,
    parameter UART_SPEED = 115200
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(

    input clk_i,
    input rst_i,

    input  uart_rxd_i,
    output uart_txd_o,

    output wire        BUS_WR,
    output reg        BUS_RD,
    output wire [31:0] BUS_ADD,

    output wire [ 7:0] BUS_DATA_IN,
    input  wire [31:0] BUS_DATA_OUT,
    input              BUS_BYTE_ACCESS
);

    //-----------------------------------------------------------------
    // Defines
    //-----------------------------------------------------------------
    localparam REQ_WRITE = 8'h10;
    localparam REQ_READ = 8'h11;

    `define STATE_W 4
    `define STATE_R 3:0
    localparam STATE_IDLE = 4'd0;
    localparam STATE_LEN = 4'd2;
    localparam STATE_ADDR0 = 4'd3;
    localparam STATE_ADDR1 = 4'd4;
    localparam STATE_ADDR2 = 4'd5;
    localparam STATE_ADDR3 = 4'd6;
    localparam STATE_WRITE = 4'd7;
    localparam STATE_READ = 4'd8;

    //-----------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------
    wire        uart_wr_w;
    wire [ 7:0] uart_wr_data_w;
    wire        uart_wr_busy_w;

    wire        uart_rd_w;
    wire [ 7:0] uart_rd_data_w;
    wire        uart_rd_valid_w;

    wire        uart_rx_error_w;

    reg         tx_valid_w;
    reg [ 7:0] tx_data_w;
    wire        tx_accept_w;
    wire        read_skip_w;

    wire        rx_valid_w;
    wire [ 7:0] rx_data_w;
    wire        rx_accept_w;

    reg  [31:0] mem_addr_q;
    reg         mem_wr_q;

    reg  [ 7:0] len_q;

    //-----------------------------------------------------------------
    // UART core
    //-----------------------------------------------------------------
    dbg_bridge_uart #(
        .UART_DIVISOR_W(16)
    ) u_uart (
        .clk_i(clk_i),
        .rst_i(rst_i),

        // Control
        .bit_div_i((CLK_FREQ / UART_SPEED) - 1),
        .stop_bits_i(1'b0),  // 0 = 1, 1 = 2

        // Transmit
        .wr_i(uart_wr_w),
        .data_i(uart_wr_data_w),
        .tx_busy_o(uart_wr_busy_w),

        // Receive
        .rd_i(uart_rd_w),
        .data_o(uart_rd_data_w),
        .rx_ready_o(uart_rd_valid_w),

        .rx_err_o(uart_rx_error_w),

        // UART pins
        .rxd_i(uart_rxd_i),
        .txd_o(uart_txd_o)
    );

    //-----------------------------------------------------------------
    // Output FIFO
    //-----------------------------------------------------------------
    wire uart_tx_pop_w = ~uart_wr_busy_w;
    wire tx_almost_full_w;

    dbg_bridge_fifo #(
        .WIDTH (8),
        .DEPTH (8),
        .ADDR_W(3)
    ) u_fifo_tx (
        .clk_i(clk_i),
        .rst_i(rst_i),

        // In
        .push_i(tx_valid_w),
        .data_in_i(tx_data_w),
        .accept_o(tx_accept_w),
        .almost_full_o(tx_almost_full_w),

        // Out
        .pop_i(uart_tx_pop_w),
        .data_out_o(uart_wr_data_w),
        .valid_o(uart_wr_w)
    );

    //-----------------------------------------------------------------
    // Input FIFO
    //-----------------------------------------------------------------
    dbg_bridge_fifo #(
        .WIDTH (8),
        .DEPTH (8),
        .ADDR_W(3)
    ) u_fifo_rx (
        .clk_i(clk_i),
        .rst_i(rst_i),

        // In
        .push_i(uart_rd_valid_w),
        .data_in_i(uart_rd_data_w),
        .accept_o(uart_rd_w),

        // Out
        .pop_i(rx_accept_w),
        .data_out_o(rx_data_w),
        .valid_o(rx_valid_w)
    );

    //-----------------------------------------------------------------
    // States
    //-----------------------------------------------------------------
    reg [`STATE_R] state_q;
    reg [`STATE_R] next_state_r;

    always @* begin
        next_state_r = state_q;

        case (next_state_r)
            //-------------------------------------------------------------
            // IDLE:
            //-------------------------------------------------------------
            STATE_IDLE: begin
                if (rx_valid_w) begin
                    case (rx_data_w)
                        REQ_WRITE, REQ_READ: next_state_r = STATE_LEN;
                        default: ;
                    endcase
                end
            end
            //-----------------------------------------
            // STATE_LEN
            //-----------------------------------------
            STATE_LEN: begin
                if (rx_valid_w) next_state_r = STATE_ADDR0;
            end
            //-----------------------------------------
            // STATE_ADDR
            //-----------------------------------------
            STATE_ADDR0: if (rx_valid_w) next_state_r = STATE_ADDR1;
            STATE_ADDR1: if (rx_valid_w) next_state_r = STATE_ADDR2;
            STATE_ADDR2: if (rx_valid_w) next_state_r = STATE_ADDR3;
            STATE_ADDR3: begin
                if (rx_valid_w && mem_wr_q) next_state_r = STATE_WRITE;
                else if (rx_valid_w) next_state_r = STATE_READ;
            end
            //-----------------------------------------
            // STATE_WRITE
            //-----------------------------------------
            STATE_WRITE: begin
                if (len_q == 8'b0) next_state_r = STATE_IDLE;
                else next_state_r = STATE_WRITE;
            end
            //-----------------------------------------
            // STATE_READ
            //-----------------------------------------
            STATE_READ: begin
                if (len_q == 8'b0) next_state_r = STATE_IDLE;
                else next_state_r = STATE_READ;
            end
            default: ;
        endcase
    end

    // State storage
    always @(posedge clk_i or posedge rst_i)
        if (rst_i) state_q <= STATE_IDLE;
        else state_q <= next_state_r;


    //-----------------------------------------------------------------
    // Write enable
    //-----------------------------------------------------------------
    always @(posedge clk_i or posedge rst_i)
        if (rst_i) mem_wr_q <= 1'b0;
        else if (state_q == STATE_IDLE && rx_valid_w) mem_wr_q <= (rx_data_w == REQ_WRITE);


    //-----------------------------------------------------------------
    // RD/WR to and from UART
    //-----------------------------------------------------------------

    // Accept data in the following states
    assign rx_accept_w = (state_q == STATE_IDLE) |
                     (state_q == STATE_LEN) |
                     (state_q == STATE_ADDR0) |
                     (state_q == STATE_ADDR1) |
                     (state_q == STATE_ADDR2) |
                     (state_q == STATE_ADDR3) |
                     (state_q == STATE_WRITE);

    //-----------------------------------------------------------------
    // Capture length
    //-----------------------------------------------------------------
    always @(posedge clk_i or posedge rst_i)
        if (rst_i) len_q <= 8'd0;
        else if (state_q == STATE_LEN && rx_valid_w) len_q[7:0] <= rx_data_w;
        else if (state_q == STATE_WRITE && rx_valid_w) len_q <= len_q - 8'd1;
        else if (state_q == STATE_READ && !tx_almost_full_w) len_q <= len_q - 8'd1;

    //-----------------------------------------------------------------
    // Capture addr
    //-----------------------------------------------------------------
    always @(posedge clk_i or posedge rst_i)
        if (rst_i) mem_addr_q <= 'd0;
        else if (state_q == STATE_ADDR0 && rx_valid_w) mem_addr_q[31:24] <= rx_data_w;
        else if (state_q == STATE_ADDR1 && rx_valid_w) mem_addr_q[23:16] <= rx_data_w;
        else if (state_q == STATE_ADDR2 && rx_valid_w) mem_addr_q[15:8] <= rx_data_w;
        else if (state_q == STATE_ADDR3 && rx_valid_w) mem_addr_q[7:0] <= rx_data_w;
        // Address increment on every access issued
        else if (state_q == STATE_WRITE && rx_valid_w) mem_addr_q <= mem_addr_q + 'd1;
        else if (state_q == STATE_READ && !tx_almost_full_w) mem_addr_q <= mem_addr_q + 'd1;

    reg [31:0] data_bus_save;
    reg [31:0] data_addr_save;

    assign BUS_WR = (state_q == STATE_WRITE) & rx_valid_w;
    assign BUS_ADD = mem_addr_q;
    assign BUS_DATA_IN = rx_data_w;
    
    wire valid_add;
    assign valid_add = (state_q == STATE_READ) & !tx_almost_full_w & len_q != 0;

    always @* begin
        if(BUS_BYTE_ACCESS)
            BUS_RD = valid_add;
        else
            BUS_RD = valid_add & mem_addr_q[1:0]==0;
    end

    always @* begin
        if(BUS_BYTE_ACCESS)
            tx_data_w = BUS_DATA_OUT[7:0];
        else begin
            case (data_addr_save[1:0])
                2'b00 : tx_data_w =   BUS_DATA_OUT[7:0];
                2'b01 : tx_data_w =   data_bus_save[15:8];
                2'b10 : tx_data_w =   data_bus_save[23:16];
                2'b11 : tx_data_w =   data_bus_save[31:24];
            endcase
        end
    end

    always @(posedge clk_i or posedge rst_i)
        if (rst_i) tx_valid_w <= 0;
        else tx_valid_w <= valid_add;

    reg bus_rd_delay;
    always @(posedge clk_i or posedge rst_i)
        if (rst_i) bus_rd_delay <= 0;
        else bus_rd_delay <= BUS_RD;

    always @(posedge clk_i) if (bus_rd_delay) data_bus_save <= BUS_DATA_OUT;

    always @(posedge clk_i) if (valid_add) data_addr_save <= mem_addr_q;

endmodule
