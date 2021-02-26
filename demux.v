`timescale 1ns / 1ps

module demux #(
		parameter MST_DWIDTH = 32,
		parameter SYS_DWIDTH = 8
	)(
		// Clock and reset interface
		input clk_sys,
		input clk_mst,
		input rst_n,
		
		//Select interface
		input[1:0] select,
		
		// Input interface
		input [MST_DWIDTH -1  : 0]	 data_i,
		input 						 	 valid_i,
		
		//output interfaces
		output reg [SYS_DWIDTH - 1 : 0] 	data0_o,
		output reg     						valid0_o,
		
		output reg [SYS_DWIDTH - 1 : 0] 	data1_o,
		output reg     						valid1_o,
		
		output reg [SYS_DWIDTH - 1 : 0] 	data2_o,
		output reg     						valid2_o
    );
	 
	reg [MST_DWIDTH - 1 : 0] stored_data;
	reg [8 : 0] transmission_index;
	reg [8 : 0] clk_fronts_passed;
	reg [8 : 0] prev_valid;
	reg start;
	reg [8 : 0] prev_clk_fronts_passed;
	reg [8 : 0] timer;
	
	always @(posedge clk_sys)
		begin
		
			if(rst_n == 0)
				begin
					transmission_index <= 0;
					clk_fronts_passed <= 0;
					prev_valid <= 0;
					start <= 0;
					prev_clk_fronts_passed <= 0;
					timer <= 0;
				end
			else if(rst_n == 1)
				begin
				
					prev_valid <= valid_i;
					prev_clk_fronts_passed <= clk_fronts_passed;
					
					if(valid_i == 1)
						begin
							clk_fronts_passed <= clk_fronts_passed + 1; // contorul incepe sa numere de la activarea lui valid_i
						end
					else if(valid_i == 0)
						begin
						end
							
						
					if(clk_fronts_passed != 0 && clk_fronts_passed == prev_clk_fronts_passed) // dupa incheierea transmisiei de date
						timer <= timer + 1;													  // valid_i devine 0 si clk_fronts_passed nu se mai incrementeaza
																							  // astfel, peste inca 4 fronturi (timpul este destul de mare intre inputuri), 
					if(timer >= 4) 															  // se reseteaza numarul de fronturi
						begin
							timer <= 0;
							clk_fronts_passed <= 0;
						end
					
					
						
						
					if(transmission_index == 0 && valid_i == 1 && clk_fronts_passed >= 3) // primul caracter este tratat mai devreme, deoarece in case, 
						begin															  // la momentul clk_fronts_passed == 3 nu exista stored_data anterior
							if(select == 0)
								data0_o <= data_i[(transmission_index + 3) * SYS_DWIDTH +: SYS_DWIDTH];
							if(select == 1)
								data1_o <= data_i[(transmission_index + 3) * SYS_DWIDTH +: SYS_DWIDTH];
							if(select == 2)
								data2_o <= data_i[(transmission_index + 3) * SYS_DWIDTH +: SYS_DWIDTH];
						end
							
					if(clk_fronts_passed >= 3) // la al patrulea clk (0 1 2 3) se face scrierea pentru celelalte cazuri, unde stored_data este actualizat la timp
						begin
							case(select)
								
								2'b00:
									begin
										transmission_index <= transmission_index + 1;
										if(transmission_index == 1)
											data0_o <= stored_data[(transmission_index + 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 2)
											data0_o <= stored_data[(transmission_index - 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 3)	
											data0_o <= stored_data[(transmission_index - 3) * SYS_DWIDTH +: SYS_DWIDTH];
									
									end
								
								2'b01:
									begin
										transmission_index <= transmission_index + 1;
										if(transmission_index == 1)
											data1_o <= stored_data[(transmission_index + 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 2)
											data1_o <= stored_data[(transmission_index - 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 3)	
											data1_o <= stored_data[(transmission_index - 3) * SYS_DWIDTH +: SYS_DWIDTH];
									end
								
								
								2'b10:
									begin
										transmission_index <= transmission_index + 1;
										if(transmission_index == 1)
											data2_o <= stored_data[(transmission_index + 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 2)
											data2_o <= stored_data[(transmission_index - 1) * SYS_DWIDTH +: SYS_DWIDTH];
										if(transmission_index == 3)	
											data2_o <= stored_data[(transmission_index - 3) * SYS_DWIDTH +: SYS_DWIDTH];
									end
									
							endcase
						end
					else 
						begin
						end
						
					if(transmission_index > 2) // reset 
						begin
							transmission_index <= 0;
						end				
							
				end
		
		end
		
	always @(posedge clk_mst) // de 4 ori mai lent
		begin
		
			if(rst_n == 0)
				begin
					stored_data <= 0;
				end
			else if(rst_n == 1)
				begin
					if(valid_i == 1) // semnalele se activeaza pe frontul urmator
						begin
							stored_data <= data_i;
							if(select == 0)
								valid0_o <= 1;
							if(select == 1)
								valid1_o <= 1;
							if(select == 2)
								valid2_o <= 1;
							
						end
					else	// reset
						begin
							valid0_o <= 0;
							valid1_o <= 0;
							valid2_o <= 0;
							stored_data <= 0;
						end
				end
				
			
		end
	

endmodule
