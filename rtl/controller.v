module controller(
  input                 clk,
  input                 rst,
  input   [1:0]         mode,
  input   [24*64 - 1:0] weight,
  input   [2:0]         winner_VEP_x,
  input   [2:0]         winner_VEP_y,
  output reg [2:0]         current_state , // state  from top
  //output reg [12:0]        counter, // from top	
  output                RAM_IF_OE,
  output                RAM_IF_WE,
  output  [17:0]        RAM_IF_A,
  output  [23:0]        RAM_IF_D,
  output                RAM_W_OE,
  output                RAM_W_WE,
  output  [17:0]        RAM_W_A,
  output  [23:0]        RAM_W_D,
  output                RAM_PIC_OE,
  output  reg           RAM_PIC_WE,
  output  reg [17:0]        RAM_PIC_A,
  output  [23:0]        RAM_PIC_D,
  //output                weight_update,
  output  reg              done
);


genvar i11;
wire [23:0] VEP_weight_controller [63:0];

reg [12:0]        counter;
generate
	for (i11=0; i11<64; i11=i11+1)begin : weight_wire1
		assign VEP_weight_controller[i11] = weight[(24*i11)+:24];
	end

endgenerate

//reg [2:0] current_state ;
reg [2:0] next_state;

//reg [11:0] counter;
reg   delay_flag;//[1:0]
parameter
  sIdle = 3'd0,
  //sFind_winner_train = 3'd1,
  sUpdate_W = 3'd2,
  //sFind_winner_call = 3'd3,
  sWrite_pic = 3'd4,
  sWrite_W = 3'd5,
  sFinish = 3'd6;


//assign weight_update = current_state == sWrite_W;

always@(posedge clk or posedge rst)begin
	if(rst)
	current_state <= sIdle;
	else
	current_state <= next_state;

end

reg finish_update;

always@(*)begin
	case(current_state)
    sIdle : next_state =   delay_flag == 1'd1 ? sUpdate_W  : sIdle ;
    //sFind_winner_train: next_state = sUpdate_W;
    sUpdate_W: next_state  = finish_update ? sWrite_pic: sUpdate_W;
    //sFind_winner_call: next_state = sWrite_pic;
    sWrite_pic: next_state = finish_update ? sFinish : sWrite_pic  ;
    sWrite_W: next_state = counter == 13'd63 ? sFinish : sWrite_W ;
    sFinish: next_state = sFinish;
    default next_state = sIdle;
	endcase

end





wire [5:0] counterY_sub = counter[11:6] - 6'd1;
wire [5:0] counterX_sub =  counter[5:0] - 6'd1;
wire [5:0] counterY_add = counter[11:6] + 6'd1;
wire [5:0] counterX_add = counter[5:0] + 6'd1;

wire [5:0] counterX = counter[5:0];
wire [5:0] counterY = counter[11:6];







always@(posedge clk or posedge rst)begin
  if(rst)
  finish_update<= 1'b0;
  else if (current_state == sWrite_pic && counter == 13'd0)
	finish_update <= 1'b0;
  else if (current_state == sWrite_pic && counter == 13'd4095)
    finish_update <= 1'b1;
  else if(!(current_state == sWrite_pic ) && mode == 2'd0 && counterY == 6'd0 && counter[5:0] == 6'd0)
    finish_update <= 1'b1;
  else if(!(current_state == sWrite_pic ) &&  mode == 2'd1 && counterY == 6'd63 && counter[5:0] == 6'd0)
    finish_update <= 1'b1;
  else if(!(current_state == sWrite_pic ) && mode == 2'd2 && counterY == 6'd0 && counter[5:0] == 6'd63)
    finish_update <= 1'b1;
  else if(!(current_state == sWrite_pic ) && mode == 2'd3 && counterY == 6'd63 && counter[5:0] == 6'd63)
    finish_update <= 1'b1;
  else 
	finish_update <= 1'b0; 
end


//wire [12:0] counter_plus;
//assign counter_plus = counter + 13'b1;

reg [12:0] counter_plus_v2;


always@(*)begin

         if ( counterX == 6'd63 && counterY == 6'd63)
	counter_plus_v2 = (1'b1 << 12);
	else if ( counterX == 6'd63)
	counter_plus_v2 = {1'b0, counterY_add , 6'b0};
	else 
	counter_plus_v2 = { counterY , counterX_add };  
  
end


//wire check_plus = counter_plus == counter_plus_v2;


always@(posedge clk or posedge rst)begin
	if(rst)
	delay_flag <= 1'b0;
	else if(current_state == sIdle )
	delay_flag <= !delay_flag;

	else 
	delay_flag <= 1'b0;	  
  
end


always@(posedge clk or posedge rst)begin
    if(rst)begin
    counter<= 13'd0;
  end
    else if(current_state == sIdle && (!delay_flag))begin
    counter[12] <= 1'b0;
    counter[5:0] <= mode[1]? 6'd0 : 6'd63;
    counter[11:6]<= mode[0]? 6'd0 : 6'd63;
end
else if ((next_state != current_state) && current_state != sIdle)
	counter <= 13'b0;


/////////////////////////////
else if (current_state == sWrite_pic || current_state == sWrite_W)
    counter <=   counter_plus_v2;//counter_plus;


  else if ( mode == 2'd0)begin
    counter[5:0] <= counterX == 6'd0 ? 6'd63 : counterX_sub;
    counter[11:6] <= counterX == 6'd0 ? counterY_sub : counterY;  

  end
  else if ( mode == 2'd1)begin
    counter[5:0] <= counterX == 6'd0 ? 6'd63 : counterX_sub;
    counter[11:6] <= counterX == 6'd0 ? counterY_add : counterY;  

  end
  else if ( mode == 2'd2)begin
    counter[5:0] <= counterX == 6'd63 ? 6'd0 : counterX_add;
    counter[11:6] <= counterX == 6'd63 ? counterY_sub : counterY;  

  end
  else if ( mode == 2'd3)begin
    counter[5:0] <= counterX == 6'd63 ? 6'd0 : counterX_add;
    counter[11:6] <= counterX == 6'd63 ? counterY_add : counterY;  

  end
	else 
		counter <=  counter;
end



//RAM_IF_WE
assign RAM_IF_WE=1'b0;
//RAM_IF_OE
assign RAM_IF_OE=1'b1;
assign RAM_IF_A = {5'b0,counter} ;
//RAM_IF_D
assign RAM_IF_D=24'b0;


//RAM_W_WE
assign RAM_W_WE= current_state == sWrite_pic;

//RAM_W_OE
assign RAM_W_OE= current_state == sWrite_pic ?  1'b0 :   1'b1;
/*always@(posedge clk or posedge rst)begin
	if(rst)
	RAM_W_OE <= 1'b0;
	else 
	RAM_W_OE <= 1'b1;
end*/

//RAM_W_A
assign RAM_W_A =  {5'b0,counter}  ;
//RAM_W_D
assign RAM_W_D= VEP_weight_controller[counter[5:0]];


//RAM_PIC_OE
assign RAM_PIC_OE =1'b0;
//RAM_PIC_WE
always@(*)begin
	if(current_state == sWrite_pic  )
	RAM_PIC_WE = 1'b1;
	else 
	RAM_PIC_WE = 1'b0;
end

wire [ 5:0] winner_idx ={winner_VEP_y , winner_VEP_x};

//RAM_PIC_A
//assign RAM_PIC_A = counter ;

//wire [12:0] counter_sub = counter - 13'd1;


reg [12:0] counter_sub_v2;


always@(*)begin

         if ( counterX == 6'd0 && counterY == 6'd0)
	counter_sub_v2 = (13'd4095);
	else if ( counterX == 6'd0)
	counter_sub_v2 = {1'b0, counterY_sub , 6'd63};
	else 
	counter_sub_v2 = { counterY , counterX_sub };  
  
end


//wire check_sub = counter_sub == counter_sub_v2;



always@(*)begin
	if(current_state == sWrite_pic)
	RAM_PIC_A = {5'b0,counter_sub_v2} ;
	else 
	RAM_PIC_A = 18'b0;
end

//RAM_PIC_D
assign RAM_PIC_D = VEP_weight_controller[winner_idx];// (winner_VEP_y << 3) + winner_VEP_x;


always@(posedge clk or posedge rst)begin
	if(rst)
	done <= 1'b0;
	else if(current_state == sFinish)
	done <= 1'd1;
end

endmodule
