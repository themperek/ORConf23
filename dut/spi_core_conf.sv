
module spi_core_conf (
    input wire RESETB,

    input  wire SCLK,
    output wire SDO,
    input  wire SDI,

    output reg [7:0] OUT
);

    always @(posedge SCLK or negedge RESETB) begin
        if (~RESETB) OUT <= 8'h00;
        else OUT[7:0] <= {OUT[6:0], SDI};
    end

    assign SDO = OUT[7];

endmodule
