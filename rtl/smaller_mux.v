module smaller_mux(
	input [9:0] in_a,
                    in_b,
	input [5:0] a_idx,
	            b_idx,
    output  [9:0] out,
    output  [5:0]  out_idx);
assign out = in_b >= in_a ? in_a : in_b;
assign out_idx = in_b >= in_a ? a_idx : b_idx;
endmodule

