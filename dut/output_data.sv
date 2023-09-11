
`include  "encode_8b10b.v"
`include  "serializer.sv"

module output_data(  input wire reset, clk_ser, emptyFifo,
                     input wire [23:0] data,
                     output wire readFifo,
                     output wire clkReadFifo,
                     output wire out,
                     input wire sof
);

localparam NOP=2'b00, HEADER=2'b01 , DATA=2'b10, DATA_NEXT=2'b11;
reg [1:0] state, next_state; 

wire clk_byte;

assign clkReadFifo = clk_byte;

reg [1:0] byte_sel;

always@(posedge clk_byte) begin
 if(reset)
     state <= NOP;
  else
     state <= next_state;
end

always@(*) begin : set_next_state
    next_state = state; //default
    
    case (state)
        NOP:
            if(emptyFifo == 0)
               next_state =  HEADER;
        HEADER:
                next_state =  DATA;
        DATA:
            if(byte_sel == 2)
                next_state = DATA_NEXT;
        DATA_NEXT:
            if(emptyFifo == 1)
                next_state = NOP;
            else if(sof) begin
                next_state = HEADER;
            end
            else
                next_state = DATA;
    endcase
end

assign readFifo = ((state == DATA && byte_sel == 2));

always@(posedge clk_byte)
if(state == HEADER || byte_sel == 2 || reset)
    byte_sel <= 2'b00;
else
    byte_sel <= byte_sel + 1'b1;

reg [7:0]  encoder_data_data;
reg encoder_data_K;
reg encoder_data_dispin;
wire encoder_data_dispout;

reg [7:0] rawDataOut;

wire [7:0] dataByte [2:0];
assign dataByte[2] = data[7:0]; 
assign dataByte[1] = data[15:8]; 
assign dataByte[0] = data[23:16]; 

wire trailer;
assign trailer = (emptyFifo | sof);

always@(*) 
begin 
    if(state == HEADER)
        encoder_data_data = 8'b111_11100;//K.28.7 8'hfc
    else if(state == DATA)
        encoder_data_data = dataByte[byte_sel];
    else if(state == DATA_NEXT ) begin 
        if(trailer)
            encoder_data_data = 8'b101_11100;//K.28.5 TRAILER //8'hbc
        else
            encoder_data_data = dataByte[byte_sel];
    end
    else 
        encoder_data_data = 8'b001_11100;//K.28.1 NOP 00111100 //8'h3c
end

always@(*) 
begin        
    if( state == DATA || (state == DATA_NEXT && !trailer) )  begin
        encoder_data_K = 0;
        rawDataOut = dataByte[byte_sel];
    end
    else begin
        encoder_data_K = 1;
        rawDataOut = 8'b0;
    end
end

always @(posedge clk_byte)
if(reset)
    encoder_data_dispin <= 1'b0;
else
    encoder_data_dispin <= encoder_data_dispout;

wire [9:0] enc8b10bData;
encode_8b10b enc_8b10b( .datain(encoder_data_data), .k(encoder_data_K), 
                        .dispin(encoder_data_dispin), .dataout(enc8b10bData), 
                        .dispout(encoder_data_dispout));

wire load;

reg [9:0] dataToSerBuff;

integer i;
always@(posedge clk_byte) begin
    for (i=0; i<10; i=i+1)
        dataToSerBuff[(10-1)-i] <= enc8b10bData[i];
end

ser_div ser_div(.clk(clk_ser) , .out(clk_byte), .load(load));
serializer serializer (.clk(clk_ser), .load(load), .in(dataToSerBuff), .out(out));

endmodule