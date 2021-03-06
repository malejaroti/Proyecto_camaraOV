//---------------------------------------------------------------------------
//
// Wishbone camera
//
// Register Description:
//
//    0x0000 data : Dato que sale de la cámara
//
//---------------------------------------------------------------------------

module wb_camera (

   input              clk,
   input              reset, //reset
   // Wishbone interface
   input              wb_stb_i,
   input              wb_cyc_i,
   output             wb_ack_o,
   input              wb_we_i,
   input       [31:0] wb_adr_i,
   input       [3:0] wb_sel_i,
   input       [31:0] wb_dat_i,
   output reg  [31:0] wb_dat_o,
   // Camera data

   input vsync,
   input href,
   input pclk,
   input [7:0] data  
);
//---------------------------------------------------------------------------
// 
//---------------------------------------------------------------------------
reg  ack;
assign wb_ack_o = wb_stb_i & wb_cyc_i & ack;

wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i;
wire wb_wr = wb_stb_i & wb_cyc_i &  wb_we_i;

reg [3:0] dataOut;
reg [3:0] add_rd;
reg rd;
reg ready;

camera( .vsync(vsync), .data(data), .href(href), .pclk(pclk),.rd(rd), .add_rd(add_rd));


always @(posedge clk)
begin
	if (reset) begin
		ack      <= 0;
	end else begin

		// Handle WISHBONE access
		ack    <= 0;

		if (wb_rd & ~ack) begin           // read cycle
			ack <= 1;

			case (wb_adr_i[3:0])
			'h0: wb_dat_o <= {31'h0,ready};
			'h4: begin wb_dat_o <= {28'h0,dataOut}; rd <=0; end  
			
						
			endcase
		end else if (wb_wr & ~ack ) begin // write cycle
			ack <= 1;
			case (wb_adr_i[3:0])
			'h4: begin
			add_rd <= wb_dat_i;
			rd<=1;								
			end
			endcase
			end
	end
end

endmodule


