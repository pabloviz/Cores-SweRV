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

assign issue_credit = vpu_completed.valid; //change, not true

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
	.ISSUE_CREDIT(issue_credit),
	.VPU_COMPLETED(vpu_completed),
	.VPU_ISSUE(vpu_issue)
//	output vpu_dispatch_bus 
	
);



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
assign vpu_completed.valid = delay_completed;

endmodule
