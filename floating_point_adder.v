//////////////////////////////////////////////////////////////////////////////////
// File Name: floating_point_adder.v
// Description: 32-bit IEEE single-precision floating-point adder
// IEEE-754 Format:
//   - 1 bit sign (S)
//   - 8 bits exponent (E)
//   - 23 bits mantissa (M)
//   - Total: 32 bits
//////////////////////////////////////////////////////////////////////////////////

module floating_point_adder(
    input wire [31:0] a,      // First operand
    input wire [31:0] b,      // Second operand
    output reg [31:0] result, // Result
    output reg overflow       // Overflow flag
);

    // Internal signals
    reg [7:0] exp_a, exp_b;           // Exponents
    reg [23:0] mant_a, mant_b;        // Mantissas (including hidden bit)
    reg sign_a, sign_b;               // Signs
    reg [7:0] exp_diff;               // Exponent difference
    reg [23:0] mant_sum;              // Sum of mantissas
    reg [7:0] exp_result;             // Result exponent
    reg sign_result;                  // Result sign
    reg [23:0] mant_result;           // Result mantissa
    reg [24:0] sum;                   // Extended sum for carry handling

    // Extract components from input operands
    always @(*) begin
        sign_a = a[31];
        sign_b = b[31];
        exp_a = a[30:23];
        exp_b = b[30:23];
        
        // Add hidden bit to mantissa
        mant_a = {1'b1, a[22:0]};
        mant_b = {1'b1, b[22:0]};
    end

    // Main addition process
    always @(*) begin
        // Calculate exponent difference
        exp_diff = exp_a - exp_b;
        
        // Align mantissas based on exponent difference
        if (exp_diff[7] == 1'b1) begin // exp_b > exp_a
            mant_a = mant_a >> (~exp_diff + 1);
            exp_result = exp_b;
        end else begin
            mant_b = mant_b >> exp_diff;
            exp_result = exp_a;
        end
        
        // Add mantissas
        if (sign_a == sign_b) begin
            sum = mant_a + mant_b;
            sign_result = sign_a;
        end else begin
            if (mant_a > mant_b) begin
                sum = mant_a - mant_b;
                sign_result = sign_a;
            end else begin
                sum = mant_b - mant_a;
                sign_result = sign_b;
            end
        end
        
        // Normalize result
        if (sum[24] == 1'b1) begin
            mant_result = sum[24:1];
            exp_result = exp_result + 1;
        end else begin
            // Find first '1' in sum
            if (sum[23] == 1'b1) begin
                mant_result = sum[23:0];
            end else if (sum[22] == 1'b1) begin
                mant_result = sum[22:0] << 1;
                exp_result = exp_result - 1;
            end else if (sum[21] == 1'b1) begin
                mant_result = sum[21:0] << 2;
                exp_result = exp_result - 2;
            end else if (sum[20] == 1'b1) begin
                mant_result = sum[20:0] << 3;
                exp_result = exp_result - 3;
            end else begin
                mant_result = 24'b0;
                exp_result = 8'b0;
            end
        end
       
        // Check for overflow
        overflow = (exp_result == 8'hFF);
        
        // Form final result
        result = {sign_result, exp_result, mant_result[22:0]};
    end

endmodule 