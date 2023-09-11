
module ser_div(clk , out, load);

input wire clk;
output reg out; //output wire out;
output reg load;

reg [3:0] cnt;

initial cnt = 0;

always @(posedge clk)
  if(cnt == 9)
    cnt <= 4'b0000;
  else
    cnt <= cnt+1;

always @(posedge clk)
  out <= cnt[2]; 

wire load_cnt;
assign load_cnt = (cnt == 3);

always @(posedge clk)
  load <= load_cnt;

endmodule

module serializer(clk, load, in, out);
input wire clk, load;
input wire [9:0] in;
output wire out;

reg [9:0] shift;

always @(posedge clk)
if(load)
    shift <= in;
else
    shift <= {shift[8:0], 1'b0};

assign out = shift[9];

endmodule
