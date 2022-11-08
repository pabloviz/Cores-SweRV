`include "definitions.sv"

//General interfaces
interface v_csr();
	wire [0:0] vill /* verilator public */;
	wire [`OVI_SEW_WIDTH-1:0] vsew /* verilator public */;
	wire [1:0] vlmul /* verilator public */;
	wire [2:0] frm /* verilator public */;
	wire [1:0] vxrm /* verilator public */;
	wire [`OVI_VL_WIDTH-1:0] vl /* verilator public */;
	wire [13:0] vstart /* verilator public */;
endinterface

interface seq_id_bus();
	wire [`OVI_SBID_WIDTH-1:0] sb_id /* verilator public */; //33:29
	wire [6:0] el_count /* verilator public*/; // 28:22
	wire [5:0] el_off /* verilator public*/; //21:16
	wire [10:0] el_id /* verilator public*/; //15:5
	wire [4:0] v_reg /* verilator public*/; //4:0
endinterface


//Core -> OVI interfaces (reduced from OVI specs)
interface core_issue_bus();
	wire [`OVI_INSTR_WIDTH-1:0] instr /* verilator public */;
	wire [`OVI_VL_WIDTH-1:0] vl /* verilator public */;
	wire [`OVI_SEW_WIDTH-1:0] sew /* verilator public */;
	wire [0:0] valid /* verilator public */;
endinterface

interface core_completed_bus();
	wire [`OVI_DATA_WIDTH-1:0] data /* verilator public */;
	wire [0:0] valid /* verilator public */;
endinterface
	

//OVI <-> Vpu interfaces (from the OVI specs)
interface vpu_issue_bus();
	wire [`OVI_INSTR_WIDTH-1:0] instr /* verilator public */;
	wire [`OVI_SCALAROPND_WIDTH-1:0] scalar_opnd /* verilator public */;
	wire [`OVI_SBID_WIDTH-1:0] sb_id /* verilator public */;
	v_csr vcsr; 
	wire [0:0] valid /* verilator public */;
endinterface

interface vpu_completed_bus();
	wire [`OVI_SBID_WIDTH-1:0] sb_id /* verilator public */;
	wire [`OVI_FFLAGS_WIDTH-1:0] fflags /* verilator public */;
	wire [0:0] vxsat /* verilator public */;
	wire [0:0] valid /* verilator public */;
	wire [`OVI_SCALAROPND_WIDTH-1:0] dest_reg /* verilator public */;
	wire [`OVI_VSTART_WIDTH-1:0] vstart /* verilator public */;
	wire [0:0] illegal /* verilator public */;
endinterface

interface vpu_dispatch_bus();
	wire [`OVI_SBID_WIDTH-1:0] sb_id /* verilator public */;
	wire [0:0] next_senior /* verilator public */;
	wire [0:0] kill /* verilator public */;
endinterface

interface vpu_memop_bus();
	wire [0:0] sync_end /* verilator public */;
	wire [`OVI_SBID_WIDTH-1:0] sb_id /* verilator public */;
	wire [15-1:0] vstart_vlfof /* verilator public */;
endinterface

interface vpu_load_bus();
	wire [`OVI_MEMDATA_WIDTH-1:0] data /* verilator public */; 
	seq_id_bus seq_id; 
	wire [0:0] valid /* verilator public */;
	wire [64-1:0] mask /* verilator public */;
	wire [0:0] mask_valid /* verilator public */;
endinterface

interface vpu_store_bus();
	wire [`OVI_MEMDATA_WIDTH-1:0] data /* verilator public */; 
	wire [0:0] valid /* verilator public */;
endinterface

interface vpu_mask_idx_bus();
	wire [65-1:0] item /* verilator public */; 
	wire [0:0] valid /* verilator public */;
	wire [0:0] last_idx /* verilator public */;
endinterface




