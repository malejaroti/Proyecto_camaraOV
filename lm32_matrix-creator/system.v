//---------------------------------------------------------------------------
// LatticeMico32 System On A Chip
//
// Top Level Design for the Matrix Creator
//---------------------------------------------------------------------------

module system
#(
 //	parameter   bootram_file0     = "../firmware/keypad/image0.ram",
 //	parameter   bootram_file1     = "../firmware/keypad/image1.ram",
 //	parameter   bootram_file2     = "../firmware/keypad/image2.ram",
 //	parameter   bootram_file3     = "../firmware/keypad/image3.ram",
	parameter   bootram_file     = "../firmware/camera/image.ram",
	parameter   clk_freq         = 50000000,
	parameter   uart_baud_rate   = 57600,
	parameter divFactor = 50000,
	parameter maxCount =  3,
	parameter counterWidth = 3
) (
	input             clk,
	// Debug 
	input             rst,
	output            led,
	// UART
	input             uart_rxd, 
	output            uart_txd,
	//keypad
	input [3:0] row,
	output [3:0] column,
	output keypad0_intr,
	//camera
	input vsync,
	input href,
	input [7:0] data,
	input pclk,
  //	output reset_cam,
	output reg divOut

);


//------------------------------------------------------------------
// Whishbone Wires
//------------------------------------------------------------------
wire         gnd   =  1'b0;
wire   [3:0] gnd4  =  4'h0;
wire  [31:0] gnd32 = 32'h00000000;

reg [counterWidth-1: 0] Q;

always @(posedge clk, negedge rst) 
 begin
	if(~rst) begin
          Q <= 0;
          divOut <= 1'b0;
	end else if (Q == (maxCount -1)) begin
     	  Q <= 0;
      	  divOut <= ~divOut;
     	end else begin
	  Q <= Q + 1;
     	end
 end


//assign reset_cam = rst;
 
wire [31:0]  lm32i_adr,
             lm32d_adr,
             uart0_adr,
             timer0_adr,
             ddr0_adr,
             bram0_adr,
             sram0_adr,
             keypad0_adr,
             camera0_adr;


wire [31:0]  lm32i_dat_r,
             lm32i_dat_w,
             lm32d_dat_r,
             lm32d_dat_w,
             uart0_dat_r,
             uart0_dat_w,
             timer0_dat_r,
             timer0_dat_w,            
             bram0_dat_r,
             bram0_dat_w,
             sram0_dat_w,
             sram0_dat_r,
             ddr0_dat_w,
             ddr0_dat_r,
             keypad0_dat_r,
             keypad0_dat_w,
             camera0_dat_r,
             camera0_dat_w;

wire [3:0]   lm32i_sel,
             lm32d_sel,
             uart0_sel,
             timer0_sel,             
             bram0_sel,
             sram0_sel,
             ddr0_sel,
             keypad0_sel,
             camera0_sel;

wire         lm32i_we,
             lm32d_we,
             uart0_we,
             timer0_we,
             bram0_we,
             sram0_we,
             ddr0_we,
             keypad0_we,
             camera0_we;


wire         lm32i_cyc,
             lm32d_cyc,
             uart0_cyc,           
             timer0_cyc,             
             bram0_cyc,
             sram0_cyc,
             ddr0_cyc,
             keypad0_cyc,
             camera0_cyc;


wire         lm32i_stb,
             lm32d_stb,
             uart0_stb,             
             timer0_stb,            
             bram0_stb,
             sram0_stb,
             ddr0_stb,
             keypad0_stb,
             camera0_stb;

wire         lm32i_ack,
             lm32d_ack,
             uart0_ack,
             timer0_ack,             
             bram0_ack,
             sram0_ack,
             ddr0_ack,
             keypad0_ack,
             camera0_ack;


wire         lm32i_rty,
             lm32d_rty;

wire         lm32i_err,
             lm32d_err;

wire         lm32i_lock,
             lm32d_lock;

wire [2:0]   lm32i_cti,
             lm32d_cti;

wire [1:0]   lm32i_bte,
             lm32d_bte;

//---------------------------------------------------------------------------
// Interrupts
//---------------------------------------------------------------------------
wire [31:0]  intr_n;
wire         uart0_intr = 0;
wire   [1:0] timer0_intr;
wire         keypad0_intr;
wire         keypad0_intr_up;

debounce(.clk(clk), .PB(keypad0_intr), .PB_state(), .PB_up(keypad0_intr_up), .PB_down()); //antirrebote para generar solo una vez la tecla

assign intr_n = { 27'hFFFFFFF, ~keypad0_intr_up, ~timer0_intr[1], 1'b0, ~timer0_intr[0], ~uart0_intr };



//---------------------------------------------------------------------------
// Wishbone Interconnect
//---------------------------------------------------------------------------
conbus #(
	.s_addr_w(4),
	.s0_addr(4'h0),// bram       0x00000000 
	.s1_addr(4'h2),// uart0      0x20000000 
	.s2_addr(4'h3),// timer      0x30000000 
	.s3_addr(4'h4),// camera     0x40000000 
	.s4_addr(4'h5)// keypad     0x50000000 

) conbus0(
	.sys_clk( clk ),
	.sys_rst( ~rst ),
	// Master0
	.m0_dat_i(  lm32i_dat_w  ),
	.m0_dat_o(  lm32i_dat_r  ),
	.m0_adr_i(  lm32i_adr    ),
	.m0_we_i (  lm32i_we     ),
	.m0_sel_i(  lm32i_sel    ),
	.m0_cyc_i(  lm32i_cyc    ),
	.m0_stb_i(  lm32i_stb    ),
	.m0_ack_o(  lm32i_ack    ),
	// Master1
	.m1_dat_i(  lm32d_dat_w  ),
	.m1_dat_o(  lm32d_dat_r  ),
	.m1_adr_i(  lm32d_adr    ),
	.m1_we_i (  lm32d_we     ),
	.m1_sel_i(  lm32d_sel    ),
	.m1_cyc_i(  lm32d_cyc    ),
	.m1_stb_i(  lm32d_stb    ),
	.m1_ack_o(  lm32d_ack    ),


	// Slave0  bram
	.s0_dat_i(  bram0_dat_r ),
	.s0_dat_o(  bram0_dat_w ),
	.s0_adr_o(  bram0_adr   ),
	.s0_sel_o(  bram0_sel   ),
	.s0_we_o(   bram0_we    ),
	.s0_cyc_o(  bram0_cyc   ),
	.s0_stb_o(  bram0_stb   ),
	.s0_ack_i(  bram0_ack   ),
	// Slave1
	.s1_dat_i(  uart0_dat_r ),
	.s1_dat_o(  uart0_dat_w ),
	.s1_adr_o(  uart0_adr   ),
	.s1_sel_o(  uart0_sel   ),
	.s1_we_o(   uart0_we    ),
	.s1_cyc_o(  uart0_cyc   ),
	.s1_stb_o(  uart0_stb   ),
	.s1_ack_i(  uart0_ack   ),
	// Slave2
	.s2_dat_i(  timer0_dat_r ),
	.s2_dat_o(  timer0_dat_w ),
	.s2_adr_o(  timer0_adr   ),
	.s2_sel_o(  timer0_sel   ),
	.s2_we_o(   timer0_we    ),
	.s2_cyc_o(  timer0_cyc   ),
	.s2_stb_o(  timer0_stb   ),
	.s2_ack_i(  timer0_ack   ),
	// Slave3
	.s3_dat_i(  camera0_dat_r ),
	.s3_dat_o(  camera0_dat_w ),
	.s3_adr_o(  camera0_adr   ),
	.s3_sel_o(  camera0_sel   ),
	.s3_we_o(   camera0_we    ),
	.s3_cyc_o(  camera0_cyc   ),
	.s3_stb_o(  camera0_stb   ),
	.s3_ack_i(  camera0_ack   ),
	// Slave4
	.s4_dat_i( keypad0_dat_r  ),
	.s4_dat_o( keypad0_dat_w  ),
	.s4_adr_o( keypad0_adr    ),
	.s4_sel_o( keypad0_sel    ),
	.s4_we_o(  keypad0_we     ),
	.s4_cyc_o( keypad0_cyc    ),
	.s4_stb_o( keypad0_stb    ),
	.s4_ack_i( keypad0_ack    )
	
);


//---------------------------------------------------------------------------
// LM32 CPU 
//---------------------------------------------------------------------------
lm32_cpu lm0 (
	.clk_i(  clk  ),
	.rst_i(  ~rst  ),
	.interrupt_n(  intr_n  ),
	//
	.I_ADR_O(  lm32i_adr    ),
	.I_DAT_I(  lm32i_dat_r  ),
	.I_DAT_O(  lm32i_dat_w  ),
	.I_SEL_O(  lm32i_sel    ),
	.I_CYC_O(  lm32i_cyc    ),
	.I_STB_O(  lm32i_stb    ),
	.I_ACK_I(  lm32i_ack    ),
	.I_WE_O (  lm32i_we     ),
	.I_CTI_O(  lm32i_cti    ),
	.I_LOCK_O( lm32i_lock   ),
	.I_BTE_O(  lm32i_bte    ),
	.I_ERR_I(  lm32i_err    ),
	.I_RTY_I(  lm32i_rty    ),
	//
	.D_ADR_O(  lm32d_adr    ),
	.D_DAT_I(  lm32d_dat_r  ),
	.D_DAT_O(  lm32d_dat_w  ),
	.D_SEL_O(  lm32d_sel    ),
	.D_CYC_O(  lm32d_cyc    ),
	.D_STB_O(  lm32d_stb    ),
	.D_ACK_I(  lm32d_ack    ),
	.D_WE_O (  lm32d_we     ),
	.D_CTI_O(  lm32d_cti    ),
	.D_LOCK_O( lm32d_lock   ),
	.D_BTE_O(  lm32d_bte    ),
	.D_ERR_I(  lm32d_err    ),
	.D_RTY_I(  lm32d_rty    )
);
	
//---------------------------------------------------------------------------
// Block RAM
//---------------------------------------------------------------------------
wb_bram #(
	.adr_width( 14 ), //tamaño memoria ram, se debe modificar en sw y hw
	.mem_file_name( bootram_file)

) bram0 (
	.clk_i(  clk  ),
	.rst_i(  ~rst  ),
	//
	.wb_adr_i(  bram0_adr    ),
	.wb_dat_o(  bram0_dat_r  ),
	.wb_dat_i(  bram0_dat_w  ),
	.wb_sel_i(  bram0_sel    ),
	.wb_stb_i(  bram0_stb    ),
	.wb_cyc_i(  bram0_cyc    ),
	.wb_ack_o(  bram0_ack    ),
	.wb_we_i(   bram0_we     )
);



//---------------------------------------------------------------------------
// uart0
//---------------------------------------------------------------------------
wire uart0_rxd;
wire uart0_txd;

wb_uart #(
	.clk_freq( clk_freq        ),
	.baud(     uart_baud_rate  )
) uart0 (
	.clk( clk ),
	.reset( ~rst ),
	//
	.wb_adr_i( uart0_adr ),
	.wb_dat_i( uart0_dat_w ),
	.wb_dat_o( uart0_dat_r ),
	.wb_stb_i( uart0_stb ),
	.wb_cyc_i( uart0_cyc ),
	.wb_we_i(  uart0_we ),
	.wb_sel_i( uart0_sel ),
	.wb_ack_o( uart0_ack ), 
//	.intr(       uart0_intr ),
	.uart_rxd( uart0_rxd ),
	.uart_txd( uart0_txd )
);

//---------------------------------------------------------------------------
// timer0
//---------------------------------------------------------------------------
wb_timer #(
	.clk_freq(   clk_freq  )
) timer0 (
	.clk(      clk          ),
	.reset(    ~rst          ),
	//
	.wb_adr_i( timer0_adr   ),
	.wb_dat_i( timer0_dat_w ),
	.wb_dat_o( timer0_dat_r ),
	.wb_stb_i( timer0_stb   ),
	.wb_cyc_i( timer0_cyc   ),
	.wb_we_i(  timer0_we    ),
	.wb_sel_i( timer0_sel   ),
	.wb_ack_o( timer0_ack   ), 
	.intr(     timer0_intr  )
);



//---------------------------------------------------------------------------
// Keypad
//---------------------------------------------------------------------------

wb_keypad keypad (
   .clk(clk),
   .reset(~rst),
   // Wishbone interface
   .wb_stb_i(keypad0_stb),
   .wb_cyc_i(keypad0_cyc),
   .wb_ack_o(keypad0_ack),
   .wb_we_i(keypad0_we),
   .wb_adr_i(keypad0_adr),
   .wb_sel_i(keypad0_sel),
   .wb_dat_i(keypad0_dat_w),
   .wb_dat_o(keypad0_dat_r),
   // Keypad data
   .row(row),
   .column(column),
   .interrupt(keypad0_intr)
);

//---------------------------------------------------------------------------
// Camera
//---------------------------------------------------------------------------

wb_camera camera (
   .clk(clk),
   .reset(~rst),
   // Wishbone interface
   .wb_stb_i(camera0_stb),
   .wb_cyc_i(camera0_cyc),
   .wb_ack_o(camera0_ack),
   .wb_we_i (camera0_we),
   .wb_adr_i(camera0_adr),
   .wb_sel_i(camera0_sel),
   .wb_dat_i(camera0_dat_w),
   .wb_dat_o(camera0_dat_r),
   // Camera data
  .vsync(vsync), 
  .data(data),
  .href(href),
  .pclk(pclk)
  );


//----------------------------------------------------------------------------
// Mux UART wires according to sw[0]
//----------------------------------------------------------------------------
assign uart_txd  = uart0_txd;
assign uart0_rxd = uart_rxd;

reg [24:0]  counter;

always @(posedge clk or negedge rst) begin
    if(~rst)
        counter <= 0;
    else 
        counter <= counter + 1;
end

assign led      = counter[24];


endmodule 
