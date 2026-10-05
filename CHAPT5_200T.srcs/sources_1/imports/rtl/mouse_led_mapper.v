`timescale 1ns/1ps

module mouse_led_mapper(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              packet_valid,
    input  wire signed [8:0] dx,
    input  wire signed [8:0] dy,
    input  wire [2:0]        buttons,
    output reg  [4:0]        led_state
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_state <= 5'b00000;
        end else if (packet_valid) begin
            // Standard PS/2 mouse positive Y means upward movement.
            led_state[0] <= (dx < 0);       // left
            led_state[1] <= (dx > 0);       // right
            led_state[2] <= (dy > 0);       // up
            led_state[3] <= (dy < 0);       // down
            led_state[4] <= |buttons;       // any mouse button
        end
    end

endmodule
