`include "../rtl/smaller_mux.v"
module WSC(
  input  [10*64 - 1:0] VEPs_manhattan_distance,//{VEP63.manhattan_distance, VEP62.manhattan_distance, ... , VEP0.manhattan_distance}
  output [2:0] winner_x,
  output [2:0] winner_y
);

wire [5:0] winner_tag;
//wire [9:0] min1;

assign winner_y = winner_tag[5:3];
assign winner_x = winner_tag[2:0];
wire [9:0] VEP_dis_arr [63:0];

wire [5:0] mux_32_idx [31:0];
wire [9:0] mux32_out [31:0];
wire [5:0] mux_16_idx [15:0];
wire [9:0] mux16_out [15:0];
wire [5:0] mux_8_idx [7:0];
wire [9:0] mux8_out [7:0];
wire [5:0] mux_4_idx [3:0];
wire [9:0] mux4_out [3:0];
wire [5:0] mux_2_idx [1:0];
wire [9:0] mux2_out [1:0];

genvar i4;
genvar i5;
genvar i6;
genvar i7;
genvar i8;
genvar i9;

generate
	for (i4=0; i4<64; i4=i4+1)begin : distance_wire1
		assign VEP_dis_arr[i4] = VEPs_manhattan_distance[(10*i4)+:10];
	end

endgenerate

//parameter [5:0] A5;
generate
	for(i5=0; i5<32; i5=i5+1)begin :mux32
		wire [5:0] A5  = i5 << 1;
	
		smaller_mux smaller_mux32(
		.in_a	(VEP_dis_arr[A5]),
		.in_b	(VEP_dis_arr[(A5) + 6'd1]),
		.a_idx(A5),
		.b_idx((A5 + 6'b1)),
		.out(mux32_out[i5]),
		.out_idx(mux_32_idx[i5])
		);
	end
endgenerate

generate
	for(i6=0; i6<16; i6=i6+1)begin :mux16
		smaller_mux smaller_mux16(
		.in_a	(mux32_out[i6<<1]),
		.in_b	(mux32_out[(i6<<1) + 32'd1]),
		.a_idx(mux_32_idx[i6<<1]),
		.b_idx(mux_32_idx[(i6<<1) +32'd1]),
		.out(mux16_out[i6]),
		.out_idx(mux_16_idx[i6])
		);
	end
endgenerate

generate
	for(i7=0; i7<8; i7=i7+1)begin :mux8
		smaller_mux smaller_mux8(
		.in_a	(mux16_out[i7<<1]),
		.in_b	(mux16_out[(i7<<1) + 32'd1]),
		.a_idx(mux_16_idx[i7<<1]),
		.b_idx(mux_16_idx[(i7<<1) + 32'd1]),
		.out(mux8_out[i7]),
		.out_idx(mux_8_idx[i7])
		);
	end
endgenerate


generate
	for(i8=0; i8<4; i8=i8+1)begin :mux4
		smaller_mux smaller_mux4(
		.in_a	(mux8_out[i8<<1]),
		.in_b	(mux8_out[(i8<<1) + 32'd1]),
		.a_idx(mux_8_idx[i8<<1]),
		.b_idx(mux_8_idx[(i8<<1) + 32'd1]),
		.out(mux4_out[i8]),
		.out_idx(mux_4_idx[i8])
		);
	end
endgenerate

generate
	for(i9=0; i9<2; i9=i9+1)begin :mux2
		smaller_mux smaller_mux2(
		.in_a	(mux4_out[i9<<1]),
		.in_b	(mux4_out[(i9<<1) + 32'd1]),
		.a_idx(mux_4_idx[i9<<1]),
		.b_idx(mux_4_idx[(i9<<1) + 32'd1]),
		.out(mux2_out[i9]),
		.out_idx(mux_2_idx[i9])
		);
	end
endgenerate

smaller_mux smaller_mux1(
		.in_a	(mux2_out[0]),
		.in_b	(mux2_out[1]),
		.a_idx(mux_2_idx[0]),
		.b_idx(mux_2_idx[1]),
		//.out(min1),
		.out_idx(winner_tag)
		);


endmodule
