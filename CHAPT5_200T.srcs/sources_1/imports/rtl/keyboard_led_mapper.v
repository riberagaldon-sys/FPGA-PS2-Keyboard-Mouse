`timescale 1ns/1ps

module keyboard_led_mapper(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_press,
    input  wire       key_release,
    input  wire [7:0] key_code,
    input  wire       extended,
    output reg  [4:0] led_state
);

    reg       mapped;
    reg [2:0] mapped_index;

    always @(*) begin
        mapped       = 1'b1;
        mapped_index = 3'd0;

        if (!extended && key_code == 8'h1D) begin
            mapped_index = 3'd0; // W
        end else if (extended && key_code == 8'h75) begin
            mapped_index = 3'd0; // Up
        end else if (!extended && key_code == 8'h1B) begin
            mapped_index = 3'd1; // S
        end else if (extended && key_code == 8'h72) begin
            mapped_index = 3'd1; // Down
        end else if (!extended && key_code == 8'h1C) begin
            mapped_index = 3'd2; // A
        end else if (extended && key_code == 8'h6B) begin
            mapped_index = 3'd2; // Left
        end else if (!extended && key_code == 8'h23) begin
            mapped_index = 3'd3; // D
        end else if (extended && key_code == 8'h74) begin
            mapped_index = 3'd3; // Right
        end else if (!extended &&
                    (key_code == 8'h5A || key_code == 8'h29)) begin
            mapped_index = 3'd4; // Enter or Space
        end else begin
            mapped = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_state <= 5'b00000;
        end else if (key_press && !extended && key_code == 8'h76) begin
            led_state <= 5'b00000; // Esc clears all LEDs.
        end else if (mapped && key_press) begin
            led_state[mapped_index] <= 1'b1;
        end else if (mapped && key_release) begin
            led_state[mapped_index] <= 1'b0;
        end
    end

endmodule
