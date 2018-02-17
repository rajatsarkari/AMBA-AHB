//Global Parameters	
`define IDLE		2'b00
`define BUSY		2'b01
`define NON_SEQ		2'b10
`define SEQ		2'b11


`define OKAY  		2'b00
`define ERROR		2'b01
`define RETRY		2'b10
`define SPLIT		2'b11
//Top Level Module AMBA AHB SLAVE
module AMBA_AHB_SLAVE(HREADY, HRESP, HRDATA, HSPLITx, HSELx, HADDR, HWRITE, HTRANS, HSIZE, HBURST, HWDATA, HRESETn, HCLK, HMASTER, HMASTLOCK);
	//Input Output Declarations
	output 				HREADY;
	output	[1:0]			HRESP;
	output	[31:0]			HRDATA;
	output  [15:0]			HSPLITx;
	
	input				HMASTLOCK, HSELx, HWRITE, HRESETn, HCLK;
	input	[1:0]			HTRANS;
	input	[31:0]			HADDR;
	input	[31:0]			HWDATA;
	input	[2:0]			HBURST;
	input	[2:0]			HSIZE;
	input	[3:0]			HMASTER;	
	//Reg Declarations
	integer				COUNT_R, COUNT_W;
	
	reg				HREADY, WRAP;
	reg	[1:0]			HRESP;
	reg	[31:0]			HRDATA;
	reg	[15:0]			HSPLITx;
	//LOCAL VARIABLES
	reg	[3:0]			SPLIT_RESP;
	reg	[7:0]			mem[0:1024];
	//STAGE S1 PIPE REGISTERS
	reg	[31:0]			HADDR_S1;
	reg 	[31:0]			BASE_HADDR;
	reg	[1:0]			HTRANS_S1;
	reg	[31:0]			NUMBER_BYTES;
	reg	[31:0]			BURSTLEN, DT_SIZE, LOWWRAP, UPWRAP, UBL, LBL;
	reg	[31:0]			BURST_LEN_S1;
	reg 	[1:0]			HRESP_S1;
	//PARAMETERS
	localparam	SINGLE		= 3'D0,
			INCR		= 3'D1,
			WRAP4		= 3'D2,
			INCR4		= 3'D3,
			WRAP8		= 3'D4,
			INCR8		= 3'D5,
			WRAP16		= 3'D6,
			INCR16		= 3'D7;
	//STAGE S1 ----------------------------------ADDRESS AND CONTROL PHASE--------------------------------------------------------------------
	always@(posedge HCLK or negedge HRESETn)
		//Reset
		if(!HRESETn && HSELx) fork
			HREADY		<= 1;
			HRESP		<= `OKAY;
			HRDATA		<= 0;
			HSPLITx 	<= 0;
		join
		//Set
		else fork
			if(HRESETn && HSELx) fork
				//STAGE S1 PIPE registers 
				HTRANS_S1  	<= HTRANS;
				BASE_HADDR 	<= HADDR;
				HADDR_S1 	<= HADDR;
				HREADY 		<= 1;
				HRESP	 	<= `OKAY;
				if(HBURST == SINGLE) begin
				BURSTLEN 	<= 1;
				end
				if(HBURST == INCR) begin
				BURSTLEN 	<= 4;		
				end
				if(HBURST == WRAP4) begin
				BURSTLEN 	<= 4;
				WRAP  		<= 1;		
				end
				if(HBURST == INCR4) begin
				BURSTLEN 	<= 4;		
				end
				if(HBURST == WRAP8) begin
				BURSTLEN 	<= 8;
				WRAP  		<= 1;		
				end
				if(HBURST == INCR8) begin
				BURSTLEN 	<= 8;		
				end
				if(HBURST == WRAP16) begin
				BURSTLEN 	<= 16;
				WRAP  		<= 1;		
				end
				if(HBURST == INCR16) begin
				BURSTLEN 	<= 16;		
				end
				BURST_LEN_S1	<= BURSTLEN;
				NUMBER_BYTES 	<= 2**HSIZE;
				//DT_SIZE	<= NUMBER_BYTES * BURSTLEN;
				//ALIGNED_ADDR	<= (HADDR/NUMBER_BYTES) * NUMBER_BYTES;
				//ALIGNED	<= (HADDR == ALIGNED_ADDR);
//				LOWWRAP		<= (HADDR/DT_SIZE) * DT_SIZE;
//				UPWRAP		<= LOWWRAP + DT_SIZE;
				LBL		<= HADDR - ((HADDR/4)*4);
				UBL 		<= LBL + NUMBER_BYTES - 1;
				//HMASTER CHECK
			join
			/*2-CYCLE RESPONSE CHECK FOR HRESP
			if(HRESP == `SPLIT || HRESP == `RETRY || HRESP == `ERROR) begin
				HRESP_S1 	<= HRESP;
				HREADY 		<= 0;
			end*/
		join
	//STAGE S2 -------------------------------------DATA PHASE--------------------------------------------------------------------------------
	always@(posedge HCLK) begin
		if(HSELx && HREADY && HRESETn) begin
			DT_SIZE		<= NUMBER_BYTES * BURSTLEN;
			LOWWRAP		<= (HADDR/DT_SIZE) * DT_SIZE;
			UPWRAP		<= LOWWRAP + DT_SIZE;			
		end
		case(HTRANS_S1)
			`IDLE		://NO DATA TRANSFER
					begin
					HRESP <= `OKAY;
					end		
			`BUSY		://WAIT BETWEEN BURSTS
					begin
					HRESP <= `OKAY;
					end
			`NON_SEQ	://FIRST TRANSFER OF THE BURST OR THE SINGLE TRANSFER
					fork
					//2-CYCLE RESPONSE CHECK FOR HRESP
					if(HRESP_S1 == `SPLIT || HRESP_S1 == `RETRY || HRESP_S1 == `ERROR) begin
							HREADY 		<= 0;
					end
					//WRITE CHANNEL
					if(HWRITE && HREADY && HSELx && HRESP == `OKAY) fork
						for(COUNT_W = LBL; COUNT_W <= UBL; COUNT_W = COUNT_W + 1) begin
							mem[HADDR_S1] 	<= HWDATA[COUNT_W+:7];
							HADDR_S1 	<= HADDR_S1 + 1;
						end
							HRESP 		<= `OKAY;
							COUNT_W 	<= 0;
					join
					//READ CHANNEL
					if(!HWRITE && HREADY && HSELx && HRESP == `OKAY) fork
						for(COUNT_R = LBL; COUNT_R <= UBL; COUNT_R = COUNT_R + 1) begin
							HRDATA[COUNT_R+:7] 	<= mem[HADDR_S1];
							HADDR_S1 		<= HADDR_S1 + 1;
						end
							HRESP 		<= `OKAY;
							COUNT_R		<= 0;
					join
					join
			`SEQ		://BURST TRANSFER
					fork
					//2-CYCLE RESPONSE CHECK FOR HRESP
					if(HRESP_S1 == `SPLIT || HRESP_S1 == `RETRY || HRESP_S1 == `ERROR) begin
							HREADY 		<= 0;
							HADDR_S1	<= BASE_HADDR;
					end
					//WRITE CHANNEL
					if(HWRITE && HREADY && HSELx && HRESP == `OKAY) fork
						if(BURST_LEN_S1 > 1) begin
							for(COUNT_W = LBL; COUNT_W <= UBL; COUNT_W = COUNT_W + 1) begin
								mem[HADDR_S1] 	<= HWDATA[COUNT_W+:7];
								HADDR_S1	<= HADDR_S1 + 1;
							end
							if(HADDR_S1 >= UPWRAP) HADDR_S1 <= LOWWRAP;
							BURST_LEN_S1 	<= BURST_LEN_S1 - 1;
							HRESP 		<= `OKAY;
						end
					join
					//READ CHANNEL
					if(!HWRITE && HREADY && HSELx && HRESP == `OKAY) fork
						if(BURST_LEN_S1 > 1) begin
							for(COUNT_R = LBL; COUNT_R <= UBL; COUNT_R = COUNT_R + 1) begin
								HRDATA[COUNT_R+:7] 	<= mem[HADDR_S1];
								HADDR_S1 		<= HADDR_S1 + 1;
							end
							if(HADDR_S1 >= UPWRAP) HADDR_S1 <= LOWWRAP;						
							BURST_LEN_S1 	<= BURST_LEN_S1 - 1;
							HRESP 		<= `OKAY;
						end
					join
					join
			default:	begin
					HRESP	<= `OKAY;
					HREADY  <= 1;
					end
		endcase	
	end
	//--------------------------------------------------------------------------------------------------------------------------------------- 
endmodule
