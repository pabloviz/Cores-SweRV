`include "definitions.sv"
module automata #()
(
	input CLK,
	input CORE_HALT,
	input core_completed_bus CORE_COMPLETED,
	output core_issue_bus CORE_ISSUE,
	input core_petition_loadstore_bus CORE_PETITION_LOADSTORE,
	output core_response_loadstore_bus CORE_RESPONSE_LOADSTORE
);

//Declare types
typedef enum reg [2:0] {REST, READ_AND_ISSUE, WAIT_ANSWER} state_t;


//Declare wires / regs
state_t curr_state /*verilator public*/ = REST;
reg [`OVI_VL_WIDTH-1: 0] vl = 8; //8 elements per vector
reg [`OVI_SEW_WIDTH-1: 0] sew = 2; //32-bit elements
wire halt;
wire [`OVI_INSTR_WIDTH-1:0] read_instruction;

reg [3:0] delay = 1;
//Assign wire values
assign halt = CORE_HALT | (delay != 0) | read_instruction == -1;
assign read_instruction = MEM[mem_ptr];
assign CORE_ISSUE.instr = read_instruction; 
assign CORE_ISSUE.opnd = read_instruction[19:15]; //hardcode x0=0, x1=1, x2=2, ...
assign CORE_ISSUE.vl = vl;
assign CORE_ISSUE.sew = sew;
assign CORE_ISSUE.valid = (curr_state==READ_AND_ISSUE && !halt) ? 1'b1 : 1'b0;
//xv_arith =[.................010.....1010111] && not reduction
assign CORE_ISSUE.wb = read_instruction[14:12]==3'b010 && read_instruction[6:0]==7'b1010111 && read_instruction[31:26]!=0;


//Instruction memory
reg [6-1:0] mem_ptr = 0;
reg [`OVI_INSTR_WIDTH-1:0] MEM [64]; //instruction memory, 64 instructions of 32 bits
reg [16-1:0] VLSEWMEM [2]; //instruction memory, 64 instructions of 32 bits

//Data memory with just one word
reg [32-1:0] LMEM = 0;
reg [32-1:0] SMEM = 0;
reg[32-1:0] reg_loaddata = 0;
reg [7:0] reg_memready = 0;
reg [7:0] reg_memvalid = 0;
reg is_load = 0;
wire datavalid = reg_memvalid==1;
wire memready = reg_memready==0;
assign CORE_RESPONSE_LOADSTORE.load_valid = datavalid && is_load;
assign CORE_RESPONSE_LOADSTORE.load_data = LMEM;
assign CORE_RESPONSE_LOADSTORE.mem_ready = memready && !CORE_PETITION_LOADSTORE.load_valid && !CORE_PETITION_LOADSTORE.store_valid;

initial
begin
    integer i;
    for (i=0; i < 64; i=i+1)
    begin
        MEM[i] = 32'b0;
    end
    $readmemh("memfiles/program.mem", MEM);
    $readmemh("memfiles/vl.mem", VLSEWMEM);
 end

always @(posedge CLK)
begin
	vl <= VLSEWMEM[0];
	sew <= VLSEWMEM[1];
	if (delay != 0) begin
		delay <= delay + 1;
	end
	if (reg_memready != 0) begin
		reg_memready <= reg_memready - 1;
		if (reg_memready == 3) begin
			reg_memvalid <= 5;
		end
	end
	if (reg_memvalid != 0) begin
		reg_memvalid <= reg_memvalid - 1;
	end
	if (reg_memvalid == 1 && is_load) begin
		LMEM <= LMEM + 1;
	end
	case(curr_state)
			
		REST: begin
			//Change state
			if (!halt) begin
				curr_state <= READ_AND_ISSUE;
			end
		end
		READ_AND_ISSUE: begin
			mem_ptr <= mem_ptr + 1;
			//Change state
			curr_state <= WAIT_ANSWER;
		end

		WAIT_ANSWER: begin
			//Change state
			if (CORE_COMPLETED.valid) begin
				if (!halt) begin
					curr_state <= READ_AND_ISSUE;
				end else begin
					curr_state <= REST;
				end
			end
			if (CORE_PETITION_LOADSTORE.load_valid) begin
				reg_memready <= 6;
				is_load <= 1'b1;
			end
			if (CORE_PETITION_LOADSTORE.store_valid) begin
				reg_memready <= 6;
				is_load <= 1'b0;
				SMEM <= CORE_PETITION_LOADSTORE.store_data;
			end
		end
		default: begin
		end
	endcase
end

endmodule
