`include "definitions.sv"
module ovi #()
(
	input CLK,

	

	//With VPU
	
	input vpu_issue_bus VPU_ISSUE,
	input vpu_dispatch_bus VPU_DISPATCH,
	input vpu_memop_bus VPU_MEMOP, 
	input vpu_load_bus VPU_LOAD,
	input VPU_MASK_IDX_CREDIT,

	output VPU_ISSUE_CREDIT,
	output vpu_completed_bus VPU_COMPLETED,
	output VPU_SYNC_START,
	output vpu_store_bus VPU_STORE,
	output VPU_STORE_CREDIT, 
	output vpu_mask_idx_bus VPU_MASK_IDX
	
);

//Standard outputs
assign VPU_ISSUE_CREDIT = 1'b0;


assign VPU_COMPLETED.sb_id =  1'b0; 
assign VPU_COMPLETED.fflags = 5'b0;	
assign VPU_COMPLETED.vxsat  = 1'b0;	
assign VPU_COMPLETED.valid  = 1'b0;	
assign VPU_COMPLETED.dest_reg = 64'b0;	
assign VPU_COMPLETED.vstart =  14'b0;	
assign VPU_COMPLETED.illegal = 1'b0;	
	
assign VPU_SYNC_START = 1'b0;
	


assign VPU_STORE.data = 512'b0;
assign VPU_STORE.valid = 1'b0;

	
assign VPU_STORE_CREDIT = 1'b0; 
	

assign VPU_MASK_IDX.item = 65'b0; 
assign VPU_MASK_IDX.valid = 1'b0;
assign VPU_MASK_IDX.last_idx = 1'b0;

/*
####################################################################
####################################################################
###################### FAKE VPU SIGNALS ############################
####################################################################
####################################################################
*/



//Declare types
typedef enum reg [3:0] {WAIT_ISSUE, ARITHMETIC, MEMORY, SEND_DATA, RCV_DATA ,EXEC_COMPLETED} state_t;

//Declare wires / regs
state_t curr_state /* verilator public */ = WAIT_ISSUE;


reg [3:0] alu_pipe /* verilator public */ = 3;
reg [3:0] mem_pipe /* verilator public */ = 5;

//Load and stores
reg instr_is_store = 0;
reg instr_is_load = 0;

reg [`OVI_MEMDATA_WIDTH-1:0] BUFFER_STORE [32];
reg [`OVI_MEMDATA_WIDTH-1:0] DATA_BUFFER [32];

reg [4:0] load_vreg;
reg [9:0] load_el_id;
reg [9:0] load_offset;
reg [6:0] load_el_count;
reg [3:0] load_sb_id;

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
			if (VPU_ISSUE.valid) begin
				issue_credits <= issue_credits - 1;
				//Change state
				instr_is_load <= VPU_ISSUE.instr[6:0] == 7'b0000111;
				instr_is_store <= VPU_ISSUE.instr[6:0] == 7'b0100111;
				curr_state <= instr_is_store ? MEMORY  [:]; : instr_is_load ? MEMORY : ARITHMETIC;

				//Arithmetic signals

				//Load signals
				VPU_SYNC_START <= 0;
				
				
			end
		end
		MEMORY: begin
			if (mem_pipe == 0) begin
				mem_pipe <= 5;
				curr_state <= instr_is_store ? SEND_DATA : instr_is_load ? RCV_DATA;
				VPU_SYNC_START <= 1;
			end
			else begin
				mem_pipe <= mem_pipe-1;
			end
		end
		ARITHMETIC: begin
			if (alu_pipe < 1) begin
				alu_pipe <= 3;
				curr_state <= EXEC_COMPLETE;
			end
			else begin
				alu_pipe <= alu_pipe-1;
			end
		end
		RCV_DATA: begin
			if (VPU_LOAD.valid)
				load_vreg <=  VPU_LOAD.sb_id[4:0];
				load_el_id <=  VPU_LOAD.sb_id[15:5];
				load_offset <=  VPU_LOAD.sb_id[21:16];
				load_el_count <=  VPU_LOAD.sb_id[28:22];
				load_sb_id <=  VPU_LOAD.sb_id[33:29];
				DATA_BUFFER[v_reg] <= VPU_LOAD.data;
			else if (VPU_MEMOP.sync_end) begin
				curr_state <= EXEC_COMPLETED;
			end else
			//Wait to receive data 
		end
		SEND_DATA: begin
			if (VPU_LOAD.valid)
				load_vreg <=  VPU_LOAD.sb_id[4:0];
				load_el_id <=  VPU_LOAD.sb_id[15:5];
				load_offset <=  VPU_LOAD.sb_id[21:16];
				load_el_count <=  VPU_LOAD.sb_id[28:22];
				load_sb_id <=  VPU_LOAD.sb_id[33:29];
				DATA_BUFFER[v_reg] <= VPU_LOAD.data;
			else if (VPU_MEMOP.sync_end) begin
				curr_state <= EXEC_COMPLETED;
			end else
			//Wait to receive data 
		end
		EXEC_COMPLETED: begin
			//Change state
			VPU_COMPLETED.valid <= 1'b0;
			curr_state <= WAIT_ISSUE;
		end
		
		default: begin
		end
	endcase

	if (VPU_ISSUE_CREDIT) begin
		issue_credits <= issue_credits + 1;
	end
	

end
endmodule
