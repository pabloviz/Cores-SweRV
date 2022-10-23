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
