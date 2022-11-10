`include "definitions.sv"
module automata #()
(
	input CLK,
	input CORE_HALT,
	input core_completed_bus CORE_COMPLETED,
	output core_issue_bus CORE_ISSUE
	
);

//Declare types
typedef enum reg [2:0] {REST, READ_AND_ISSUE, WAIT_ANSWER, RECEIVE_DATA} state_t;


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
assign CORE_ISSUE.vl = vl;
assign CORE_ISSUE.sew = sew;
assign CORE_ISSUE.valid = (curr_state==READ_AND_ISSUE && !halt) ? 1'b1 : 1'b0;

wire [64-1:0] bits = sew==0 ? 8 : sew==1 ? 16 : sew==2? 32 : 64;
wire [64-1:0] n_packets = (vl*bits)/512;
reg [64-1:0] received_packets = 0;
//Instruction memory
reg [6-1:0] mem_ptr = 0;
reg [`OVI_INSTR_WIDTH-1:0] MEM [64]; //instruction memory, 64 instructions of 32 bits
reg [16-1:0] VLSEWMEM [2]; //instruction memory, 64 instructions of 32 bits
initial
begin
    integer i;
    for (i=0; i < 64; i=i+1)
    begin
        MEM[i] = 32'b0;
    end
    $readmemh("memfiles/arith.mem", MEM);
    $readmemh("memfiles/vl.mem", VLSEWMEM);
 end


always @(posedge CLK)
begin
	vl <= VLSEWMEM[0];
	sew <= VLSEWMEM[1];
	if (delay != 0) begin
		delay <= delay + 1;
	end
	//default outputs
	case(curr_state)
		REST: begin
			//Change state
			if (!halt) begin
				curr_state <= READ_AND_ISSUE;
			end
		end
		READ_AND_ISSUE: begin
			//Change state
			mem_ptr <= mem_ptr + 1;
			curr_state <= WAIT_ANSWER;
			received_packets <= 0;
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
			else if (0) begin //core sync start & instruction_is_store
				curr_state <= RECEIVE_DATA;
			end
		end
		RECEIVE_DATA: begin
			if (received_packets == n_packets) begin
				//sync_end = 1
				curr_state <= WAIT_ANSWER;
			end
			else begin
				if (0) begin //store data valid
				//fakememory[received_packets] = coredata
				received_packets <= received_packets+1;
				end
			end
		end

		default: begin
		end
	endcase
end

endmodule
