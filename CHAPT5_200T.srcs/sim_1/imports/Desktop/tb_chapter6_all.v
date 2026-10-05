`timescale 1ns/1ps
// Chapter 6: PS/2 keyboard and mouse. Project: CHAPT5_200T.
// Simulation top: tb_chapter6_all. Add this file to Simulation Sources only.
// Uses the ORIGINAL project RTL, including both modes of top_chapter5_ps2.
// Run: restart; run 5 ms. Expected: checks_done=1, checks_pass=1, errors=0.
// There is no $finish/$stop: the simulation stays open for waveform screenshots.
//
// Simulation-only acceleration:
//   sys_clk remains 50 MHz; POR_BITS=4 instead of the board default 21.
//   Mouse POWERUP_MS=1, RESPONSE_MS=5, RETRY_MS=2 in this testbench only.
//   Device frames use a 4 us bit period for functional verification. This
//   accelerated stimulus is NOT a measurement of the physical PS/2 clock rate.
//   Receiver timeout and host request/inhibit parameters remain unchanged.
//
// Recommended screenshots (all named signals are at the testbench root):
// Fig.6-1, 0..160 us: PS2_CLK, PS2_DATA, bit_count, frame_bits,
//   data_byte, data_valid, frame_error, rx_valid_events, rx_error_events.
//   Cases 1/2/3: legal 1D, wrong parity, wrong stop bit.
//   frame_bits[10] is an RTL initialization value, NOT a captured stop bit.
// Fig.6-2(a), 5..280 us: kbd_scan_code, kbd_scan_valid,
//   kbd_extend_pending, kbd_break_pending, kbd_key_code, kbd_extended,
//   kbd_key_press, kbd_key_release, kbd_led.
//   E0 75 = Up pressed; E0 F0 75 = Up released.
// Fig.6-2(b), about 1230..1710 us: mouse_ready, mouse_rx_byte,
//   mouse_rx_valid, mouse_packet_index, mouse_packet_valid, mouse_dx,
//   mouse_dy, mouse_buttons, mouse_x, mouse_y, mouse_led.
//   First three packets: (+8,+4,left), (-5,-2,right), (0,0,no button).
// Optional initialization detail, 990..1240 us: mouse_PS2_CLK,
//   mouse_PS2_DATA, mouse_tx_byte/start/busy/done/ack_ok,
//   mouse_rx_byte/valid, mouse_ready. Host F4 -> bus ACK -> device FA.
// Set byte/code signals to hexadecimal, LEDs/buttons to binary,
// mouse_dx/mouse_dy to SIGNED decimal, coordinates/counters to unsigned decimal.

module tb_chapter6_all;
    reg sys_clk = 1'b0;
    always #10 sys_clk = ~sys_clk;

    reg rx_rst_n = 1'b0;
    reg PS2_CLK = 1'b1;
    reg PS2_DATA = 1'b1;
    wire [7:0] data_byte;
    wire data_valid;
    wire frame_error;
    wire [3:0] bit_count;
    wire [10:0] frame_bits;
    reg [3:0] rx_case = 4'd0;

    ps2_rx #(.CLK_HZ(50_000_000), .TIMEOUT_US(2000)) dut_rx (
        .clk(sys_clk), .rst_n(rx_rst_n),
        .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA),
        .data_byte(data_byte), .data_valid(data_valid),
        .frame_error(frame_error)
    );
    assign bit_count = dut_rx.bit_count;
    assign frame_bits = dut_rx.frame_bits;

    // Real open-drain buses: the device drives low or releases to the pull-up.
    tri1 kbd_PS2_CLK;
    tri1 kbd_PS2_DATA;
    reg kbd_clk_low = 1'b0;
    reg kbd_data_low = 1'b0;
    wire [4:0] kbd_led;
    assign kbd_PS2_CLK = kbd_clk_low ? 1'b0 : 1'bz;
    assign kbd_PS2_DATA = kbd_data_low ? 1'b0 : 1'bz;
    top_chapter5_ps2 #(
        .CLK_HZ(50_000_000), .POR_BITS(4), .PS2_DEVICE_MODE(0)
    ) dut_keyboard (
        .sys_clk(sys_clk), .PS2_CLK(kbd_PS2_CLK),
        .PS2_DATA(kbd_PS2_DATA), .led(kbd_led)
    );
    wire [7:0] kbd_scan_code = dut_keyboard.g_keyboard.scan_code_raw;
    wire kbd_scan_valid = dut_keyboard.g_keyboard.scan_valid_raw;
    wire kbd_frame_error = dut_keyboard.g_keyboard.frame_error;
    wire kbd_key_press = dut_keyboard.g_keyboard.key_press;
    wire kbd_key_release = dut_keyboard.g_keyboard.key_release;
    wire [7:0] kbd_key_code = dut_keyboard.g_keyboard.key_code;
    wire kbd_extended = dut_keyboard.g_keyboard.extended;
    wire kbd_extend_pending =
        dut_keyboard.g_keyboard.u_keyboard_decoder.extend_pending;
    wire kbd_break_pending =
        dut_keyboard.g_keyboard.u_keyboard_decoder.break_pending;

    tri1 mouse_PS2_CLK;
    tri1 mouse_PS2_DATA;
    reg mouse_clk_low = 1'b0;
    reg mouse_data_low = 1'b0;
    wire [4:0] mouse_led;
    top_chapter5_ps2 #(
        .CLK_HZ(50_000_000), .POR_BITS(4), .PS2_DEVICE_MODE(1),
        .MOUSE_X_MAX(1023), .MOUSE_Y_MAX(599)
    ) dut_mouse (
        .sys_clk(sys_clk), .PS2_CLK(mouse_PS2_CLK),
        .PS2_DATA(mouse_PS2_DATA), .led(mouse_led)
    );
    assign mouse_PS2_CLK = mouse_clk_low ? 1'b0 : 1'bz;
    assign mouse_PS2_DATA = mouse_data_low ? 1'b0 : 1'bz;
    // These overrides belong to simulation only. Do not edit the board RTL.
    defparam dut_mouse.g_mouse.u_mouse_init.POWERUP_MS = 1;
    defparam dut_mouse.g_mouse.u_mouse_init.RESPONSE_MS = 5;
    defparam dut_mouse.g_mouse.u_mouse_init.RETRY_MS = 2;

    wire mouse_ready = dut_mouse.g_mouse.mouse_ready;
    wire mouse_init_error = dut_mouse.g_mouse.init_error;
    wire [7:0] mouse_tx_byte = dut_mouse.g_mouse.tx_byte;
    wire mouse_tx_start = dut_mouse.g_mouse.tx_start;
    wire mouse_tx_busy = dut_mouse.g_mouse.tx_busy;
    wire mouse_tx_done = dut_mouse.g_mouse.tx_done;
    wire mouse_tx_ack_ok = dut_mouse.g_mouse.tx_ack_ok;
    wire mouse_tx_error = dut_mouse.g_mouse.tx_error;
    wire [7:0] mouse_rx_byte = dut_mouse.g_mouse.rx_byte;
    wire mouse_rx_valid = dut_mouse.g_mouse.rx_valid;
    wire mouse_rx_error = dut_mouse.g_mouse.rx_frame_error;
    wire mouse_packet_valid = dut_mouse.g_mouse.packet_valid;
    wire [1:0] mouse_packet_index = dut_mouse.g_mouse.u_mouse_packet.byte_index;
    wire signed [8:0] mouse_dx = dut_mouse.g_mouse.dx;
    wire signed [8:0] mouse_dy = dut_mouse.g_mouse.dy;
    wire [2:0] mouse_buttons = dut_mouse.g_mouse.buttons;
    wire [10:0] mouse_x = dut_mouse.g_mouse.mouse_x;
    wire [9:0] mouse_y = dut_mouse.g_mouse.mouse_y;
    reg [7:0] mouse_host_command = 8'd0;
    reg mouse_host_parity = 1'b0;
    reg mouse_host_stop = 1'b0;

    integer errors = 0;
    integer rx_valid_events = 0;
    integer rx_error_events = 0;
    integer kbd_press_events = 0;
    integer kbd_release_events = 0;
    integer kbd_error_events = 0;
    integer mouse_packet_events = 0;
    integer mouse_rx_error_events = 0;
    integer mouse_tx_done_events = 0;
    integer mouse_tx_ack_events = 0;
    integer mouse_tx_error_events = 0;
    reg rx_done = 1'b0;
    reg keyboard_done = 1'b0;
    reg mouse_done = 1'b0;
    reg checks_done = 1'b0;
    reg checks_pass = 1'b0;
    reg prev_rx_valid = 1'b0;
    reg prev_rx_error = 1'b0;
    reg prev_kbd_press = 1'b0;
    reg prev_kbd_release = 1'b0;
    reg prev_mouse_packet = 1'b0;

    task automatic expect_eq;
        input [8*96-1:0] label;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("CH6 ERROR at %0.3f us: %0s actual=%h expected=%h",
                         $realtime / 1000.0, label, actual, expected);
            end
        end
    endtask

    // Observe after nonblocking assignments. Event outputs must be one cycle.
    always @(posedge sys_clk) begin
        #0.001;
        if (rx_rst_n) begin
            if (data_valid) rx_valid_events = rx_valid_events + 1;
            if (frame_error) rx_error_events = rx_error_events + 1;
            if (data_valid && prev_rx_valid)
                expect_eq("RX valid pulse width", 1, 0);
            if (frame_error && prev_rx_error)
                expect_eq("RX error pulse width", 1, 0);
            if (data_valid && frame_error)
                expect_eq("RX valid and error are mutually exclusive", 1, 0);
            prev_rx_valid = data_valid;
            prev_rx_error = frame_error;
        end
        if (dut_keyboard.rst_n) begin
            if (kbd_key_press) kbd_press_events = kbd_press_events + 1;
            if (kbd_key_release) kbd_release_events = kbd_release_events + 1;
            if (kbd_frame_error) kbd_error_events = kbd_error_events + 1;
            if (kbd_key_press && prev_kbd_press)
                expect_eq("Keyboard press pulse width", 1, 0);
            if (kbd_key_release && prev_kbd_release)
                expect_eq("Keyboard release pulse width", 1, 0);
            if (kbd_key_press && kbd_key_release)
                expect_eq("Keyboard press/release mutually exclusive", 1, 0);
            prev_kbd_press = kbd_key_press;
            prev_kbd_release = kbd_key_release;
        end
        if (dut_mouse.rst_n) begin
            if (mouse_packet_valid) mouse_packet_events = mouse_packet_events + 1;
            if (mouse_rx_error) mouse_rx_error_events = mouse_rx_error_events + 1;
            if (mouse_tx_error) mouse_tx_error_events = mouse_tx_error_events + 1;
            if (mouse_tx_done) begin
                mouse_tx_done_events = mouse_tx_done_events + 1;
                if (mouse_tx_ack_ok) mouse_tx_ack_events = mouse_tx_ack_events + 1;
            end
            if (mouse_packet_valid && prev_mouse_packet)
                expect_eq("Mouse packet pulse width", 1, 0);
            prev_mouse_packet = mouse_packet_valid;
        end
    end

    task automatic drive_data;
        input integer link;
        input value;
        begin
            case (link)
                0: PS2_DATA = value;
                1: kbd_data_low = !value;
                2: mouse_data_low = !value;
                default: expect_eq("Invalid data link", link, 0);
            endcase
        end
    endtask

    task automatic drive_clock;
        input integer link;
        input value;
        begin
            case (link)
                0: PS2_CLK = value;
                1: kbd_clk_low = !value;
                2: mouse_clk_low = !value;
                default: expect_eq("Invalid clock link", link, 0);
            endcase
        end
    endtask

    // Legal start=0, data LSB first, odd parity, stop=1.
    task automatic send_device_frame;
        input integer link;
        input [7:0] value;
        input bad_parity;
        input stop_bit;
        reg [10:0] bits;
        integer i;
        begin
            bits = {stop_bit, ((~(^value)) ^ bad_parity), value, 1'b0};
            drive_clock(link, 1'b1);
            for (i = 0; i < 11; i = i + 1) begin
                drive_data(link, bits[i]);
                #2000;
                drive_clock(link, 1'b0);
                #2000;
                drive_clock(link, 1'b1);
            end
            drive_data(link, 1'b1);
            #8000;
        end
    endtask

    task automatic keyboard_down;
        input [7:0] code;
        input is_extended;
        input [4:0] expected_led;
        integer before_events;
        begin
            before_events = kbd_press_events;
            if (is_extended) send_device_frame(1, 8'hE0, 0, 1);
            send_device_frame(1, code, 0, 1);
            expect_eq("Keyboard press count", kbd_press_events, before_events + 1);
            expect_eq("Keyboard pressed code", kbd_key_code, code);
            expect_eq("Keyboard pressed extended", kbd_extended, is_extended);
            expect_eq("Keyboard pressed LED", kbd_led, expected_led);
        end
    endtask

    task automatic keyboard_up;
        input [7:0] code;
        input is_extended;
        input [4:0] expected_led;
        integer before_events;
        begin
            before_events = kbd_release_events;
            if (is_extended) send_device_frame(1, 8'hE0, 0, 1);
            send_device_frame(1, 8'hF0, 0, 1);
            send_device_frame(1, code, 0, 1);
            expect_eq("Keyboard release count", kbd_release_events, before_events + 1);
            expect_eq("Keyboard released code", kbd_key_code, code);
            expect_eq("Keyboard released extended", kbd_extended, is_extended);
            expect_eq("Keyboard released LED", kbd_led, expected_led);
        end
    endtask

    task automatic keyboard_pair;
        input [7:0] code;
        input is_extended;
        input [4:0] pressed_led;
        begin
            keyboard_down(code, is_extended, pressed_led);
            keyboard_up(code, is_extended, 5'b00000);
        end
    endtask

    task automatic expect_mouse;
        input integer expected_dx;
        input integer expected_dy;
        input [2:0] expected_buttons;
        input integer expected_x;
        input integer expected_y;
        input [4:0] expected_led;
        begin
            // Explicit sign extension allows negative 9-bit displacement checks.
            expect_eq("Mouse dx", {{23{mouse_dx[8]}}, mouse_dx}, expected_dx);
            expect_eq("Mouse dy", {{23{mouse_dy[8]}}, mouse_dy}, expected_dy);
            expect_eq("Mouse buttons", mouse_buttons, expected_buttons);
            expect_eq("Mouse X", mouse_x, expected_x);
            expect_eq("Mouse Y", mouse_y, expected_y);
            expect_eq("Mouse LED", mouse_led, expected_led);
        end
    endtask

    task automatic mouse_packet;
        input [7:0] header;
        input [7:0] x_byte;
        input [7:0] y_byte;
        input integer expected_dx;
        input integer expected_dy;
        input integer expected_x;
        input integer expected_y;
        input [4:0] expected_led;
        integer before_events;
        begin
            before_events = mouse_packet_events;
            send_device_frame(2, header, 0, 1);
            expect_eq("No packet after header", mouse_packet_events, before_events);
            send_device_frame(2, x_byte, 0, 1);
            expect_eq("No packet after only two bytes", mouse_packet_events, before_events);
            send_device_frame(2, y_byte, 0, 1);
            expect_eq("Exactly one complete packet", mouse_packet_events, before_events + 1);
            expect_eq("Packet index returns to zero", mouse_packet_index, 0);
            expect_mouse(expected_dx, expected_dy, header[2:0],
                         expected_x, expected_y, expected_led);
        end
    endtask

    // Receive a real host command from the open-drain wires. No force/release.
    // Host changes data after device falling edges; sample once data has settled.
    task automatic mouse_receive_host_command;
        integer i;
        begin
            wait (dut_mouse.ps2_clk_drive_low === 1'b1);
            wait (dut_mouse.ps2_clk_drive_low === 1'b0);
            expect_eq("Host start bit", mouse_PS2_DATA, 0);
            #2000;
            for (i = 0; i < 10; i = i + 1) begin
                mouse_clk_low = 1'b1;
                #2000;
                if (i < 8) mouse_host_command[i] = mouse_PS2_DATA;
                else if (i == 8) mouse_host_parity = mouse_PS2_DATA;
                else mouse_host_stop = mouse_PS2_DATA;
                mouse_clk_low = 1'b0;
                #2000;
            end
            // The eleventh device clock acknowledges the host transfer.
            mouse_data_low = 1'b1;
            mouse_clk_low = 1'b1;
            #2000;
            mouse_clk_low = 1'b0;
            #2000;
            mouse_data_low = 1'b0;
            #8000;
            expect_eq("Host command on actual bus", mouse_host_command, 8'hF4);
            expect_eq("Host odd parity", (^mouse_host_command) ^ mouse_host_parity, 1);
            expect_eq("Host stop bit", mouse_host_stop, 1);
            expect_eq("Host TX completed once", mouse_tx_done_events, 1);
            expect_eq("Host bus ACK captured", mouse_tx_ack_events, 1);
            expect_eq("Host TX no error", mouse_tx_error_events, 0);
        end
    endtask

    initial begin
        #200;
        rx_rst_n = 1'b1;
    end

    initial begin : receiver_cases
        #5000;
        rx_case = 1;
        send_device_frame(0, 8'h1D, 0, 1);
        expect_eq("RX legal byte", data_byte, 8'h1D);
        expect_eq("RX legal valid count", rx_valid_events, 1);
        expect_eq("RX legal no error", rx_error_events, 0);
        rx_case = 2;
        send_device_frame(0, 8'h1D, 1, 1);
        expect_eq("Parity error rejected", rx_valid_events, 1);
        expect_eq("Parity error reported", rx_error_events, 1);
        rx_case = 3;
        send_device_frame(0, 8'h1D, 0, 0);
        expect_eq("Stop error rejected", rx_valid_events, 1);
        expect_eq("Stop error reported", rx_error_events, 2);
        rx_case = 4;
        drive_data(0, 0);
        #2000;
        drive_clock(0, 0);
        #2000;
        drive_clock(0, 1);
        drive_data(0, 1);
        #2100000;
        expect_eq("Incomplete frame timeout", rx_error_events, 3);
        expect_eq("Timeout resets bit count", bit_count, 0);
        expect_eq("Timeout has no valid byte", rx_valid_events, 1);
        rx_case = 5;
        send_device_frame(0, 8'hA5, 0, 1);
        expect_eq("RX recovers after timeout", data_byte, 8'hA5);
        expect_eq("RX recovered valid count", rx_valid_events, 2);
        expect_eq("RX final error count", rx_error_events, 3);
        rx_done = 1;
    end

    initial begin : keyboard_cases
        #10000;
        expect_eq("Keyboard reset LED", kbd_led, 0);
        // First screen: extended Up key press and release, including prefixes.
        send_device_frame(1, 8'hE0, 0, 1);
        expect_eq("E0 sets extended pending", kbd_extend_pending, 1);
        expect_eq("E0 is not a key event", kbd_press_events, 0);
        send_device_frame(1, 8'h75, 0, 1);
        expect_eq("Up press count", kbd_press_events, 1);
        expect_eq("Up press extended", kbd_extended, 1);
        expect_eq("Up code", kbd_key_code, 8'h75);
        expect_eq("Up press LED", kbd_led, 5'b00001);
        send_device_frame(1, 8'hE0, 0, 1);
        send_device_frame(1, 8'hF0, 0, 1);
        expect_eq("F0 sets break pending", kbd_break_pending, 1);
        expect_eq("E0 survives F0", kbd_extend_pending, 1);
        expect_eq("F0 is not a release event", kbd_release_events, 0);
        send_device_frame(1, 8'h75, 0, 1);
        expect_eq("Up release count", kbd_release_events, 1);
        expect_eq("Up release extended", kbd_extended, 1);
        expect_eq("Up release LED", kbd_led, 0);
        expect_eq("Extended prefix consumed", kbd_extend_pending, 0);
        expect_eq("Break prefix consumed", kbd_break_pending, 0);

        keyboard_pair(8'h1D, 0, 5'b00001); // W
        keyboard_pair(8'h1B, 0, 5'b00010); // S
        keyboard_pair(8'h1C, 0, 5'b00100); // A
        keyboard_pair(8'h23, 0, 5'b01000); // D
        keyboard_pair(8'h5A, 0, 5'b10000); // Enter
        keyboard_pair(8'h29, 0, 5'b10000); // Space
        keyboard_pair(8'h72, 1, 5'b00010); // Down
        keyboard_pair(8'h6B, 1, 5'b00100); // Left
        keyboard_pair(8'h74, 1, 5'b01000); // Right

        // Current RTL ignores E1 and clears prefixes; it does not decode the
        // full multi-byte Pause/Break sequence. Test only the implemented rule.
        send_device_frame(1, 8'hE0, 0, 1);
        send_device_frame(1, 8'hF0, 0, 1);
        send_device_frame(1, 8'hE1, 0, 1);
        expect_eq("E1 clears extended pending", kbd_extend_pending, 0);
        expect_eq("E1 clears break pending", kbd_break_pending, 0);
        keyboard_down(8'h1D, 0, 5'b00001);
        keyboard_down(8'h1C, 0, 5'b00101); // Simultaneous W + A.
        keyboard_down(8'h76, 0, 5'b00000); // Esc clears every LED.
        keyboard_up(8'h1D, 0, 5'b00000);
        keyboard_up(8'h1C, 0, 5'b00000);
        expect_eq("Keyboard no frame errors", kbd_error_events, 0);
        keyboard_done = 1;
    end

    initial begin : mouse_cases
        #5000;
        expect_eq("Mouse initial X", mouse_x, 511);
        expect_eq("Mouse initial Y", mouse_y, 299);
        mouse_receive_host_command;
        expect_eq("Not ready before response FA", mouse_ready, 0);
        send_device_frame(2, 8'hFA, 0, 1);
        expect_eq("Mouse ready after FA", mouse_ready, 1);
        expect_eq("Mouse initialization successful", mouse_init_error, 0);
        expect_eq("FA is not a motion packet", mouse_packet_events, 0);
        $display("CH6 mouse motion starts at %0.3f us", $realtime / 1000.0);

        // The first three packets are the main mouse screenshot.
        mouse_packet(8'h09, 8'h08, 8'h04,   8,   4,  519, 295, 5'b10110);
        mouse_packet(8'h3A, 8'hFB, 8'hFE,  -5,  -2,  514, 297, 5'b11001);
        mouse_packet(8'h08, 8'h00, 8'h00,   0,   0,  514, 297, 5'b00000);

        // Header bit 3 must be 1. Junk at the packet boundary is ignored.
        send_device_frame(2, 8'h00, 0, 1);
        expect_eq("Invalid header ignored", mouse_packet_events, 3);
        expect_eq("Invalid header keeps index zero", mouse_packet_index, 0);

        // A partial packet does not update displacement, coordinates or LEDs.
        send_device_frame(2, 8'h08, 0, 1);
        send_device_frame(2, 8'h03, 0, 1);
        expect_eq("Partial packet not published", mouse_packet_events, 3);
        expect_eq("Partial packet waiting for Y", mouse_packet_index, 2);
        expect_mouse(0, 0, 0, 514, 297, 5'b00000);
        send_device_frame(2, 8'h01, 0, 1);
        expect_eq("Partial packet completed", mouse_packet_events, 4);
        expect_mouse(3, 1, 0, 517, 296, 5'b00110);

        // Overflow flags hold coordinates. Current RTL still reports dx/dy
        // and drives direction LEDs from those values; do not claim LED hold.
        mouse_packet(8'hC8, 8'h7F, 8'h7F, 127, 127, 517, 296, 5'b00110);
        mouse_packet(8'h08, 8'hFF, 8'hFF, 255, 255, 772,  41, 5'b00110);
        mouse_packet(8'h08, 8'hFF, 8'hFF, 255, 255,1023,   0, 5'b00110);
        mouse_packet(8'h38, 8'h00, 8'h00,-256,-256, 767, 256, 5'b01001);
        mouse_packet(8'h38, 8'h00, 8'h00,-256,-256, 511, 512, 5'b01001);
        mouse_packet(8'h38, 8'h00, 8'h00,-256,-256, 255, 599, 5'b01001);
        mouse_packet(8'h38, 8'h00, 8'h00,-256,-256,   0, 599, 5'b01001);
        expect_eq("Mouse total complete packets", mouse_packet_events, 11);
        expect_eq("Mouse receive no frame errors", mouse_rx_error_events, 0);
        expect_eq("Mouse remains ready", mouse_ready, 1);
        mouse_done = 1;
    end

    initial begin : report_result
        wait (rx_done && keyboard_done && mouse_done);
        #1000;
        checks_pass = (errors == 0);
        checks_done = 1;
        if (checks_pass)
            $display("CH6 PASS at %0.3f us: RX valid=%0d error=%0d; keyboard press=%0d release=%0d; mouse packets=%0d ACK=%0d",
                     $realtime / 1000.0, rx_valid_events, rx_error_events,
                     kbd_press_events, kbd_release_events,
                     mouse_packet_events, mouse_tx_ack_events);
        else
            $display("CH6 FAIL: errors=%0d", errors);
    end

    initial begin : watchdog
        #5000000;
        if (!checks_done) begin
            errors = errors + 1;
            checks_pass = 0;
            checks_done = 1;
            $display("CH6 FAIL: timeout; rx_done=%b keyboard_done=%b mouse_done=%b",
                     rx_done, keyboard_done, mouse_done);
        end
    end
endmodule
