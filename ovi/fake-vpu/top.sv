`include "definitions.sv"
module top #()
(
	input CLK,
	input RESET
);


//Core signals
wire core_halt /* verilator public */;
core_completed_bus core_completed;
core_issue_bus core_issue;

//Vpu signals
wire issue_credit;
vpu_completed_bus vpu_completed;
vpu_issue_bus vpu_issue;
vpu_dispatch_bus vpu_dispatch;
wire vpu_sync_start;
vpu_store_bus vpu_store;
wire vpu_store_credit;
vpu_mask_idx_bus vpu_mask_idx;
vpu_memop_bus vpu_memop;
vpu_load_bus vpu_load;
wire vpu_mask_idx_credit;


//Some extra I/O of the VPU
/*
// LOAD_FINISH
output                      load_finish_valid_o, // TO AVISPADO
output [SB_WIDTH-1:0]       load_finish_sb_id_o, // TO AVISPADO
output                      load_finish_no_retry_o, // TO AVISPADO

// DEBUG INTERFACE
input                       dbg_re_i,
input                       dbg_we_i,
input [DBG_ADDR_WIDTH-1:0]  dbg_address_i, 
output [DBG_DATA_WIDTH-1:0] dbg_read_data_o,
output                      dbg_read_data_valid_o,
input [DBG_DATA_WIDTH-1:0]  dbg_write_data_i,

// PMU INTERFACE
input [N_HPM-1:0][HPM_EVENT_WIDTH-1:0]      hpm_vpu_event_i,
output [N_HPM-1:0]                          hpm_vpu_count_o
*/


automata #() core_automata
(
	.CLK(CLK),
	.CORE_HALT(core_halt),
	.CORE_COMPLETED(core_completed),
	.CORE_ISSUE(core_issue)
);


ovi #() ovi_module 
(
	.CLK(CLK),

	//With core
	.CORE_ISSUE(core_issue),
	.CORE_COMPLETED(core_completed),
	.CORE_HALT(core_halt),

	//With VPU
	.VPU_ISSUE_CREDIT(issue_credit),
	.VPU_COMPLETED(vpu_completed),
	.VPU_SYNC_START(vpu_sync_start),
	.VPU_STORE(vpu_store),
	.VPU_STORE_CREDIT(vpu_store_credit), 
	.VPU_MASK_IDX(vpu_mask_idx),

	.VPU_ISSUE(vpu_issue),
	.VPU_DISPATCH(vpu_dispatch),
	.VPU_MEMOP(vpu_memop), 
	.VPU_LOAD(vpu_load),
	.VPU_MASK_IDX_CREDIT(vpu_mask_idx_credit)
	
);


wire [40-1:0] vpu_csr;
assign vpu_csr = {vpu_issue.vcsr.vill, vpu_issue.vcsr.vsew, vpu_issue.vcsr.vlmul, vpu_issue.vcsr.frm, vpu_issue.vcsr.vxrm, vpu_issue.vcsr.vl, vpu_issue.vcsr.vstart};
wire [34-1:0] vpu_seqid;
assign vpu_seqid = {vpu_load.seq_id.sb_id, vpu_load.seq_id.el_count, vpu_load.seq_id.el_off, vpu_load.seq_id.el_id, vpu_load.seq_id.v_reg};

wire vpu_stall;
vpu_core #() core
(
        .clk_i(CLK),
	.rsn_i(RESET),
        .core_stall_o (vpu_stall),

        .issue_credit_o(issue_credit),
        .issue_valid_i(vpu_issue.valid),
        .issue_instr_i(vpu_issue.instr),
        .issue_sb_id_i(vpu_issue.sb_id),
        .issue_csr_i(vpu_csr),
        .issue_data_i(vpu_issue.scalar_opnd),

        .dispatch_kill_i(vpu_dispatch.kill),
        .dispatch_nxt_sen_i(vpu_dispatch.next_senior),
        .dispatch_sb_id_i(vpu_dispatch.sb_id),

        .completed_valid_o(vpu_completed.valid),
        .completed_sb_id_o(vpu_completed.sb_id),
        .completed_fflags_o(vpu_completed.fflags),
        .completed_vxsat_o(vpu_completed.vxsat),
        .completed_dst_reg_o(vpu_completed.dest_reg),
        .completed_vstart_o(vpu_completed.vstart),
        .completed_illegal_o(vpu_completed.illegal),

	.memop_sync_start_o(vpu_sync_start),
	.memop_sb_id_o(), //Is the diagram wrong?
	.memop_sync_end_i(vpu_memop.sync_end),
	.memop_sb_id_i(vpu_memop.sb_id),
	.memop_vstart_vlfof_i(vpu_memop.vstart_vlfof),

	.load_valid_i(vpu_load.valid),
	.load_data_i(vpu_load.data),
	.load_seq_id_i(vpu_seqid),
	.load_mask_valid_i(vpu_load.mask_valid),
	.load_mask_i(vpu_load.mask),

    // STORE
	.store_valid_o(vpu_store.valid),
	.store_sb_id_o(), //Is the diagram wrong?
	.store_data_o(vpu_store.data),
	.store_credit_i(vpu_store_credit),

    // MASK_IDX
	.mask_idx_valid_o(vpu_mask_idx.valid),
	.mask_idx_sb_id_o(), //Is the diagram wrong?
	.mask_idx_item_o(vpu_mask_idx.item),
	.mask_idx_last_idx_o(vpu_mask_idx.last_idx),
	.mask_idx_credit_i(vpu_mask_idx_credit),

.load_finish_valid_o(),
.load_finish_sb_id_o(),
.load_finish_no_retry_o(),
.dbg_re_i(),
.dbg_we_i(),
.dbg_address_i(), 
.dbg_read_data_o(),
.dbg_read_data_valid_o(),
.dbg_write_data_i(),
.hpm_vpu_event_i(),
.hpm_vpu_count_o()

    );


//VPU



//Debug
initial begin
	$display("Starting simulation:");
end
reg [64-1:0] debug_counter /* verilator public */ ;
reg [2:0] counter_completed = 0;
reg delay_completed = 0;
reg active = 0;
always @(posedge CLK)
begin
	debug_counter <= debug_counter + 1;
	
	delay_completed <= 1'b0;
	if (active) begin
		counter_completed <= counter_completed + 1;
	end
	if (counter_completed == 7) begin
		counter_completed <= 3'b0;
		active <= 1'b0;
		delay_completed <= 1'b1;
		
	end
	if (vpu_issue.valid) begin
		active <= 1'b1; 
	end

	if (debug_counter == 50) begin
		$finish;
	end
end
//assign vpu_completed.valid = delay_completed;

endmodule
