`timescale 1ns / 1ps

module mux #(
		parameter D_WIDTH = 8
	)(
		// Clock and reset interface
		input clk,
		input rst_n,
		
		//Select interface
		input[1:0] select,
		
		// Output interface
		output reg[D_WIDTH - 1 : 0] data_o,
		output reg						 valid_o,
				
		//output interfaces
		input [D_WIDTH - 1 : 0] 	data0_i,
		input   							valid0_i,
		
		input [D_WIDTH - 1 : 0] 	data1_i,
		input   							valid1_i,
		
		input [D_WIDTH - 1 : 0] 	data2_i,
		input     						valid2_i
    );
	 
	 reg [8 : 0] prev_valid_o;
	 reg [8 : 0] prev_data_o;
	 
	 always @(posedge clk)
		begin
		
			if(rst_n == 0)
				begin
					prev_valid_o <= 0;
					valid_o <= 0;
					data_o <= 0;
					prev_data_o <= 0;
				end
			else if(rst_n == 1)
				begin
					
					case(select)
						
						2'b00: 
							begin
								if(valid0_i == 1)
									begin
										prev_valid_o <= 1;
										prev_data_o <= data0_i;
									end
								else if(valid0_i == 0)
									begin
										prev_valid_o <= 0;
										prev_data_o <= 0;
									end
							end
							
						2'b01:
							begin
								if(valid1_i == 1)
									begin
										prev_valid_o <= 1;
										prev_data_o <= data1_i;
									end
								else if(valid1_i == 0)
									begin
										prev_valid_o <= 0;
										prev_data_o <= 0;
									end
							end
							
						2'b10: 
							begin
								if(valid2_i == 1)
									begin
										prev_valid_o <= 1;
										prev_data_o <= data2_i;
									end
								else if(valid2_i == 0)
									begin
										prev_valid_o <= 0;
										prev_data_o <= 0;
									end
							end
							
						default:
							begin
								prev_valid_o <= 0;
								prev_data_o <= 0;
							end
							
					endcase
					
					valid_o <= prev_valid_o;
					data_o <= prev_data_o;
					
				end
		
		end

endmodule
