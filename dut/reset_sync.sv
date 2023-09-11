module reset_sync (
    output reg rst,
    input wire clk, reset_b
);
  reg rff1;
  
  always @(posedge clk or negedge reset_b)
    if (!reset_b) {rst, rff1} <= 2'b11;
    else {rst, rff1} <= {rff1, 1'b0};

endmodule
