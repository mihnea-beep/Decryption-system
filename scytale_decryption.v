`timescale 1ns / 1ps

module scytale_decryption#(
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
			input[KEY_WIDTH - 1 : 0] key_N,
			input[KEY_WIDTH - 1 : 0] key_M,
			
			// Output interface
			output reg[D_WIDTH - 1:0] data_o,
			output reg valid_o,
			
			output reg busy
    );
	 
	 reg [MAX_NOF_CHARS * D_WIDTH - 1 : 0] full_text;
	 reg [8 : 0] current_position; // 512 > 400 = max number of bits for a sentence
	 reg end_of_word;
	 reg [8 : 0] dimension;
	 reg [8 : 0] nof_chars;
	 
	 reg [8 : 0] i;
	 reg [8 : 0] j;
	 reg [8 : 0] map_letter;
	 
	 reg [MAX_NOF_CHARS * D_WIDTH - 1 : 0] decoded_text;
	 reg [8 : 0] current_char;
	 reg [8 : 0] crt_letter;
	 
	 always @(posedge clk)
		begin
		
		//$display("full_text: %b\nend_of_word: %b", full_text[55 : 0], end_of_word);
		//$display("nof_chars: %b\n", nof_chars);
			if(rst_n == 0)
				begin
				// reset
				//crt_letter <= 0;
				nof_chars <= 0;
				busy <= 0;
				full_text <= 0;
				data_o <= 0;
				valid_o <= 0;
				current_position <= 0; //
				end_of_word <= 0;
				current_char <= 0; //
				map_letter <= 0;
				crt_letter <= 0;
				
				
				end
			else if(rst_n == 1)
				begin
				
					if(valid_i == 1 && data_i != 0)
						begin
						
						if(data_i != 'hFA)
							begin
								full_text[current_position +: D_WIDTH] <= data_i; //
								current_position <= current_position + D_WIDTH;
								nof_chars <= nof_chars + 1;
							end
							else if(data_i == 'hFA)
								begin
								//$display("data_i ('hFA): %h", data_i);
									end_of_word <= 1;
									busy <= 1;
									nof_chars <= nof_chars - 1;
								end
						end
						else
							begin
																			
								if(end_of_word == 1)
									begin
										//busy <= 1;
										valid_o <= 1;
										end_of_word <= 0; // 
										data_o <= full_text[crt_letter * D_WIDTH +: D_WIDTH];
										current_char <= current_char + 1;
										map_letter <= crt_letter + key_N;
										crt_letter <= crt_letter + 1;
									end
									
								if(busy == 1 && !end_of_word)
									begin
										valid_o <= 1;
										if(current_char < nof_chars)
										//data_o <= full_text[current_position - 1 -: D_WIDTH];
											begin
												////$display("\n----- current_char: %b", current_char);
												map_letter <= map_letter + key_N;
												
												if(nof_chars >= map_letter)
													begin
														data_o <= full_text[map_letter * D_WIDTH +: D_WIDTH];
														current_char <= current_char + 1; 
														////$display("data_o: %c\tmap_letter: %b\tnof_chars: %b", data_o, map_letter, nof_chars);
													end
													else begin
														data_o <= full_text[crt_letter * D_WIDTH +: D_WIDTH];
														////$display("crt_letter: %c\t crt_letter_no: %b", full_text[crt_letter * D_WIDTH +: D_WIDTH], crt_letter);
														////$display("\ndata_o: %c", data_o);
														current_char <= current_char + 1;
														crt_letter <= crt_letter + 1;
														map_letter <= crt_letter + key_N;
														//end_of_word <= 1;
													end
												
												//$display("current_char: %b\tnof_chars: %b\tdata_o: %c\n", current_char, nof_chars, data_o);
												//$display("dimension: %b\ncurrent_position: %b\n", dimension, current_position);
											end
										else if(current_char == nof_chars)
											begin
												data_o <= full_text[current_char * D_WIDTH +: D_WIDTH];
												current_char <= current_char + 1;
												
												////$display("current_char: %b\tnof_chars: %b\tdata_o: %c\n", current_char, nof_chars, data_o);
												//busy <= 0;
												//valid_o <= 0;
												//data_o <= 65;
											end
										else if(current_char > nof_chars)
											begin
												////$display("\ndata_o: %c", data_o);
												data_o <= 0;
												busy <= 0;
												valid_o <= 0;
											end
									end
								else if(busy == 0 && valid_o == 0 && current_char > nof_chars) // some kind of reset
									begin
										current_char <= 0;
										nof_chars <= 0;
										current_position <= 0;
										full_text <= 0;
										data_o <= 0;
										//
										crt_letter <= 0;
										map_letter <= 0;
										
									end
									
							end 
						
				end
				
		end
					
	/*always @(posedge end_of_word)
		begin
		// scytale logic 
		dimension = current_position; // numarul de biti
		
		if(end_of_word)
			begin
			crt_letter = 0;
			//$display("yep\ndimension: %b\ncurrent_position: %b\n", dimension, current_position);
				for(i = 0; i < key_N; i = i + 1)
					begin
						map_letter = i;
						//crt_letter = crt_letter + 1;
						decoded_text[crt_letter * D_WIDTH +: D_WIDTH] = full_text[i * D_WIDTH +: D_WIDTH];
						crt_letter = crt_letter + 1;
						for(j = i; j < nof_chars; j = j + 1)
							begin
								map_letter = map_letter + key_N;
								if(map_letter < nof_chars)
									//display(map_letter_index...)
									begin
									//decoded_text[i * D_WIDTH +: D_WIDTH] <= full_text[i * D_WIDTH +: D_WIDTH];
									//decoded_text[i +: D_WIDTH] <= full_text[map_letter * D_WIDTH +: D_WIDTH];
									//$display("decoded_text: %c\n", decoded_text);
										decoded_text[D_WIDTH * crt_letter +: D_WIDTH] = full_text[map_letter * D_WIDTH +: D_WIDTH];
										crt_letter = crt_letter + 1;
									
									end
							end
					end
					
				//$display("\ndecoded_text: %b", decoded_text);
			end
			crt_letter = 0;
		end
*/
endmodule
