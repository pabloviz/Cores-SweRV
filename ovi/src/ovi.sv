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
	input VPU_STORE_CREDIT, 
	input vpu_mask_idx_bus VPU_MASK_IDX,
	output vpu_issue_bus VPU_ISSUE,
	output vpu_dispatch_bus VPU_DISPATCH,
	output vpu_memop_bus VPU_MEMOP, 
	output vpu_load_bus VPU_LOAD,
	output VPU_MASK_IDX_CREDIT
	
);

//Declare types
typedef enum reg [1:0] {WAIT_ISSUE, WAIT_COMPLETED} state_t;


//Declare wires / regs
state_t curr_state /* verilator public */ = WAIT_ISSUE;
reg [3:0] issue_credits /* verilator public */= 4;
v_csr vcsr;


//Asigns
assign CORE_HALT = curr_state!=WAIT_ISSUE || issue_credits==0? 1'b1 : 1'b0;

//Issue bus (construct it from core issue)
assign VPU_ISSUE.instr = CORE_ISSUE.instr;
assign VPU_ISSUE.scalar_opnd = 64'b0;
assign VPU_ISSUE.sb_id = `OVI_SBID_WIDTH'b0;
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
assign VPU_MEMOP.sync_end = 1'b0;

//Load (right now at 0)
assign VPU_LOAD.valid = 1'b0;
assign VPU_LOAD.mask_valid = 1'b0;

//Store (right now at 0)
assign VPU_STORE.valid = 1'b0;

//Mask (right now at 0)
assign VPU_MASK_IDX.valid = 1'b0;
assign VPU_MASK_IDX.last_idx = 1'b0;
//Mask credit (right now at 0)
assign VPU_MASK_IDX_CREDIT = 1'b0;


always @(posedge CLK)
begin
	//Fill issue bus
	case(curr_state)
		WAIT_ISSUE: begin
			if (issue_credits > 0 && CORE_ISSUE.valid) begin
				issue_credits <= issue_credits - 1;
				//Change state
				curr_state <= WAIT_COMPLETED;
			end
		end
		WAIT_COMPLETED: begin
			//Change state
			if (VPU_COMPLETED.valid) begin
				curr_state <= WAIT_ISSUE;
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
