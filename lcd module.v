module lcdDecoder(CLK, DATA, DATAU, DATAD, DATAL, DATAR, LCD_RS, LCD_RW, LCD_E, LCD_DB);

input CLK;	// CLK is an internal 50MHz clock
input [7:0] DATA, DATAU, DATAD, DATAL, DATAR; // Data to be interpreted by the LCD Module, sent from Navigation Module
output reg LCD_RS, LCD_RW, LCD_E; // Outputs sent to LCD display, indicate read/write and command/instruction operations
output reg [7:0] LCD_DB; //Output sent to LCD display, holds values corresponding to outputs needed to complete specific commands


// - Define parameters corresponding to basic commands that the LCD must execute 

parameter [7:0] CLEAR = 8'b00000001; // Clear Display
parameter [7:0] SETUP	= 8'b001110xx;	//Sets to 8-bit operation and selects 2-line display and 5x8 dot character font.
parameter [7:0] DISP_ON	= 8'b00001100;	//Turns on display and cursor.
parameter [7:0] ENTRY_N	= 8'b00000110;	//Sets mode to increment the address by one and to shift the cursor to the right at the time of write to the DD/CGRAM.
parameter [7:0] LINE	= 8'b11000000;	// Sets DDRAM address so that the cursor is positioned on second line


// - Define parameters corresponding to ascii characters that will be displayed 

parameter [7:0] R = 8'b01010010; 
parameter [7:0] O = 8'b01001111;	
parameter [7:0] M = 8'b01001101;	
parameter [7:0] COLON = 8'b00111010;
parameter [7:0] SPACE = 8'b00100000;
parameter [7:0] U = 8'b01010101;
parameter [7:0] D = 8'b01000100;
parameter [7:0] L = 8'b01001100;
parameter [7:0] RI = 8'b01010010;



// - Define parameters for an internal countrer  

parameter [24:0] countrerinc1 = 14;	// 250ns = ~14 clock cycles
parameter [24:0] countrerinc2 = 216480;	// 4.1ms = ~216480 clock cycles
parameter [24:0] countrerinc3 = 792000;	// ~15ms = ~792000 clock cycles
parameter [40:0] countrerinc4 = 30900000; // ~.6 s = ~30900000 clock cycles
 

 // - Define the internal countrer

reg [40:0] countr=0; 
reg count_mark1=0,count_mark2=0,count_mark3=0,flag_1s=0;
reg counter_start=1;	// when counter_start is 0, counting begins; otherwise countr resets to 0 and does not begin until prompted 
 
always @(posedge CLK) begin
if(counter_start) begin
count_mark1	<=	1'b0;	
count_mark2	<=	1'b0;	
count_mark3 <=	1'b0;	
flag_1s <=	1'b0;
countr	<=	20'b0;	
end
else begin
if(countr>=countrerinc1) begin	
count_mark1	<=	1'b1;
end
else begin	
count_mark1	<=	count_mark1;
end
//----------------------------
if(countr>=countrerinc2) begin	
count_mark2	<=	1'b1;
end
else begin	
count_mark2	<=	count_mark2;
end
//----------------------------
if(countr>=countrerinc3) begin	
count_mark3	<=	1'b1;
end
else begin	
count_mark3	<=	count_mark3;
end
if(countr>=countrerinc4) begin	
flag_1s	<=	1'b1;
end
else begin	
flag_1s	<=	flag_1s;
end
//----------------------------
countr	<= countr + 1;
end
end

// - Finite State Machine


reg [10:0] STATE=0;
reg [1:0] SUBSTATE=0;
 
always @(posedge CLK) begin
case(STATE)

0: begin //---------------clear, E = 0
LCD_RS	<=	1'b0;	//Instruction
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= CLEAR;    
SUBSTATE	<=	0;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

1: begin //-----------clear, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

2: begin //---------------setup, E = 0
LCD_RS	<=	1'b0;	//Instruction
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= SETUP;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

3: begin //-----------setup, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

4: begin //---------------display, E = 0
LCD_RS	<=	1'b0;	//Instruction
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DISP_ON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

5: begin //-----------display, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

6: begin //---------------entry mode, E = 0
LCD_RS	<=	1'b0;	//Instruction
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= ENTRY_N;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

7: begin //-----------entry mode, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

8: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= R;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

9: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

10: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= O;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

11: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

12: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= O;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

13: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

14: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= M;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

15: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

16: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= COLON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

17: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

18: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DATA;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

19: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

20: begin //---------------setup, E = 0
LCD_RS	<=	1'b0;	//Instruction
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= LINE;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

21: begin //-----------setup, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

22: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= U;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

23: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

24: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= COLON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

25: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

26: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DATAU;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

27: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

28: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= SPACE;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

29: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

30: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= D;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

31: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

32: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= COLON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

33: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

34: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DATAD;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

35: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

36: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= SPACE;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

37: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

38: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= L;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

39: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

40: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= COLON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

41: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

42: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DATAL;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

43: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

44: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= SPACE;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

45: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

46: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= RI;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

47: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

48: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= COLON;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

49: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

50: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= DATAR;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

51: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

52: begin //-----------write character, E = 0
LCD_RS	<=	1'b1;	
LCD_RW	<= 1'b0;	//Write operation
LCD_E	<=	1'b0;	
LCD_DB <= SPACE;
SUBSTATE	<=	SUBSTATE;
if(!count_mark3) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
counter_start	<=	1'b1; //Stop and reset counter
end	
end

53: begin //-----------write character, E = 1

if(SUBSTATE==0)begin	
LCD_E	<=	1'b1;	
if(!count_mark1) begin	
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
SUBSTATE	<=	SUBSTATE+1;	//Progress to next substate
counter_start	<=	1'b1; //Stop and reset counter
end
end

if(SUBSTATE==1)begin
LCD_E	<=	1'b0;	//Disable En, lcd reads DATA during negedge of En
if(!count_mark2) begin	
STATE	<=	STATE;	//Maintain state
SUBSTATE	<=	SUBSTATE;	//Maintain substate
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	STATE+1;	//Progress to next state
SUBSTATE	<=	0;	//Reset substate
counter_start	<=	1'b1; //Stop and reset counter
end
end	
end

default: begin // - Idle state
if(!flag_1s) begin	
STATE	<=	STATE;	//Remain in state
counter_start	<=	1'b0; //Begin counter
end
else begin
STATE	<=	0;	//Reset to state 0
counter_start	<=	1'b1; //Stop and reset counter
end	
end

endcase
end
endmodule


