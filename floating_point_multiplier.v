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

    // Extract components
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] frac_a = a[22:0];
    wire [22:0] frac_b = b[22:0];
    
    // Calculate result components
    wire sign_result = sign_a ^ sign_b;
    reg [8:0] exp_temp;
    reg [22:0] frac_result;
    
    // For mantissa multiplication (hidden bit included)
    reg [23:0] mant_a;
    reg [23:0] mant_b;
    reg [47:0] mant_product;
    
    always @(*) begin
        // Special cases
        if (a == 32'h00000000 || b == 32'h00000000) begin
            // If either operand is zero, result is zero
            result = 32'h00000000;
            overflow = 0;
        end
        else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
            // If either operand is inf or NaN, result is inf
            result = {sign_result, 8'hFF, 23'h000000};
            overflow = 1;
        end
        else begin
            // Normal case
            
            // 1. Add hidden bit '1' to mantissas
            mant_a = {1'b1, frac_a};
            mant_b = {1'b1, frac_b};
            
            // 2. Multiply mantissas
            mant_product = mant_a * mant_b;
            
            // 3. Add exponents (subtract bias 127)
            exp_temp = exp_a + exp_b - 127;
            
            // 4. Normalize result
            if (mant_product[47]) begin
                // If bit 47 is set, shift right and adjust exponent
                frac_result = mant_product[46:24];
                exp_temp = exp_temp + 1;
            end else begin
                // No need to shift
                frac_result = mant_product[45:23];
            end
            
            // Check for overflow
            if (exp_temp >= 255) begin
                result = {sign_result, 8'hFF, 23'h000000}; // Infinity
                overflow = 1;
            end else if (exp_temp <= 0) begin
                result = {sign_result, 8'h00, 23'h000000}; // Zero (underflow)
                overflow = 0;
            end else begin
                result = {sign_result, exp_temp[7:0], frac_result};
                overflow = 0;
            end
        end
    end

endmodule 
