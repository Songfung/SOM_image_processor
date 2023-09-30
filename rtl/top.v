//`include "LFSR.v"
`include "../rtl/VEP.v"
`include "../rtl/WSC.v"
`include "../rtl/controller.v"

module top(
  input          clk,
  input          rst,
  input  [ 1:0]  mode,
  input  [23:0]  RAM_IF_Q,
  input  [23:0]  RAM_W_Q,
  input  [23:0]  RAM_PIC_Q,
  output         RAM_IF_OE,
  output         RAM_IF_WE,
  output [17:0]  RAM_IF_A,
  output [23:0]  RAM_IF_D,
  output         RAM_W_OE,
  output         RAM_W_WE,
  output [17:0]  RAM_W_A,
  output [23:0]  RAM_W_D,
  output         RAM_PIC_OE,
  output         RAM_PIC_WE,
  output [17:0]  RAM_PIC_A,
  output [23:0]  RAM_PIC_D,
  output         done
);


parameter
  sIdle = 3'd0,
  sFind_winner_train = 3'd1,
  sUpdate_W = 3'd2,
  sFind_winner_call = 3'd3,
  sWrite_pic = 3'd4,
  sWrite_W = 3'd5,
  sFinish = 3'd6;

//WSC ouput
wire [2:0] top_winner_x;
wire [2:0] top_winner_y;
//wire top_winner_OutValid;

//reg weight_update[63:0];
//wire [12:0] counter;

integer i2;
genvar i1;
genvar i3;
genvar i10;
//reg finish;
wire [10*64 - 1:0] total_distance;
wire [9:0] VEP_distance [63:0];

wire [24*64 -1:0] total_weight;
wire [23:0] VEP_weight [63:0];

wire [2:0] current_state;
//wire weight_update_top ;



controller controller1(
    .clk  (clk),
    .rst(rst),
    .mode(mode),
    .weight(total_weight),//!from VEP
    .winner_VEP_x(top_winner_x), //from WSC
    .winner_VEP_y(top_winner_y), //from WSC
    .current_state(current_state) , // state  from controller
    //.counter(counter), // from top	 
    .RAM_IF_OE(RAM_IF_OE),
    .RAM_IF_WE(RAM_IF_WE),
    .RAM_IF_A(RAM_IF_A),
    .RAM_IF_D(RAM_IF_D),
    .RAM_W_OE(RAM_W_OE),
    .RAM_W_WE(RAM_W_WE),
    .RAM_W_A(RAM_W_A),
    .RAM_W_D(RAM_W_D),
    .RAM_PIC_OE(RAM_PIC_OE),
    .RAM_PIC_WE(RAM_PIC_WE),
    .RAM_PIC_A(RAM_PIC_A),
    .RAM_PIC_D(RAM_PIC_D),
    //.weight_update(weight_update_top), //! when updateW
    .done(done)
);

WSC WSC1(
	//.clk(clk),
	//.rst(rst),
	.VEPs_manhattan_distance(total_distance),
	.winner_x(top_winner_x),
	.winner_y(top_winner_y)
	 ///.winner_OutValid(top_winner_OutValid)
);



generate
	for(i1=0; i1<64; i1=i1+1)begin : VEPs
		VEP VEP(
		.clk	(clk),
		.rst	(rst),
    		.VEP_x(i1[2:0]),
    		.VEP_y(i1[5:3]),
    		.winner_VEP_x(top_winner_x),
    		.winner_VEP_y(top_winner_y),
		.pixel	(RAM_IF_Q),
		//.weight_initial	(RAM_W_Q),
		.state(current_state),
    		.weight(VEP_weight[i1]),
		.manhattan_distance	(VEP_distance[i1])
		);
	end
endgenerate

generate
	for(i3=0; i3<64; i3=i3+1)begin : totalwire
		assign total_distance[(10*i3)+:10] = VEP_distance[i3];
	end
endgenerate

generate
	for(i10=0; i10<64; i10=i10+1)begin : weightwire
		assign total_weight[(24*i10)+:24] = VEP_weight[i10];
	end
endgenerate



endmodule
