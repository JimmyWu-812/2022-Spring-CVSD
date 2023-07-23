module alu #(
    parameter INT_W  = 4,
    parameter FRAC_W = 6,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input                     i_valid,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output       [DATA_W-1:0] o_data
); // Do not modify
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg [DATA_W-1:0] o_data_w, o_data_r;
reg              o_valid_w, o_valid_r;
// ---- Add your own wires and registers here if needed ---- //
wire [18:0] MIN_THRESHOLD, MAX_THRESHOLD;
wire [9:0]  MIN_VALUE, MAX_VALUE;

wire [9:0]  alu_data_a, alu_data_b;
wire [3:0]  alu_inst;
wire [18:0] o_data_r_extended;

wire        overflow_ADD_pos, overflow_ADD_neg, overflow_SUB_pos, overflow_SUB_neg;
wire        overflow_MUL_pos, overflow_MUL_neg, overflow_MAC_pos, overflow_MAC_neg;

wire [18:0] alu_MUL_tmp, alu_MAC_tmp;
wire [12:0] alu_MUL_tmp_rounded, alu_MAC_tmp_rounded;
wire [9:0]  alu_ADD_tmp, alu_SUB_tmp;
wire [9:0]  alu_ADD, alu_SUB, alu_MUL, alu_MAC, alu_TANH;
wire [9:0]  alu_ORN, alu_CLZ, alu_CTZ, aku_CPOP, alu_ROL;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
// ---- Add your own wire data assignments here if needed ---- //
assign MIN_THRESHOLD = 13'b0_0001_1111_1111;
assign MAX_THRESHOLD = 13'b1_1110_0000_0000;
assign MIN_VALUE = 10'b10_0000_0000;
assign MAX_VALUE = 10'b01_1111_1111;

assign alu_data_a = i_valid ? i_data_a : 0;
assign alu_data_b = i_valid ? i_data_b : 0;
assign alu_inst = i_valid ? i_inst : 4'b1111;
assign o_data_r_extended = {{3{o_data_r[9]}}, o_data_r, 6'b0};

assign alu_ADD_tmp = $signed(alu_data_a)+$signed(alu_data_b);
assign alu_SUB_tmp = $signed(alu_data_a)-$signed(alu_data_b);
assign alu_MUL_tmp = $signed(alu_data_a)*$signed(alu_data_b);
assign alu_MUL_tmp_rounded = alu_MUL_tmp[5] ? alu_MUL_tmp[18:6] + 1 : alu_MUL_tmp[18:6];
assign alu_MAC_tmp = $signed(alu_MUL_tmp)+$signed(o_data_r_extended);
assign alu_MAC_tmp_rounded = alu_MAC_tmp[5] ? alu_MAC_tmp[18:6] + 1 : alu_MAC_tmp[18:6];

assign overflow_ADD_pos = ~alu_data_a[9] & ~alu_data_b[9] & alu_ADD_tmp[9];
assign overflow_ADD_neg = alu_data_a[9] & alu_data_b[9] & ~alu_ADD_tmp[9];
assign overflow_SUB_pos = ~alu_data_a[9] & alu_data_b[9] & alu_SUB_tmp[9];
assign overflow_SUB_neg = alu_data_a[9] & ~alu_data_b[9] & ~alu_SUB_tmp[9];
assign overflow_MUL_pos = ~alu_MUL_tmp_rounded[12] & (alu_MUL_tmp_rounded > MIN_THRESHOLD);
assign overflow_MUL_neg = alu_MUL_tmp_rounded[12] & (alu_MUL_tmp_rounded < MAX_THRESHOLD);
assign overflow_MAC_pos = ~alu_MAC_tmp_rounded[12] & (alu_MAC_tmp_rounded > MIN_THRESHOLD);
assign overflow_MAC_neg = alu_MAC_tmp_rounded[12] & (alu_MAC_tmp_rounded < MAX_THRESHOLD);

assign alu_ADD = overflow_ADD_pos ? MAX_VALUE : 
                 overflow_ADD_neg ? MIN_VALUE : alu_ADD_tmp;
assign alu_SUB = overflow_SUB_pos ? MAX_VALUE : 
                 overflow_SUB_neg ? MIN_VALUE : alu_SUB_tmp;
assign alu_MUL = overflow_MUL_pos ? MAX_VALUE : 
                 overflow_MUL_neg ? MIN_VALUE : alu_MUL_tmp_rounded;
assign alu_MAC = overflow_MAC_pos ? MAX_VALUE : 
                 overflow_MAC_neg ? MIN_VALUE : alu_MAC_tmp_rounded;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
    o_data_w = 10'b0;
    o_valid_w = 1'b0;
    case(i_inst)
        4'b0000: o_data_w = alu_ADD;
        4'b0001: o_data_w = alu_SUB;
        4'b0010: o_data_w = alu_MUL;
        4'b0011: o_data_w = alu_MAC;
    endcase
    o_valid_w = i_valid;
end



// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_data_r <= 0;
        o_valid_r <= 0;
    end else begin
        o_data_r <= o_data_w;
        o_valid_r <= o_valid_w;
    end
end

endmodule