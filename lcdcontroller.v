`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:06:57 01/07/2016 
// Design Name: 
// Module Name:    lcdcontroller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lcdcontroller(
CLK, LCD_RS, LCD_RW, LCD_E, DB_OUT4,DB_OUT5,DB_OUT6,DB_OUT7,RST
);
input CLK;			
input RST;


output LCD_RS, LCD_RW, LCD_E,DB_OUT4,DB_OUT5,DB_OUT6,DB_OUT7;


reg [7:0] DATA;
reg [1:0] OPER=2'b01;
reg RDY;
wire ENB=1;
reg [7:0] LCD_DB=0;
reg LCD_RW=0;			
reg LCD_RS=0;			
reg LCD_E=0;
reg DB_OUT4,DB_OUT5,DB_OUT6,DB_OUT7;

//===============================================================================================
//------------------------------Define the Character Parameters----------------------------------
//===============================================================================================
parameter [7:0]A=8'b01000001;
parameter [7:0]B=8'b01000010;
parameter [7:0]C=8'b01000011;
parameter [7:0]D=8'b01000100;
parameter [7:0]E=8'b01000101;
parameter [7:0]F=8'b01000110;
parameter [7:0]G=8'b01000111;
parameter [7:0]H=8'b01001000;
parameter [7:0]I=8'b01001001;
parameter [7:0]J=8'b01001010;
parameter [7:0]K=8'b01001011;
parameter [7:0]L=8'b01001100;
parameter [7:0]M=8'b01001101;
parameter [7:0]N=8'b01001110;
parameter [7:0]O=8'b01001111;
parameter [7:0]P=8'b01010000;

parameter [7:0]a=8'b01010001;
parameter [7:0]b=8'b01010010;
parameter [7:0]c=8'b01010011;
parameter [7:0]d=8'b01010100;
parameter [7:0]e=8'b01010101;
parameter [7:0]f=8'b01010110;
parameter [7:0]g=8'b01010111;
parameter [7:0]h=8'b01011000;
parameter [7:0]i=8'b01011001;
parameter [7:0]j=8'b01011010;
parameter [7:0]k=8'b01011011;
parameter [7:0]l=8'b01011100;
parameter [7:0]m=8'b01011101;
parameter [7:0]n=8'b01011110;
parameter [7:0]o=8'b01011111;
parameter [7:0]p=8'b01110000;

//===============================================================================================
//------------------------------Define the Timing Parameters-------------------------------------
//===============================================================================================
parameter [19:0] t_40ns 	= 1;		//40ns 		== ~1clk
parameter [19:0] t_250ns 	= 13;		//250ns 	== ~6clks
parameter [19:0] t_42us 	= 2000;		//42us 		== ~1008clks
parameter [19:0] t_100us 	= 50;		//100us		== ~2400clks
parameter [19:0] t_1640us 	= 55000;	//1.64ms 	== ~39360clks
parameter [19:0] t_4100us 	= 200400;	//4.1ms    	== ~98400clks
parameter [19:0] t_15000us	= 780000;	//15ms 		== ~360000clks
parameter [19:0] t_100micros 	= 500;

//===============================================================================================
//-----------------------------Create the counting mechanisms------------------------------------
//===============================================================================================
reg [19:0] cnt_timer=0; 			//39360 clks, used to delay the STATEmachine during a command execution (SEE above command set)
reg flag_40ns=0,flag_250ns=0,flag_42us=0,flag_100us=0,flag_1640us=0,flag_4100us=0,flag_15000us=0,flag_100micros=0;
reg flag_rst=1;					//Start with flag RST set. so that the counting has not started
reg [5:0] char_counter=0;

always @(posedge CLK) begin
	if(flag_rst) begin
		flag_40ns	<=	1'b0;		//Unlatch the flag
		flag_250ns	<=	1'b0;		//Unlatch the flag
		flag_42us	<=	1'b0;		//Unlatch the flag
		flag_100us	<=	1'b0;		//Unlatch the flag
		flag_1640us	<=	1'b0;		//Unlatch the flag
		flag_4100us	<=	1'b0;		//Unlatch the flag
		flag_15000us    <=	1'b0;		//Unlatch the flag
		flag_100micros<= 1'b0;
		cnt_timer	<=	20'b0;		
	end
	else begin
	//----------------------------
		if(cnt_timer>=t_100micros) begin			
			flag_100micros	<=	1'b1;
		end
		else begin			
			flag_100micros	<=	flag_100micros;
		end
		//----------------------------
		if(cnt_timer>=t_250ns) begin			
			flag_250ns	<=	1'b1;
		end
		else begin			
			flag_250ns	<=	flag_250ns;
		end
		//----------------------------
		if(cnt_timer>=t_42us) begin			
			flag_42us	<=	1'b1;
		end
		else begin			
			flag_42us	<=	flag_42us;
		end
		//----------------------------
		if(cnt_timer>=t_100us) begin			
			flag_100us	<=	1'b1;
		end
		else begin			
			flag_100us	<=	flag_100us;
		end
		//----------------------------
		if(cnt_timer>=t_1640us) begin			
			flag_1640us	<=	1'b1;
		end
		else begin			
			flag_1640us	<=	flag_1640us;
		end
		//----------------------------
		if(cnt_timer>=t_4100us) begin			
			flag_4100us	<=	1'b1;
		end
		else begin			
			flag_4100us	<=	flag_4100us;
		end
		//----------------------------
		if(cnt_timer>=t_15000us) begin			
			flag_15000us	<=	1'b1;
		end
		else begin			
			flag_15000us	<=	flag_15000us;
		end
		//----------------------------
		cnt_timer	<= cnt_timer + 1;
	end
end

always@(posedge CLK) begin
	if(RDY)
		if( char_counter < 33 )
			char_counter <= char_counter +1;
		else
			char_counter <= 0;
end

//##########################################################################################
//-----------------------------Create the STATE MACHINE------------------------------------
//##########################################################################################
reg [3:0] STATE=0;
reg [1:0] SUBSTATE=0;
reg second_write=0;

always @(posedge CLK) begin
	case(STATE)
		//---------------------------------------------------------------------------------------
		0: begin //---------------Initiate Command Sequence (RS=LOW)-----------------------------
			LCD_RS	<=		1'b0;										//Indicate an instruction is to be sent soon
			LCD_RW	<= 	1'b0;										//Indicate a write operation
			LCD_E		<=		1'b0;										//We are in the initial setup, keep low until 250ns has past
			LCD_DB 	<= 	8'b00000000;
			RDY					<= 1'b0;								//Indicate that the module is busy
			SUBSTATE	<=		0;
			if(!flag_15000us) begin									//WAIT 15ms...worst case scenario
				STATE				<=	STATE;						//Remain in current STATE
				flag_rst			<=	1'b0; 						//Start or Continue counting				
			end
			else begin 				
				STATE				<=	STATE+1;						//Go to next STATE
				flag_rst			<=	1'b1; 						//Stop counting				
			end		
		end
		//---------------------------------------------------------------------------------------
		1: begin //-----------SET FUNCTION #1, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b0;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b0;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b1;						
					DB_OUT5<= 1'b1;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_4100us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		2: begin //-----------SET FUNCTION #2, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b0;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b0;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b1;						
					DB_OUT5<= 1'b1;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_100micros) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		3: begin //-----------SET FUNCTION #3, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b0;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b0;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b1;						
					DB_OUT5<= 1'b1;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_4100us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		4: begin //-----------SET FUNCTION #4, 8-bit interface, 2-line display, 5x7 dots---------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b0;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b1;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b1;						
					DB_OUT5<= 1'b1;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_4100us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		5: begin //-----------------Function Set-------------------------------------------------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b1;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b1;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b0;						
					DB_OUT5<= 1'b1;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_42us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		6: begin //-------------------Entry Set Mode---------------------------------------------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b1;						
				DB_OUT5<= 1'b1;
				DB_OUT6<= 1'b0;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin													 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 								
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b0;						
					DB_OUT5<= 1'b0;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 												
				end
				if(flag_42us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		7: begin //---------Display On/Off-------------------------------------------------------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;							
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b1;						
				DB_OUT5<= 1'b1;
				DB_OUT6<= 1'b1;
				DB_OUT7<= 1'b1;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;							
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin							 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b0;						
					DB_OUT5<= 1'b0;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 													
				end
				if(flag_42us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end
		//---------------------------------------------------------------------------------------
		8: begin //------------------------Clear Display----------------------------------------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= 1'b1;						
				DB_OUT5<= 1'b0;
				DB_OUT6<= 1'b0;
				DB_OUT7<= 1'b0;	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;							
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 									
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin					
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= 1'b0;						
					DB_OUT5<= 1'b0;
					DB_OUT6<= 1'b0;
					DB_OUT7<= 1'b0;
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 														
				end
				if(flag_42us) begin
					STATE<=STATE+1;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end
		//---------------------------------------------------------------------------------------
		9: begin //-------------------WAIT 1,64ms-----------------------------------------------		
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;							
			RDY					<= 1'b0;						
			if(SUBSTATE==0)begin	 						
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin				
				if(!flag_1640us) begin						
					SUBSTATE		<=	SUBSTATE;				
					flag_rst		<=	1'b0; 														
				end
				else begin 				
					SUBSTATE		<=	0;				
					STATE			<=	STATE+1;
					flag_rst		<=	1'b1; 									
				end
			end
		end
		//---------------------------------------------------------------------------------------
		10: begin//----------------------------- WRITE DATA -------------------------------------
			LCD_RS				<=	1'b1;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst		<=	1'b0; 					
			if(SUBSTATE==0 )begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= DATA[0];						
				DB_OUT5<= DATA[1];
				DB_OUT6<= DATA[2];
				DB_OUT7<= DATA[3];	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;								
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 									
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= DATA[4];						
					DB_OUT5<= DATA[5];
					DB_OUT6<= DATA[6];
					DB_OUT7<= DATA[7];
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 													
				end
				if(flag_42us) begin
					STATE<=13;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		11: begin//----------------------- WRITE INSTRUCTION ------------------------------------
			LCD_RS				<=	1'b0;						
			LCD_RW				<=	1'b0;						
			RDY					<= 1'b0;						
			flag_rst<=1'b0;
			if(SUBSTATE==0)begin	 		
				LCD_E				<=	1'b0;						
				LCD_DB 			<=	LCD_DB;					
				STATE				<=	STATE;				
				SUBSTATE			<=	1;
			end			
			if(SUBSTATE==1)begin
				SUBSTATE		<=	SUBSTATE;				
				DB_OUT4<= DATA[0];						
				DB_OUT5<= DATA[1];
				DB_OUT6<= DATA[2];
				DB_OUT7<= DATA[3];	
					if (flag_40ns == 1) begin
						LCD_E	<=	1'b1;							
						flag_rst<=1'b0;
					end
					if(flag_250ns == 1) begin															 				
						LCD_E<=	1'b0;
						SUBSTATE<=	SUBSTATE+1;				
						flag_rst<=	1'b1; 										
					end
			end
			if(SUBSTATE==2)begin
										
				LCD_DB<= LCD_DB;					
				flag_rst		<=	1'b0; 					
				if(flag_100us == 1) begin						
					flag_rst		<=	1'b1;
					SUBSTATE <= SUBSTATE +1;
				end
				else begin
					STATE<=STATE;
					SUBSTATE<=2;
				end	
			end
			if(SUBSTATE==3)begin
					flag_rst		<=	1'b0;
					LCD_E	<=	1'b1;
					DB_OUT4<= DATA[4];						
					DB_OUT5<= DATA[5];
					DB_OUT6<= DATA[6];
					DB_OUT7<= DATA[7];
				if(flag_250ns) begin						
					LCD_E	<=	1'b0;				
					flag_rst		<=	1'b0; 													
				end
				if(flag_42us) begin
					STATE<=13;
					SUBSTATE<=0;
					flag_rst<=	1'b1;
				end
			end
		end	
		//---------------------------------------------------------------------------------------
		13:
						begin//----------This is the IDLE STATE, DO NOTHING UNTIL OPER is set-----------
							LCD_RS	<=		LCD_RS;								
							LCD_RW	<= 	1'b0;									
							LCD_DB 	<= 	LCD_DB;								
							LCD_E		<=		1'b0;									
							RDY		<=		1'b1;									
							if(RST==0)begin
								case(OPER)
									0:STATE<=STATE; 	
									1:STATE<=10;		
									2:STATE<=11;		
									3:STATE<=0;			
								endcase
							end
							else if(ENB ==1 && RST==1)begin
								STATE<=0;
							end
						end
	endcase
end
// writen data handler
always@(posedge CLK)begin
	case(char_counter)
		0:		begin
				DATA <=  A;
				OPER <= 2'b01;
				end
		1:		begin
				DATA <=  B;
				OPER <= 2'b01;
				end
		2:DATA <=  C;
		3:DATA <=  D;
		4:DATA <=  E;
		5:DATA <=  F;
		6:DATA <=  G;
		7:DATA <=  H;
		8:DATA <=  I;
		9:DATA <=  J;
		10:DATA <=  K;
		11:DATA <=  L;
		12:DATA <=  M;
		13:DATA <=  N;
		14:DATA <=  O;
		15:	begin
				DATA <=  P;
				OPER <= 2'b10;
				end
		16:	begin
					DATA <= 8'b11000000; // changes lines
					OPER <= 2'b01;
				end			
		17:DATA <=  a;
		18:DATA <=  b;
		19:DATA <=  c;
		20:DATA <=  d;
		21:DATA <=  e;
		22:DATA <=  f;
		23:DATA <=  g;
		24:DATA <=  h;
		25:DATA <=  i;
		26:DATA <=  j;
		27:DATA <=  k;
		28:DATA <=  l;
		29:DATA <=  m;
		30:DATA <=  n;
		31:DATA <=  o;
		32:DATA <=  p;
	endcase
end


		
endmodule