`timescale 1ns / 1ps

module zigzag_decryption #(
				parameter D_WIDTH = 8,
				parameter KEY_WIDTH = 8,
				parameter MAX_NOF_CHARS = 50,
				parameter START_DECRYPTION_TOKEN = 8'hFA
			)(
			// Clock and reset interface
			input clk,
			input rst_n,
			
			// Input interface
			input[D_WIDTH - 1:0] data_i,
			input valid_i,
			
			// Decryption Key
			input[KEY_WIDTH - 1 : 0] key,
			
			// Output interface
            output reg busy,
			output reg[D_WIDTH - 1:0] data_o,
			output reg valid_o
    );

	reg [D_WIDTH * MAX_NOF_CHARS - 1 : 0] enc_data; // informatia criptata
	reg [8 : 0] nof_chars; // numarul de caractere (incepand cu 0) / citire
	reg [8 : 0] current_position; // 
	reg [8 : 0] end_of_transmission;
	reg [8 : 0] current_letter;
	reg [8 : 0] new_letter;
	reg [8 : 0] current_char;
	
	reg low;
	reg [8 : 0] index;
	
	reg [8 : 0] cycles;
	reg [8 : 0] idx_i, idx_j, a_idx, b_idx, c_idx;
	
	// variabile impartire
	reg [15 : 0] Q, R, N, D;
	reg [4 : 0] i;

	always @(posedge clk)
		begin
		
			if(rst_n == 0)
				begin
				
				busy <= 0;
				valid_o <= 0;
				data_o <= 0;
				
				nof_chars <= 0;
				current_position <= 0;
				enc_data <= 0;
				
				current_char <= 0;
				current_letter <= 0;
				new_letter <= 0;
				
				low <= 0;
			   index <= 0;
			   idx_i <= 0;
			   idx_j <= 0;
			   a_idx <= 0;
			   b_idx <= 0;
			   c_idx <= 0;
				
				end
			else if(rst_n == 1)
				begin
				
					if(valid_i == 1 && data_i != 0)	// incarcare informatie criptata
						begin
							
							if(data_i != 'hFA)
								begin
									enc_data[nof_chars * D_WIDTH +: D_WIDTH] <= data_i;
									nof_chars <= nof_chars + 1;
								end
							else
								begin
									nof_chars <= nof_chars - 1;
									end_of_transmission <= 1;
									//busy <= 1;
								end
							
							//$display("enc_data: %b", enc_data);
							
						end
					else //if(valid_i == 0)
						begin
							
							if(end_of_transmission == 1) // semnal ce declanseaza realizarea impartirii si activarea lui busy
								begin					// pe frontul urmator al clk
									busy <= 1;
									end_of_transmission <= 0;
									//new_letter <= new_letter + 1;
									
								end
								
							if(busy == 1)
								begin
									valid_o <= 1;
									
									
									if(key == 2 && nof_chars[0] == 1)	// nof_chars = dimensiune - 1 (nr. de caractere pleaca de la 0)
										begin						    // deci pentru numar par de caractere
											if(current_char <= nof_chars)
												begin
												
													
													if(index <= Q - 1)
														begin
														
															if(low == 0)
																begin
																
																	data_o <= enc_data[index * D_WIDTH +: D_WIDTH];
																	low <= 1;
																	
																end
															else if(low == 1)
																begin
																
																	data_o <= enc_data[(index + Q) * D_WIDTH +: D_WIDTH];
																	low <= 0;
																	index <= index + 1;
																end
															
															current_char <= current_char + 1;
															
														end
														
												end
											else if(current_char > nof_chars)
												begin
												
													busy <= 0;
													valid_o <= 0;
													data_o <= 0;
													index <= 0;
													low <= 0;
													current_char <= 0;
													nof_chars <= 0;
												
												end
										end
									else if(key == 2 && nof_chars[0] == 0)	// pentru numar impar de caractere
										begin
										
										//
										if(current_char <= nof_chars)
												begin
												
													
													if(index <= Q)
														begin
														
															if(low == 0)
																begin
																
																	data_o <= enc_data[index * D_WIDTH +: D_WIDTH];
																	low <= 1;
																	
																end
															else if(low == 1)
																begin
																
																	data_o <= enc_data[(index + Q + 1) * D_WIDTH +: D_WIDTH];
																	low <= 0;
																	index <= index + 1;
																end
															
															current_char <= current_char + 1;
															
														end
												end
										else if(current_char > nof_chars)	// resetare
												begin
												
													busy <= 0;
													valid_o <= 0;
													data_o <= 0;
													index <= 0;
													low <= 0;
													current_char <= 0;
													nof_chars <= 0;
												
												end
										//
										end
									else if(key == 3) // temporary busy/valid signals TODO: logic
										begin
											if(current_char <= nof_chars)
												begin
												
													if(idx_i < Q) // < Cycles - pentru nof_chars / nr_caractereperciclu = cat rest 0 (Ciclu complet)
														begin
														
															if(idx_j <= key)
																begin
																	if(idx_j == 0)
																		data_o <= enc_data[idx_i * D_WIDTH +: D_WIDTH];
																	else if(idx_j != 0)
																		begin
																			case (idx_i)
																			
																				0: begin
																					if(idx_j == 1)
																						begin
																							a_idx <= idx_i + Q;
																							data_o <= enc_data[(idx_i + Q) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 2)
																						begin
																							b_idx <= a_idx + 2 * Q;
																							data_o <= enc_data[(a_idx + 2 * Q) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 3)
																						begin
																							c_idx <= a_idx + 1;
																							data_o <= enc_data[(a_idx + 1) * D_WIDTH +: D_WIDTH];
																						end
																					end
																					
																				1: begin
																					if(idx_j == 1)
																						begin
																							a_idx <= a_idx + 2;
																							data_o <= enc_data[(a_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 2)
																						begin
																							b_idx <= b_idx + 1;
																							data_o <= enc_data[(b_idx + 1) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 3)
																						begin
																							c_idx <= c_idx + 2;
																							data_o <= enc_data[(c_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					end
																					
																				2: begin
																					if(idx_j == 1)
																						begin
																							a_idx <= a_idx + 2;
																							data_o <= enc_data[(a_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 2)
																						begin
																							b_idx <= b_idx + 1;
																							data_o <= enc_data[(b_idx + 1) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 3)
																						begin
																							c_idx <= c_idx + 2;
																							data_o <= enc_data[(c_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					end
																				
																				3: begin
																					if(idx_j == 1)
																						begin
																							a_idx <= a_idx + 2;
																							data_o <= enc_data[(a_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 2)
																						begin
																							b_idx <= b_idx + 1;
																							data_o <= enc_data[(b_idx + 1) * D_WIDTH +: D_WIDTH];
																						end
																					if(idx_j == 3)
																						begin
																							c_idx <= c_idx + 2;
																							data_o <= enc_data[(c_idx + 2) * D_WIDTH +: D_WIDTH];
																						end
																					end
																					
																					
																			endcase
																		end
																	
																	idx_j <= idx_j + 1;
																
																end
															if(idx_j == 3)
																begin
																	idx_i <= idx_i + 1;
																	idx_j <= 0;
																end
															
														
														end
												
													current_char <= current_char + 1;
													
												end
											else
												begin
													busy <= 0;
													valid_o <= 0;
													current_char <= 0;
													nof_chars <= 0;
													a_idx <= 0;
													b_idx <= 0;
													c_idx <= 0;
													idx_i <= 0;
													idx_j <= 0;
												end
										end
									
								end
						end
				
				end
				
		end
		
	always @(*)		// algoritmul de impartire utilizat in Tema 1
		begin
		
		if(end_of_transmission)
			begin
				N = nof_chars + 1;
				D = key;
					
					if(key == 2)
						begin
							if(D != 0)
								begin 
									
									Q = 0;
									R = 0;
									
									for(i = 15; i > 0; i = i - 1)
										begin
										
											R = R << 1;
											R[0] = N[i];
											
											if(R >= D)  
												begin				
													R = R - D;
													Q[i] = 1;
												end
												
										end
										
										R = R << 1;	// bitul de pe prima pozitie este tratat separat pentru a evita cazul in care i ia valoarea maxima
										R[0] = N[i];
											
									if(R >= D)  
										begin				
											R = R - D;
											Q[0] = 1;
										end
								end
						end
					else if(key == 3)
						begin
							D = 4; // numarul de caractere per ciclu complet
							if(D != 0)
								begin 
									
									Q = 0;
									R = 0;
									
									for(i = 15; i > 0; i = i - 1)
										begin
										
											R = R << 1;
											R[0] = N[i];
											
											if(R >= D)  
												begin				
													R = R - D;
													Q[i] = 1;
												end
												
										end
										
										R = R << 1;	// bitul de pe prima pozitie este tratat separat pentru a evita cazul in care i ia valoarea maxima
										R[0] = N[i];
											
									if(R >= D)  
										begin				
											R = R - D;
											Q[0] = 1;
										end
								end
								
							if(R != 0)
								Q = Q + 1; // se adauga un ciclu pentru key = 3, unde nof_chars % nr_caractereperciclu != 0
						end
							
//$display("Q: %b", Q); // 

				end
				
			end



endmodule
