`timescale 1ns / 1ps

module decryption_regfile #(
			parameter addr_width = 8,
			parameter reg_width 	 = 16
		)(
			// Clock and reset interface
			input clk, 
			input rst_n,
			
			// Register access interface
			input[addr_width - 1:0] addr,
			input read,
			input write,
			input [reg_width -1 : 0] wdata,
			output reg [reg_width -1 : 0] rdata,
			output reg done,
			output reg error,
			
			// Output wires 
			output [reg_width - 1 : 0] select,
			output [reg_width - 1 : 0] caesar_key,
			output [reg_width - 1 : 0] scytale_key,
			output [reg_width - 1 : 0] zigzag_key
    );
	
	reg [reg_width - 1 : 0] select_register;
	reg [reg_width - 1 : 0] caesar_key_register;
	reg [reg_width - 1 : 0] scytale_key_register;
	reg [reg_width - 1 : 0] zigzag_key_register;
	
	reg valid_write;
	reg valid_read;
	
	reg[reg_width - 1 : 0] tmp_data;
	reg[addr_width - 1 : 0] tmp_addr;
	
	always @(posedge clk)
		begin
		
		
		// - - - reset - - -
		
		if(rst_n == 0) 
			begin
				select_register <= 16'h0;
				caesar_key_register <= 16'h0;
				scytale_key_register <= 16'hFFFF;
				zigzag_key_register <= 16'h2;
				done <= 0;
				error <= 0;
				rdata <= 0;
			end
		else
			begin
			
			// - - - read/write - - -
			
				if(valid_write) // adresa de pe frontul clk pozitiv anterior exista
					begin
						
						error <= 0; // scrierea se poate realiza, deci semnalul de eroare va fi dezactivat
						
						case(tmp_addr) // scriere in registrul corespunzator adresei
									  // primite ca input (daca e valida)
							8'h00:
								begin
									select_register[1:0] <= tmp_data;
								end
							
							8'h10:
								begin
									caesar_key_register <= tmp_data;
								end
								
							8'h12:
								begin
									scytale_key_register <= tmp_data;
								end
							
							8'h14:
								begin
									zigzag_key_register <= tmp_data;
								end								
						endcase
						
					end
					
				else
				
				if(valid_read)
					begin
						
						error <= 0;	// citirea se poate realiza, deci semnalul de eroare va fi dezactivat
						
						case(tmp_addr)
						
							8'h00:
								begin
									rdata <= tmp_data;
								end
								
							8'h10:
								begin
									rdata <= tmp_data;
								end
									
							8'h12:
								begin
									rdata <= tmp_data;
								end
								
							8'h14:
								begin
									rdata <= tmp_data;
								end		
							
							endcase
							
					end
					
					
				if(done) 		 // daca s-a facut scriere/citire anterior
					done <= 0;	// done este dezactivat
		
				if(write == 1 && read == 0)	// acces de tip scriere
					begin
					done <= 1;
					valid_read <= 0;
					
						case(addr)
							
							8'h00:
								begin
									valid_write <= 1;	// scriere in select
									tmp_data <= wdata;
									tmp_addr <= addr;
									select_register[1:0] <= wdata;
									error <= 0;
								end
							8'h10:
								begin
									valid_write <= 1;	// scriere in caesar
									tmp_data <= wdata;
									tmp_addr <= addr;
									caesar_key_register <= wdata;
									error <= 0;
								end
							8'h12:
								begin
									valid_write <= 1;	// scriere in scytale
									tmp_data <= wdata;
									tmp_addr <= addr;
									scytale_key_register <= wdata;
									error <= 0;
								end
							8'h14: 
								begin
									valid_write <= 1;	// scriere in zigzag
									tmp_data <= wdata;
									tmp_addr <= addr;
									zigzag_key_register <= wdata;
									error <= 0;
								end
							default: 
								begin
									valid_write <= 0;	// acces la registru invalid
								    //error_trigger <= 1; 
									tmp_addr <= addr;
									error <= 1;
								end
								
						endcase
							
					end
				else	
				if(read == 1 && write == 0)	// acces de tip citire
					begin
					done <= 1;
					valid_write <= 0;
					
						case(addr)
						
							8'h00:
								begin
									tmp_data <= select_register[1:0];	// citire din select
									valid_read <= 1;
									tmp_addr <= addr;
									rdata <= select_register[1:0];
									error <= 0;
								end
							8'h10:
								begin
									tmp_data <= caesar_key_register;	// citire din caesar
									valid_read <= 1;
									tmp_addr <= addr;
									rdata <= caesar_key_register;
									error <= 0;
								end
							8'h12:
								begin
									tmp_data <= scytale_key_register;	// citire din scytale
									valid_read <= 1;
									tmp_addr <= addr;
									rdata <= scytale_key_register;
									error <= 0;
								end
							8'h14: 
								begin
									tmp_data <= zigzag_key_register;	// citire din zigzag
									valid_read <= 1;
									tmp_addr <= addr;
									rdata <= zigzag_key_register;
									error <= 0;
								end
							default:
								begin
									valid_read <= 0;	// acces la registru invalid
									tmp_addr <= addr;
									error <= 1;
								end
								
						endcase	
				end
				else
					begin
						if(error)
							error <= 0; // daca eroarea a fost activata pe ciclul anterior, iar 
										// pe ciclul curent nu se fac scrieri/citiri, eroarea este setata pe 0
						valid_read <= 0;
						valid_write <= 0;
					end
			end
			
			// afisare valori pentru semnalele implicate in scriere/citire pe fiecare front pozitiv al clk
			// $display("read = %h; valid_read = %h; tmp_addr = %h; addr = %h;", read, valid_read, tmp_addr, addr);
			
		end
		
			assign select = select_register;
			assign caesar_key =  caesar_key_register;
			assign scytale_key = scytale_key_register;
			assign zigzag_key =  zigzag_key_register;
		
endmodule
