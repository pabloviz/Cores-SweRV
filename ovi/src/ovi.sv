`include "definitions.sv"
module ovi #()
(
	input CLK,

	//With core
	input core_issue_bus CORE_ISSUE,
	output core_completed_bus CORE_COMPLETED,
	output CORE_HALT,
	//Misssing load, store, mask signals!

	//With VPU
	input VPU_ISSUE_CREDIT,
	input vpu_completed_bus VPU_COMPLETED,
	input VPU_SYNC_START,
	input vpu_store_bus VPU_STORE,
	input vpu_mask_idx_bus VPU_MASK_IDX,
	output vpu_issue_bus VPU_ISSUE,
	output vpu_dispatch_bus VPU_DISPATCH,
	output vpu_memop_bus VPU_MEMOP, 
	output vpu_load_bus VPU_LOAD,
	output VPU_STORE_CREDIT, 
	output VPU_MASK_IDX_CREDIT
	
);

//Declare types
typedef enum reg [1:0] {WAIT_ISSUE, WAIT_ANSWER, RECEIVE_DATA, SEND_DATA} state_t;


//Declare wires / regs
state_t curr_state /* verilator public */ = WAIT_ISSUE;
reg [3:0] issue_credits /* verilator public */= 4;
v_csr vcsr;
reg [`OVI_SBID_WIDTH-1:0] sbid_counter = 0;
reg [4:0] store_credits = 1; //1 is easier to debug :)

//Load Store
reg instr_is_store = 0;
reg instr_is_load = 0;
reg [5-1:0] instr_reg;
reg [`OVI_VL_WIDTH-1: 0] instr_vl;
reg [64-1:0] n_packets; 
reg [64-1:0] transmited_packets = 0;
reg [`OVI_MEMDATA_WIDTH-1:0] BUFFER_STORE [32];
reg [`OVI_MEMDATA_WIDTH-1:0] BUFFER_LOAD [32];
wire [64-1:0] instrlogbits = CORE_ISSUE.sew==0 ? 3 : CORE_ISSUE.sew==1 ? 4 : CORE_ISSUE.sew==2? 5 : 6;


//Asigns
assign CORE_HALT = curr_state!=WAIT_ISSUE || issue_credits==0? 1'b1 : 1'b0;

//Issue bus (construct it from core issue)
assign VPU_ISSUE.instr = CORE_ISSUE.instr;
assign VPU_ISSUE.scalar_opnd = 64'b0;
assign VPU_ISSUE.sb_id = sbid_counter; 
assign VPU_ISSUE.vcsr.vstart = `OVI_VSTART_WIDTH'b0; 
assign VPU_ISSUE.vcsr.vl = CORE_ISSUE.vl;
assign VPU_ISSUE.vcsr.vxrm = 2'b0;
assign VPU_ISSUE.vcsr.frm = 3'b0;
assign VPU_ISSUE.vcsr.vlmul = 2'b0;
assign VPU_ISSUE.vcsr.vsew = CORE_ISSUE.sew;
assign VPU_ISSUE.vcsr.vill = 1'b0;
assign VPU_ISSUE.valid = (curr_state==WAIT_ISSUE && issue_credits>0 && CORE_ISSUE.valid) ?   1'b1 : 1'b0;

//Dispatch: Always on issue (for now)
assign VPU_DISPATCH.kill = 1'b0;
assign VPU_DISPATCH.sb_id = VPU_ISSUE.sb_id;
assign VPU_DISPATCH.next_senior = VPU_ISSUE.valid;

//Completed bus (just pass data)
assign CORE_COMPLETED.data = VPU_COMPLETED.dest_reg;
assign CORE_COMPLETED.valid = VPU_COMPLETED.valid; //This may change in the future

//Memop (right now at 0)
assign VPU_MEMOP.sync_end = (curr_state == RECEIVE_DATA || curr_state == SEND_DATA) && (transmited_packets == n_packets) ? 1'b1 : 1'b0;
assign VPU_MEMOP.sb_id = sbid_counter - 1;

//Load (right now at 0)
assign VPU_LOAD.valid = (curr_state == SEND_DATA) && (transmited_packets<n_packets); //This may change when we connect the core
assign VPU_LOAD.data = BUFFER_LOAD[transmited_packets];
assign VPU_LOAD.mask_valid = 1'b0;
assign VPU_LOAD.seq_id.v_reg = instr_reg; 
wire [10:0] el_id = transmited_packets * (512>>instrlogbits);
wire [6:0] el_count = transmited_packets==n_packets-1 ? instr_vl % (512>>instrlogbits) : (512>>instrlogbits);
assign VPU_LOAD.seq_id.el_id = el_id; 
assign VPU_LOAD.seq_id.el_off = 0;
assign VPU_LOAD.seq_id.el_count = el_count; 
assign VPU_LOAD.seq_id.sb_id = sbid_counter - 1;

//Store
assign VPU_STORE_CREDIT = VPU_STORE.valid;


//Mask (right now at 0)
assign VPU_MASK_IDX.valid = 1'b0;
assign VPU_MASK_IDX.last_idx = 1'b0;
//Mask credit (right now at 0)
assign VPU_MASK_IDX_CREDIT = 1'b0;


initial
begin
    integer i;
    integer j;
    for (i=0; i < 32; i=i+1)
    begin
        BUFFER_STORE[i] = 512'b0;
	for(j=0; j<512; j+=32)
	begin
		BUFFER_LOAD[i][j+:32] <= 3;
	end
    end
 end

always @(posedge CLK)
begin
	//Fill issue bus
	case(curr_state)
		WAIT_ISSUE: begin
			if (issue_credits > 0 && CORE_ISSUE.valid) begin
				issue_credits <= issue_credits - 1;
				sbid_counter <= sbid_counter + 1;
				transmited_packets <= 0;
				n_packets <= (CORE_ISSUE.vl<<instrlogbits)/512 + (((CORE_ISSUE.vl<<instrlogbits)%512!=0)? 1 : 0);
				instr_vl <= CORE_ISSUE.vl;
				instr_is_load <= CORE_ISSUE.instr[6:0] == 7'b0000111;
				instr_is_store <= CORE_ISSUE.instr[6:0] == 7'b0100111;
				instr_reg <= CORE_ISSUE.instr[11:7];
				//Change state
				curr_state <= WAIT_ANSWER;
			end
		end
		WAIT_ANSWER: begin
			//Change state
			if (VPU_COMPLETED.valid) begin
				curr_state <= WAIT_ISSUE;
			end
			else if (VPU_SYNC_START) begin 
				curr_state <= instr_is_store ? RECEIVE_DATA : instr_is_load ? SEND_DATA : WAIT_ANSWER;
			end
		end
		RECEIVE_DATA: begin
			if (transmited_packets == n_packets) begin
				curr_state <= WAIT_ANSWER;
			end
			else begin
				if (VPU_STORE.valid) begin 
					BUFFER_STORE[transmited_packets] <= VPU_STORE.data;
					transmited_packets <= transmited_packets+1;
				end
			end
		end
		SEND_DATA: begin
			if (transmited_packets == n_packets) begin
				curr_state <= WAIT_ANSWER;
			end
			else begin
				transmited_packets <= transmited_packets+1;
			end
		end
		default: begin
		end
	endcase

	if (VPU_ISSUE_CREDIT) begin
		issue_credits <= issue_credits + 1;
	end
	

end
endmodule
