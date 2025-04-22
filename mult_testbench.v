`timescale 1ns/1ps

module mult_testbench;
    // Test signals
    reg [31:0] a, b;
    wire [31:0] result;
    wire overflow;
    
    // Instantiate multiplier
    floating_point_multiplier multiplier(
        .a(a),
        .b(b),
        .result(result),
        .overflow(overflow)
    );
    
    // Function to convert decimal to IEEE-754
    function [31:0] decimal_to_ieee;
        input real num;
        reg sign;
        integer exp;
        real mantissa;
        real temp;
        integer i;
        reg [22:0] frac;
        begin
            sign = (num < 0) ? 1'b1 : 1'b0;
            temp = (num < 0) ? -num : num;
            
            // Handle special cases
            if (temp == 0.0) begin
                decimal_to_ieee = 32'h00000000;
            end
            else begin
                // Find exponent
                exp = 0;
                mantissa = temp;
                
                if (mantissa >= 2.0) begin
                    while (mantissa >= 2.0) begin
                        mantissa = mantissa / 2.0;
                        exp = exp + 1;
                    end
                end
                else if (mantissa < 1.0) begin
                    while (mantissa < 1.0) begin
                        mantissa = mantissa * 2.0;
                        exp = exp - 1;
                    end
                end
                
                // Calculate fraction bits
                mantissa = mantissa - 1.0; // Remove 1.0
                frac = 0;
                for (i = 0; i < 23; i = i + 1) begin
                    mantissa = mantissa * 2.0;
                    if (mantissa >= 1.0) begin
                        frac = (frac << 1) | 1'b1;
                        mantissa = mantissa - 1.0;
                    end
                    else begin
                        frac = frac << 1;
                    end
                end
                
                decimal_to_ieee = {sign, (exp + 127), frac};
            end
        end
    endfunction
    
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
        $display("Floating Point Multiplication Test Results");
        $display("-------------------------------------------");
        
        // Test case 1: 2.0 * 3.0 = 6.0
        a = 32'h40000000; // 2.0
        b = 32'h40400000; // 3.0
        #10;
        $display("Test 1: %.1f * %.1f = %.1f (Expected: 6.0)", 
            ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(result));
        $display("Result in hex: %h", result);
        
        // Test case 2: 1.5 * 2.0 = 3.0
        a = 32'h3FC00000; // 1.5
        b = 32'h40000000; // 2.0
        #10;
        $display("\nTest 2: %.1f * %.1f = %.1f (Expected: 3.0)", 
            ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(result));
        $display("Result in hex: %h", result);
        
        // Test case 3: 7.2 * 3.2 = 23.04
        a = 32'h40E66666; // 7.2
        b = 32'h40400000; // 3.2 (Adjusted to use a simpler value)
        #10;
        $display("\nTest 3: %.1f * %.1f = %.2f (Expected: 23.04)", 
            ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(result));
        $display("Result in hex: %h", result);
        
        // Test case 4: 0.5 * 0.25 = 0.125
        a = 32'h3F000000; // 0.5
        b = 32'h3E800000; // 0.25
        #10;
        $display("\nTest 4: %.2f * %.2f = %.3f (Expected: 0.125)", 
            ieee_to_decimal(a), ieee_to_decimal(b), ieee_to_decimal(result));
        $display("Result in hex: %h", result);
        
        $finish;
    end
endmodule 