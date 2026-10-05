`timescale 1ns/1ps

module top_chapter5_ps2 #(
    parameter integer CLK_HZ          = 50_000_000,
    parameter integer POR_BITS        = 21,

    // 0: PS/2 keyboard (recommended for first hardware verification)
    // 1: PS/2 mouse, host sends F4 and parses 3-byte packets
    parameter integer PS2_DEVICE_MODE = 1,

    // Current LCD platform is 1024x600.  These coordinates are exposed
    // to ILA in mouse mode and can be overridden for another display.
    parameter integer MOUSE_X_MAX     = 1023,
    parameter integer MOUSE_Y_MAX     = 599
)(
    input  wire       sys_clk,
    inout  wire       PS2_CLK,
    inout  wire       PS2_DATA,
    output wire [4:0] led
);

    wire rst_n;

    por_reset #(
        .COUNTER_BITS(POR_BITS)
    ) u_por_reset (
        .clk  (sys_clk),
        .rst_n(rst_n)
    );

    wire ps2_clk_in;
    wire ps2_data_in;
    wire ps2_clk_drive_low;
    wire ps2_data_drive_low;
    wire [4:0] led_internal;

    assign PS2_CLK  = ps2_clk_drive_low  ? 1'b0 : 1'bz;
    assign PS2_DATA = ps2_data_drive_low ? 1'b0 : 1'bz;

    assign ps2_clk_in  = PS2_CLK;
    assign ps2_data_in = PS2_DATA;
    assign led          = led_internal;

    generate
        if (PS2_DEVICE_MODE == 0) begin : g_keyboard
            (* MARK_DEBUG = "TRUE" *) wire [7:0] scan_code_raw;
            (* MARK_DEBUG = "TRUE" *) wire       scan_valid_raw;
            (* MARK_DEBUG = "TRUE" *) wire       frame_error;

            (* MARK_DEBUG = "TRUE" *) wire       key_press;
            (* MARK_DEBUG = "TRUE" *) wire       key_release;
            (* MARK_DEBUG = "TRUE" *) wire [7:0] key_code;
            (* MARK_DEBUG = "TRUE" *) wire       extended;
            (* MARK_DEBUG = "TRUE" *) wire [4:0] keyboard_led;

            assign ps2_clk_drive_low  = 1'b0;
            assign ps2_data_drive_low = 1'b0;
            assign led_internal       = keyboard_led;

            ps2_rx #(
                .CLK_HZ    (CLK_HZ),
                .TIMEOUT_US(2000)
            ) u_ps2_rx (
                .clk        (sys_clk),
                .rst_n      (rst_n),
                .ps2_clk    (ps2_clk_in),
                .ps2_data   (ps2_data_in),
                .data_byte  (scan_code_raw),
                .data_valid (scan_valid_raw),
                .frame_error(frame_error)
            );

            ps2_keyboard_decoder u_keyboard_decoder (
                .clk        (sys_clk),
                .rst_n      (rst_n),
                .scan_code  (scan_code_raw),
                .scan_valid (scan_valid_raw),
                .key_press  (key_press),
                .key_release(key_release),
                .key_code   (key_code),
                .extended   (extended)
            );

            keyboard_led_mapper u_keyboard_led_mapper (
                .clk        (sys_clk),
                .rst_n      (rst_n),
                .key_press  (key_press),
                .key_release(key_release),
                .key_code   (key_code),
                .extended   (extended),
                .led_state  (keyboard_led)
            );

        end else begin : g_mouse
            (* MARK_DEBUG = "TRUE" *) wire       tx_start;
            (* MARK_DEBUG = "TRUE" *) wire [7:0] tx_byte;
            (* MARK_DEBUG = "TRUE" *) wire       tx_busy;
            (* MARK_DEBUG = "TRUE" *) wire       tx_done;
            (* MARK_DEBUG = "TRUE" *) wire       tx_ack_ok;
            (* MARK_DEBUG = "TRUE" *) wire       tx_error;

            (* MARK_DEBUG = "TRUE" *) wire [7:0] rx_byte;
            (* MARK_DEBUG = "TRUE" *) wire       rx_valid;
            (* MARK_DEBUG = "TRUE" *) wire       rx_frame_error;

            (* MARK_DEBUG = "TRUE" *) wire       mouse_ready;
            (* MARK_DEBUG = "TRUE" *) wire       init_error;
            (* MARK_DEBUG = "TRUE" *) wire       packet_valid;
            (* MARK_DEBUG = "TRUE" *) wire [2:0] buttons;
            (* MARK_DEBUG = "TRUE" *) wire signed [8:0] dx;
            (* MARK_DEBUG = "TRUE" *) wire signed [8:0] dy;
            (* MARK_DEBUG = "TRUE" *) wire [10:0] mouse_x;
            (* MARK_DEBUG = "TRUE" *) wire [9:0]  mouse_y;
            (* MARK_DEBUG = "TRUE" *) wire [4:0] mouse_led;

            assign led_internal = mouse_led;

            ps2_host_tx #(
                .CLK_HZ(CLK_HZ)
            ) u_ps2_host_tx (
                .clk               (sys_clk),
                .rst_n             (rst_n),
                .start             (tx_start),
                .tx_byte           (tx_byte),
                .ps2_clk_in        (ps2_clk_in),
                .ps2_data_in       (ps2_data_in),
                .ps2_clk_drive_low (ps2_clk_drive_low),
                .ps2_data_drive_low(ps2_data_drive_low),
                .busy              (tx_busy),
                .done              (tx_done),
                .ack_ok            (tx_ack_ok),
                .tx_error          (tx_error)
            );

            // Reset the receiver while the host is transmitting so that
            // the outgoing host frame is not interpreted as device data.
            ps2_rx #(
                .CLK_HZ    (CLK_HZ),
                .TIMEOUT_US(2000)
            ) u_ps2_rx (
                .clk        (sys_clk),
                .rst_n      (rst_n && !tx_busy),
                .ps2_clk    (ps2_clk_in),
                .ps2_data   (ps2_data_in),
                .data_byte  (rx_byte),
                .data_valid (rx_valid),
                .frame_error(rx_frame_error)
            );

            ps2_mouse_init #(
                .CLK_HZ(CLK_HZ)
            ) u_mouse_init (
                .clk        (sys_clk),
                .rst_n      (rst_n),
                .tx_start   (tx_start),
                .tx_byte    (tx_byte),
                .tx_busy    (tx_busy),
                .tx_done    (tx_done),
                .tx_ack_ok  (tx_ack_ok),
                .tx_error   (tx_error),
                .rx_byte    (rx_byte),
                .rx_valid   (rx_valid),
                .mouse_ready(mouse_ready),
                .init_error (init_error)
            );

            ps2_mouse_packet #(
                .X_MAX (MOUSE_X_MAX),
                .Y_MAX (MOUSE_Y_MAX),
                .X_INIT(MOUSE_X_MAX / 2),
                .Y_INIT(MOUSE_Y_MAX / 2)
            ) u_mouse_packet (
                .clk         (sys_clk),
                .rst_n       (rst_n),
                .enable      (mouse_ready),
                .data_byte   (rx_byte),
                .data_valid  (rx_valid),
                .packet_valid(packet_valid),
                .buttons     (buttons),
                .dx          (dx),
                .dy          (dy),
                .mouse_x     (mouse_x),
                .mouse_y     (mouse_y)
            );

            mouse_led_mapper u_mouse_led_mapper (
                .clk         (sys_clk),
                .rst_n       (rst_n),
                .packet_valid(packet_valid),
                .dx          (dx),
                .dy          (dy),
                .buttons     (buttons),
                .led_state   (mouse_led)
            );
        end
    endgenerate

endmodule
