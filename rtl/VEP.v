/*
* Hint
sigal explanation:
1.  clk                : This is a positive edge-triggered clock signal.
2.  rst                : This is a reset signal.
3.  VEP_x              : The x-coordinate of this VEP.
4.  VEP_y              : The y-coordinate of this VEP.
5.  winner_VEP_x       : The VEP_x value with the minimum Manhattan distance.
6.  winner_VEP_y       : The VEP_y value with the minimum Manhattan distance.
7.  pixel              : Same as RAM_IF_Q, includes {R, G, B} channels with 8 bits in each channel.
8.  weight_initial    : The initial value given by LFSR, contained {R, G, B} channels.
9.  weight_update     : An enable signal from the controller that tells the weight in each VEP to be updated.
10. weight            : The value of the VEP's weight register.
11. manhattan_distance : For example, the Manhattan distance between (125, 80, 27) and (110, 70, 34) is |125-110|+|80-70|+|27-34|=32.

In short, there are 2 phases in SOM operation, the first phase is the training phase, 
which updating the weight through unsupervised training.
Second phase is recall phase, in the phase we need to select the weight closest to input pixel
as the winner weight. Be careful not to update the weights at this phase.

<TRAINING PHASE>
step1 : Split each pixel into 3 channels,so does the weight.
step2 : Calculate manhattan distance of each VEP.
step3 : Use WSC.v to find the x,y-coordinate with minimum manhattan distance,in other words,WSC.v is used to find the winner_VEP_x,y. 
step4 : Use VEP_x, VEP_y, winner_VEP_x and winner_VEP_y to select corresponding neighbor function.
step5 : Update the weight by setting weight_update to high.
step6 : repeat step1 to step 5 until all pixels of image are traversed.

<RECALL PHASE>
step1 : Split each pixel into 3 channels, so does the weight.
step2 : Traversed all VEP's and find the VEP closest(manhattan distance) to input pixel.
step3 : Output winner VEP's weight(RAM_W_D) to testbench.
step4 : Repeat step1 to step4 until all pixels of image are traversed.
*/
module VEP(
  input              clk,
  input              rst,
  input  [      2:0] VEP_x,
  input  [      2:0] VEP_y,
  input  [      2:0] winner_VEP_x,
  input  [      2:0] winner_VEP_y,
  input  [8*3 - 1:0] pixel,
  //input  [8*3 - 1:0] weight_initial,
  //input              weight_update,
  input  [2:0]       state,
  output  [8*3 - 1:0] weight,
  output [      9:0] manhattan_distance//manhattan distance, add 2 extension bits to prevent overflow
);

parameter
  sIdle = 3'd0,
  sFind_winner_train = 3'd1,
  sUpdate_W = 3'd2,
  sFind_winner_call = 3'd3,
  sWrite_pic = 3'd4,
  sWrite_W = 3'd5,
  sFinish = 3'd6;



reg [8*3 - 1:0] weight_save;
reg [8*3 - 1:0] pixel_save;
wire [7:0] R_diff ;
wire [7:0] G_diff ;
wire [7:0] B_diff ;

assign weight = weight_save;

assign manhattan_distance =  R_diff + G_diff + B_diff;


/*wire [7:0] VEP_W_R = weight_save[23:16];
wire [7:0] VEP_W_G = weight_save[15:8];
wire [7:0] VEP_W_B = weight_save[7:0];*/







wire [2:0] bigger_X = winner_VEP_x > VEP_x ? winner_VEP_x : VEP_x;
wire [2:0] smaller_X = winner_VEP_x < VEP_x ? winner_VEP_x : VEP_x;
wire [2:0] bigger_Y = winner_VEP_y > VEP_y ? winner_VEP_y : VEP_y;
wire [2:0] smaller_Y =winner_VEP_y < VEP_y ? winner_VEP_y : VEP_y;

wire [2:0] X_diff = bigger_X - smaller_X ;
wire [2:0] Y_diff = bigger_Y - smaller_Y ;



//wire [3:0] xy_distance = X_diff + Y_diff;
reg [1:0] xy_distance ;
always@(*)begin
	if(X_diff == 3'd0 && Y_diff == 3'd0)
	xy_distance = 2'd0;
	else if ((X_diff == 3'd0 && Y_diff == 3'd1) || (X_diff == 3'd1 && Y_diff == 3'd0) )
	xy_distance = 2'd1;
	else if ((X_diff == 3'd0 && Y_diff == 3'd2) || (X_diff == 3'd2 && Y_diff == 3'd0) || (X_diff == 3'd1 && Y_diff == 3'd1) )
	xy_distance = 2'd2;
	else 
	xy_distance = 2'd3;


end

//wire [5:0] xy_shift = {2'd0,xy_distance} + 6'd2;

/*wire[5:0] B_diff_shift = (B_diff >> xy_shift);
wire[5:0] R_diff_shift = (R_diff >> xy_shift ); 
wire[5:0] G_diff_shift = (G_diff >> xy_shift) ; */

wire signed [8:0] R_diff_sign = pixel_save[23:16] - weight_save[23:16] ; 
wire signed [8:0] G_diff_sign = pixel_save[15:8] - weight_save[15:8] ; 
wire signed [8:0] B_diff_sign = pixel_save[7:0] - weight_save[7:0] ; 

//wire R_8 = R_diff_sign[8];
//wire [6:0] R_8_s = {7{R_diff_sign[8]}};
//wire [6:0] test1 = {7{R_diff_sign[8]}} << (3'd7 - xy_shift);

wire signed [7:0] R_diff_shift_sign =  ((R_diff_sign >>> xy_distance) >>> 6'd2);//+ R_diff_sign[xy_shift-1]
wire signed [7:0] G_diff_shift_sign =   ((G_diff_sign >>> xy_distance) >>> 6'd2);
wire signed [7:0] B_diff_shift_sign =   ((B_diff_sign >>> xy_distance) >>> 6'd2);

/*wire signed [7:0] R_diff_shift_sign =  {8{R_diff_sign[8]}} << (4'd7 - xy_distance) | ((R_diff_sign >> xy_distance) >> 6'd2);//+ R_diff_sign[xy_shift-1]
wire signed [7:0] G_diff_shift_sign =  {8{G_diff_sign[8]}} << (4'd7 - xy_distance) | ((G_diff_sign >> xy_distance) >> 6'd2);
wire signed [7:0] B_diff_shift_sign =  {8{B_diff_sign[8]}} << (4'd7 - xy_distance) | ((B_diff_sign >> xy_distance) >> 6'd2);*/

wire signed [7:0] R_W_up = {weight_save[23:16]} + R_diff_shift_sign;
wire signed [7:0] G_W_up = {weight_save[15:8] } +  G_diff_shift_sign;
wire signed [7:0] B_W_up = {weight_save[7:0] } +   B_diff_shift_sign;


wire Pix_bigger_R = pixel_save[23:16] > weight_save[23:16];
wire Pix_bigger_G = pixel_save[15:8] > weight_save[15:8];
wire Pix_bigger_B = pixel_save[7:0] > weight_save[7:0];




wire signed [8:0] R_diff_sign_two =  (~R_diff_sign) + 9'b1;//+ R_diff_sign[xy_shift-1]
wire signed [8:0] G_diff_sign_two =  (~G_diff_sign) + 9'b1;
wire signed [8:0] B_diff_sign_two =  (~B_diff_sign) + 9'b1;

assign R_diff =  Pix_bigger_R ? R_diff_sign[7:0] :  R_diff_sign_two[7:0] ;
assign G_diff =  Pix_bigger_G ? G_diff_sign[7:0] :  G_diff_sign_two[7:0] ;
assign B_diff =  Pix_bigger_B ? B_diff_sign[7:0] :  B_diff_sign_two[7:0] ;

/*assign R_diff = bigger_R - smaller_R ;
assign G_diff = bigger_G - smaller_G ;
assign B_diff = bigger_B - smaller_B ;
assign bigger_R = (pixel_save[23:16] > weight_save[23:16]  ) ? pixel_save[23:16] :  weight_save[23:16] ;
assign smaller_R = (pixel_save[23:16] < weight_save[23:16]  ) ? pixel_save[23:16] :  weight_save[23:16] ;
assign bigger_G = (pixel_save[15:8] > weight_save[15:8]) ? pixel_save[15:8] :  weight_save[15:8] ;
assign smaller_G = (pixel_save[15:8] < weight_save[15:8]) ? pixel_save[15:8] :  weight_save[15:8] ;
assign bigger_B = (pixel_save[7:0] > weight_save[7:0]  ) ? pixel_save[7:0] :  weight_save[7:0] ;
assign smaller_B = (pixel_save[7:0] < weight_save[7:0]  ) ? pixel_save[7:0] :  weight_save[7:0] ;

wire [7:0] bigger_R;
wire [7:0] smaller_R;
wire [7:0] bigger_G;
wire [7:0] smaller_G;
wire [7:0] bigger_B;
wire [7:0] smaller_B;
assign bigger_R = Pix_bigger_R ? pixel_save[23:16] :  weight_save[23:16] ;
assign smaller_R = Pix_bigger_R ?   weight_save[23:16] : pixel_save[23:16] ;
assign bigger_G = Pix_bigger_G  ? pixel_save[15:8] :  weight_save[15:8] ;
assign smaller_G = Pix_bigger_G ?   weight_save[15:8] :pixel_save[15:8] ;
assign bigger_B = Pix_bigger_B  ? pixel_save[7:0] :  weight_save[7:0] ;
assign smaller_B = Pix_bigger_B ?   weight_save[7:0] : pixel_save[7:0] ;

*/

/*wire signed [7:0] R_W_up = weight_save[23:16] + ((pixel_save[23:16] - weight_save[23:16]) >> xy_shift);
wire signed [7:0] G_W_up = weight_save[15:8] + ((pixel_save[15:8] - weight_save[15:8]) >> xy_shift);
wire signed [7:0] B_W_up = weight_save[7:0] +  ((pixel_save[7:0] - weight_save[7:0]) >> xy_shift);*/

// wire[5:0] B_diff_shift = (B_diff  >> xy_shift) + B_diff[xy_shift -1 ];
// wire[5:0] R_diff_shift = (R_diff >> xy_shift ) + R_diff[xy_shift -1 ]; 
// wire[5:0] G_diff_shift = (G_diff >> xy_shift) + G_diff[xy_shift -1 ]; 
 

// assign R_diff = (pixel_save[23:16] > weight_save[23:16]  ) ? pixel_save[23:16] - weight_save[23:16] :  weight_save[23:16] - pixel_save[23:16] ;
// assign G_diff = (pixel_save[15:8] > weight_save[15:8]  ) ? pixel_save[15:8] - weight_save[15:8] :  weight_save[15:8] - pixel_save[15:8] ;
// assign B_diff = (pixel_save[7:0] > weight_save[7:0]  ) ? pixel_save[7:0] - weight_save[7:0] :  weight_save[7:0] - pixel_save[7:0] ;

always@(posedge clk or posedge rst)begin
if(rst)
	weight_save <= {8'd125,8'd125,8'd125};
else if (xy_distance <= 2'd2 && state == sUpdate_W)begin
  weight_save[23:16] <= R_W_up[7:0];
  weight_save[15:8]  <= G_W_up[7:0];
  weight_save[7:0]   <= B_W_up[7:0];
end
end


//wire W_update = xy_distance <= 4'd2 && state == sUpdate_W;//!test

always@(*)begin
	pixel_save = pixel;
end
 /*always@(posedge clk or posedge rst)begin
 if(rst)
 	pixel_save <= 24'b0;
 else
 	pixel_save <= pixel;
 end*/

endmodule
