`timescale 1ns/1ps

module fp_testbench;
    // Test signals
    reg [31:0] a, b;
    wire [31:0] add_result, mul_result;
    wire add_overflow, mul_overflow;
    
    // Instantiate modules
    floating_point_adder adder(
        .a(a),
        .b(b),
        .result(add_result),
        .overflow(add_overflow)
    );
    
    floating_point_multiplier multiplier(
        .a(a),
        .b(b),
        .result(mul_result),
        .overflow(mul_overflow)
    );
    
    // Function to convert IEEE-754 to decimal
    function real ieee_to_decimal;
        input [31:0] ieee;
        reg sign;
        reg [7:0] exponent;
        reg [22:0] mantissa;
        real result;
        integer i;
        begin
            sign = ieee[31];
            exponent = ieee[30:23];
            mantissa = ieee[22:0];
            
            if (exponent == 8'hFF) begin
                if (mantissa == 0) begin
                    result = sign ? -1.0/0.0 : 1.0/0.0; // Infinity
                end else begin
                    result = 0.0/0.0; // NaN
                end
            end else if (exponent == 0) begin
                if (mantissa == 0) begin
                    result = 0.0;
                end else begin
                    // Denormal number
                    result = 0.0;
                    for (i = 0; i < 23; i = i + 1) begin
                        if (mantissa[22-i]) begin
                            result = result + 2.0**(-126-i);
                        end
                    end
                end
            end else begin
                // Normal number
                result = 1.0;
                for (i = 0; i < 23; i = i + 1) begin
                    if (mantissa[22-i]) begin
                        result = result + 2.0**(-i-1);
                    end
                end
                result = result * 2.0**(exponent - 127);
            end
            
            ieee_to_decimal = sign ? -result : result;
        end
    endfunction
    
    // Test cases
    initial begin
        // Test case 1: 7.2 + 3.2
        a = 32'h40E66666; // 7.2
        b = 32'h404CCCCD; // 3.2
        #10;
        $display("Test 1: %.1f + %.1f = %.1f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(add_result));
        $display("Test 1: %.1f * %.1f = %.1f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(mul_result));
        
        // Test case 2: -5.5 + 2.25
        a = 32'hC0B00000; // -5.5
        b = 32'h40100000; // 2.25
        #10;
        $display("Test 2: %.1f + %.2f = %.2f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(add_result));
        $display("Test 2: %.1f * %.2f = %.2f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(mul_result));
        
        // Test case 3: 0.1 + 0.2
        a = 32'h3DCCCCCD; // 0.1
        b = 32'h3E4CCCCD; // 0.2
        #10;
        $display("Test 3: %.1f + %.1f = %.1f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(add_result));
        $display("Test 3: %.1f * %.1f = %.2f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(mul_result));
        
        // Test case 4: 1.0 + (-1.0)
        a = 32'h3F800000; // 1.0
        b = 32'hBF800000; // -1.0
        #10;
        $display("Test 4: %.1f + %.1f = %.1f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(add_result));
        $display("Test 4: %.1f * %.1f = %.1f", ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(mul_result));
        
        $finish;
    end
endmodule 