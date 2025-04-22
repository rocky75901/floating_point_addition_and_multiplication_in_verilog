//////////////////////////////////////////////////////////////////////////////////
// File Name: floating_point_multiplier.v
// Description: 32-bit IEEE single-precision floating-point multiplier
// IEEE-754 Format:
//   - 1 bit sign (S)
//   - 8 bits exponent (E)
//   - 23 bits mantissa (M)
//   - Total: 32 bits
//////////////////////////////////////////////////////////////////////////////////

module floating_point_multiplier(
    input wire [31:0] a,      // First operand
    input wire [31:0] b,      // Second operand
    output reg [31:0] result, // Result
    output reg overflow       // Overflow flag
);

    // Internal signals
    reg sign_a, sign_b;               // Signs
    reg [7:0] exp_a, exp_b;           // Exponents
    reg [23:0] mant_a, mant_b;        // Mantissas (including hidden bit)
    reg [47:0] mant_product;          // Product of mantissas
    reg [7:0] exp_sum;                // Sum of exponents
    reg sign_result;                  // Result sign
    reg [7:0] exp_result;             // Result exponent
    reg [23:0] mant_result;           // Result mantissa

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

    // Main multiplication process
    always @(*) begin
        // Calculate sign
        sign_result = sign_a ^ sign_b;
        
        // Calculate exponent
        exp_sum = exp_a + exp_b;
        exp_result = exp_sum - 8'd127; // Subtract bias
        
        // Multiply mantissas
        mant_product = mant_a * mant_b;
        
        // Normalize result
        if (mant_product[47] == 1'b1) begin
            mant_result = mant_product[46:23];
            exp_result = exp_result + 1;
        end else begin
            mant_result = mant_product[45:22];
        end
        
        // Check for overflow
        overflow = (exp_result == 8'hFF);
        
        // Form final result
        result = {sign_result, exp_result, mant_result[22:0]};
    end

endmodule 