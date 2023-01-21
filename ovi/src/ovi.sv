`include "definitions.sv"
module ovi #()
(
	input CLK,

	//With core
	input core_issue_bus CORE_ISSUE,
	output core_completed_bus CORE_COMPLETED,
	output CORE_HALT,
	input core_response_loadstore_bus CORE_RESPONSE_LOADSTORE,
	output core_petition_loadstore_bus CORE_PETITION_LOADSTORE,

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


///////////////////////////////////////
//Declare wires / regs
state_t curr_state /* verilator public */ = WAIT_ISSUE;
reg [3:0] issue_credits /* verilator public */= 4;
v_csr vcsr;
reg [`OVI_SBID_WIDTH-1:0] sbid_counter = 0;
reg [5:0] buffer_store_index = 0; 

//Instruction saved information:
reg instr_is_store = 0;
reg instr_is_load = 0;
reg [5-1:0] instr_reg;
reg [`OVI_SEW_WIDTH-1: 0] instr_sew;
reg [`OVI_VL_WIDTH-1: 0] instr_vl;
reg [4-1:0] reg_instrlogbits = 0;
reg [8-1:0] reg_instrbits = 0;
reg wb = 0;

//Load & Store
reg [32-1:0] reg_baseaddr = 0;
reg [32-1:0] addr_offset = 0;
reg [16-1:0] n_packets; 
reg [16-1:0] sent_packets = 0;
reg sync_end = 0;
//Load
reg [`OVI_MEMDATA_WIDTH-1:0] BUFFER_LOAD [1];
reg buffer_load_ready=0;
reg [16-1:0] load_packets = 0;
reg [10:0] el_id;
reg [6:0] el_count;
reg send_load_petition = 0;
//Store
reg [`OVI_MEMDATA_WIDTH-1:0] BUFFER_STORE [32];
reg vpu_send_store_credit = 0;
reg send_store_petition = 0;



///////////////////////////////////////
//Wire computations
//General:
assign CORE_HALT = curr_state!=WAIT_ISSUE || issue_credits==0? 1'b1 : 1'b0;
wire [4-1:0] instrlogbits = CORE_ISSUE.sew==0 ? 3 : CORE_ISSUE.sew==1 ? 4 : CORE_ISSUE.sew==2? 5 : 6;
wire [8-1:0] instrbits = CORE_ISSUE.sew==0 ? 8 : CORE_ISSUE.sew==1 ? 16 : CORE_ISSUE.sew==2? 32 : 64;

//Issue bus 
assign VPU_ISSUE.instr = CORE_ISSUE.instr;
assign VPU_ISSUE.scalar_opnd = CORE_ISSUE.opnd;
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
assign CORE_COMPLETED.valid = VPU_COMPLETED.valid; 
assign CORE_COMPLETED.wb = wb && VPU_COMPLETED.valid; 
assign CORE_COMPLETED.dst = instr_reg;

//Memop 
assign VPU_MEMOP.sync_end = sync_end; 
assign VPU_MEMOP.sb_id = sbid_counter - 1;

//VPU Load 
assign VPU_LOAD.valid = buffer_load_ready; 
assign VPU_LOAD.data = BUFFER_LOAD[0];
assign VPU_LOAD.mask_valid = 1'b0;
assign VPU_LOAD.seq_id.v_reg = instr_reg; 
assign VPU_LOAD.seq_id.el_id = el_id; 
assign VPU_LOAD.seq_id.el_off = 0;
assign VPU_LOAD.seq_id.el_count = el_count; 
assign VPU_LOAD.seq_id.sb_id = sbid_counter - 1;

//VPU Store
assign VPU_STORE_CREDIT = vpu_send_store_credit;

//Mask (right now at 0)
assign VPU_MASK_IDX.valid = 1'b0;
assign VPU_MASK_IDX.last_idx = 1'b0;
assign VPU_MASK_IDX_CREDIT = 1'b0;


//OVI<->CPU Load & Store
assign CORE_PETITION_LOADSTORE.mem_addr = reg_baseaddr + addr_offset; 
assign CORE_PETITION_LOADSTORE.sew = instr_sew; 
wire [8-1:0] extra_elements = (instr_vl % (512>>reg_instrlogbits));
//Sent packets
wire [12-1:0] chunk = sent_packets[15:`SUBPACKET_BITS];
wire [`SUBPACKET_BITS-1:0] chunk_offset = sent_packets[`SUBPACKET_BITS-1:0];
wire last_packet = (sent_packets+1 == n_packets);
wire last_chunk_offset = last_packet | &chunk_offset; //last chunk or offset=1111
//Load
//Received packets
wire [12-1:0] load_chunk = load_packets[15:`SUBPACKET_BITS];
wire [`SUBPACKET_BITS-1:0] load_chunk_offset = load_packets[`SUBPACKET_BITS-1:0];
wire last_load_packet = (load_packets+1 == n_packets);
wire last_load_chunk_offset = last_load_packet | &load_chunk_offset; //last chunk or chunk_offset=1111
assign CORE_PETITION_LOADSTORE.load_valid = (curr_state == SEND_DATA) && send_load_petition;
//Store

assign CORE_PETITION_LOADSTORE.store_valid = send_store_petition; 
assign CORE_PETITION_LOADSTORE.store_data = BUFFER_STORE[chunk][chunk_offset*`CPU_PACKET_WIDTH+:`CPU_PACKET_WIDTH];
wire [$clog2(`CPU_PACKET_WIDTH) : 0] extra_bytes = ((instr_vl << reg_instrlogbits)&(`CPU_PACKET_WIDTH -1))>>3;
wire [7:0] byte_enable =  (1<<extra_bytes)-1;
assign CORE_PETITION_LOADSTORE.store_byen = last_packet ? byte_enable : -1;


initial
begin
    integer i;
    for (i=0; i < 1; i=i+1)
    begin
        BUFFER_STORE[i] = 512'b0;
	BUFFER_LOAD[i] = 512'b0; 
    end
 end

always @(posedge CLK)
begin
	//Default signals
	buffer_load_ready <= 1'b0;
	send_load_petition <= 1'b0;
	send_store_petition <= 1'b0;
	vpu_send_store_credit <= 1'b0;
	sync_end <= 1'b0;
	//Fill issue bus
	case(curr_state)
		WAIT_ISSUE: begin
			if (issue_credits > 0 && CORE_ISSUE.valid) begin
				issue_credits <= issue_credits - 1;
				sbid_counter <= sbid_counter + 1;
				sent_packets <= 0;
				load_packets <= 0;
				n_packets <= ((CORE_ISSUE.vl << instrlogbits) >> $clog2(`CPU_PACKET_WIDTH)) +
					      ((((CORE_ISSUE.vl << instrlogbits)&(`CPU_PACKET_WIDTH -1))!=0)? 16'b1 : 16'b0); //If it is not evenly diveded, one extra packet :)
				instr_vl <= CORE_ISSUE.vl;
				instr_sew <= CORE_ISSUE.sew;
				instr_is_load <= CORE_ISSUE.instr[6:0] == 7'b0000111;
				instr_is_store <= CORE_ISSUE.instr[6:0] == 7'b0100111;
				instr_reg <= CORE_ISSUE.instr[11:7];
				reg_baseaddr <= CORE_ISSUE.opnd;
				addr_offset <= 0;
				reg_instrlogbits <= instrlogbits;
				reg_instrbits <= instrbits;
				wb <= CORE_ISSUE.wb;
				curr_state <= WAIT_ANSWER;
			end
		end
		WAIT_ANSWER: begin
			if (VPU_COMPLETED.valid) begin
				curr_state <= WAIT_ISSUE;
			end
			else if (VPU_SYNC_START) begin 
				curr_state <= instr_is_store ? RECEIVE_DATA : instr_is_load ? SEND_DATA : WAIT_ANSWER;
				buffer_store_index <= 0;
			end
		end
		RECEIVE_DATA/*from the vpu*/: begin //STORES
			//if the core is ready and we have enough received chunks from the VPU, send petition. 
			if (CORE_RESPONSE_LOADSTORE.mem_ready && buffer_store_index > chunk) begin
				send_store_petition <= 1'b1;
				//If it is the last offset of a 512bits chunk or its the last packet , return credit to the vpu
				if (last_chunk_offset) begin 
					vpu_send_store_credit <= 1'b1;
					//If it was the last packet, in the next cycle change to wait answer and send sync_end
					if (last_packet) begin
						curr_state <= WAIT_ANSWER;
						sync_end <= 1'b1;
					end
				end
			end
			//The VPU sends us 512 bits of data, we store it in a buffer
			if (VPU_STORE.valid) begin 
				BUFFER_STORE[buffer_store_index] <= VPU_STORE.data;
				buffer_store_index <= buffer_store_index + 1;
			end
			//Update addr if we send a store petition
			if (send_store_petition) begin
				//8 -> +1, 16 -> +2, 32 -> +4, 64 -> +8
				addr_offset <= addr_offset + (`CPU_PACKET_WIDTH >> 3); 
				sent_packets <= sent_packets+1;
			end
		end
		SEND_DATA/*to the vpu*/: begin //LOADS
			if (CORE_RESPONSE_LOADSTORE.mem_ready && (sent_packets < n_packets)) begin
				send_load_petition <= 1'b1;
			end
			if (CORE_RESPONSE_LOADSTORE.load_valid) begin //Data arrives from core, store it
				BUFFER_LOAD[0][load_chunk_offset*`CPU_PACKET_WIDTH+:`CPU_PACKET_WIDTH] <= CORE_RESPONSE_LOADSTORE.load_data;
				load_packets <= load_packets+1;
				//If last offset, send data to the VPU
				if (last_load_chunk_offset) begin 
					buffer_load_ready <= 1'b1;
					el_id <= (load_chunk) << ($clog2(512)-reg_instrlogbits);//(sew32: sent_packets*16)
					el_count <= (last_load_packet) ? extra_elements: ((512>>reg_instrlogbits));
					//If it was the last packet, in the next cycle change to wait answer and send sync_end
					if (last_load_packet) begin
						curr_state <= WAIT_ANSWER;
						sync_end <= 1'b1;
					end
				end
			end
			if (send_load_petition) begin
				//8 -> +1, 16 -> +2, 32 -> +4, 64 -> +8
				addr_offset <= addr_offset + (`CPU_PACKET_WIDTH >> 3); 
				sent_packets <= sent_packets+1;
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
