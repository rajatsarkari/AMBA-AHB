//Global Parameters
`define IDLE  		3'b000
`define ACTIVE		3'b001
`define AGAIN		3'b010
`define LITTLE		3'b011

	
`define NON_SEQ		2'b00
`define SEQ		2'b01
`define BUSY		2'b01
`define IDLE_TRANS	2'b11


`define OKAY  		2'b00
`define ERROR		2'b01
`define RETRY		2'b10
`define SPLIT		2'b11

module amba_ahb_slave(HREADY, HRESP, HRDATA, HSPLITx, HSELx, HADDR, HWRITE, HTRANS, HSIZE, HBURST, HWDATA, HRESETn, HCLK, HMASTER, HMASTLOCK);

	//Input Output Declarations
	output 		HREADY;
	output	[1:0]	HTRANS;
	output	[1:0]	HRESP;
	output	[31:0]	HRDATA;
	output  [15:0]	HSPLITx;

	input		HMASTLOCK, HSELx, HWRITE, HRESETn, HCLK;
	input	[31:0]	HADDR;
	input	[31:0]	HWDATA;
	input	[2:0]	HBURST;
	input	[2:0]	HSIZE;
	input	[3:0]	HMASTER;	
	//Reg Declarations
	integer		count;

	reg		HREADY;
	reg	[1:0]	HTRANS;
	reg	[1:0]	HRESP;
	reg	[31:0]	HRDATA;
	reg	[15:0]	HSPLITx;

	reg	[31:0]	HADDR_temp;
	reg	[3:0]	SPLIT_RESP;
	reg	[2:0]	ps, ns;
	reg	[31:0]	memory_slave[0:31];

	//State Transitions
	always@(posedge HCLK) 			ps	<= ns;
	//Operation Starts
	always@(ps or ns or HRESETn or HSELx or HWDATA or HWRITE)
		case(ps)
		`IDLE:		if(!HRESETn && HSELx == 0)
					ns		= `IDLE;
				else begin
					HREADY		= 1;
					HADDR_temp	= HADDR;
					ns		= `ACTIVE;
					HTRANS		= `NON_SEQ;
				end
		`ACTIVE:	fork//HSIZE NOT Considered for the sake of simplicity
				if(HRESETn && HSELx && HWRITE && HREADY)
					case(HBURST)
					3'd0:begin
						memory_slave[HADDR_temp]= HWDATA;
						HREADY			= 1;
						HRESP			= `OKAY;
						HTRANS			= `NON_SEQ;
						ns			= `IDLE;		
					     end	
					3'd1:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 1;
						count			= count + 1;
						if(count > 32)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns		= `ACTIVE;	
					     end
					3'd2:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 4)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd3:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 4)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end
					3'd4:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 8)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd5:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 8)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end
					3'd6:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 16)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd7:begin
						memory_slave[HADDR_temp]= HWDATA;
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 16)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end					
					default:begin
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
					endcase
				if(HRESETn && HSELx && !HWRITE && HREADY)
					case(HBURST)
					3'd0:begin
						HRDATA			= memory_slave[HADDR_temp];
						HREADY			= 1;
						HRESP			= `OKAY;
						HTRANS			= `NON_SEQ;
						ns			= `IDLE;		
					     end	
					3'd1:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 1;
						count			= count + 1;
						if(count > 32)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns		= `ACTIVE;	
					     end
					3'd2:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 4)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd3:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 4)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end
					3'd4:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 8)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd5:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 8)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end
					3'd6:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 16)
						begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
						else begin
							ns 		= `ACTIVE;
							if(HADDR_temp[7:0] > 8'd12)
							begin
							//Address Wrap
							end
					 	end
					     end	
					3'd7:begin
						HRDATA			= memory_slave[HADDR_temp];
						HTRANS			= `SEQ;		
						HADDR_temp		= HADDR_temp + 4;
						count			= count + 1;
						if(count > 16)
							begin
							count		= 0;
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
							end
						else 	ns 		= `ACTIVE;
					     end					
					default:begin
							ns		= `IDLE;
							HREADY		= 1;	
							HRESP		= `OKAY;
							HTRANS		= `BUSY;
						end
					endcase
				if(!HREADY)
					begin
					ns 	 	= `AGAIN;
					HRESP		= `RETRY;
					end
				join
		`AGAIN:		if(HREADY)
					ns		= `ACTIVE;
				else
					ns		= `LITTLE;
		`LITTLE:	begin
					HRESP				= `SPLIT;
					SPLIT_RESP			= HMASTER;
					if(HMASTLOCK)
						ns			= `ACTIVE;
					else begin
						HSPLITx			= SPLIT_RESP;
						ns			= `IDLE;
					end		
				end
		endcase
	//Operation Ends			
endmodule
