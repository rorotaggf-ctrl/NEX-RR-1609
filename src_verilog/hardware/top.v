module top (
    input  wire       clk_27m,        // 27 MHz Quarz-Oszillator (Pin 52)
    input  wire       btn_rst_n,      // Reset-Taster S1 (Low-aktiv)

    // PS/2 Peripherie (externe GPIO-Pins)
    input  wire       ps2_kbd_clk,
    input  wire       ps2_kbd_dat,
    input  wire       ps2_mouse_clk,
    input  wire       ps2_mouse_dat,

    // PSRAM Interface (interner 64-MBit PSRAM-Chip)
    output wire       O_psram_ck,
    output wire       O_psram_cs_n,
    inout  wire [3:0] IO_psram_dq,

    // HDMI Differenzsignale (TMDS)
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n,

    // Onboard Status-LEDs (Low-aktiv geschaltet)
    output wire [5:0] leds
);

    // Takt-Verdrahtung: 27 MHz Basistakt (später via PLL auf 40.5 MHz / 25.2 MHz)
    wire clk_cpu;
    wire clk_pixel;

    assign clk_cpu   = clk_27m; 
    assign clk_pixel = clk_27m;

    // Dual PS/2 Receiver fuer Tastatur und Maus
    wire [7:0] kbd_data, mouse_data;
    wire       kbd_ready, mouse_ready;

    ps2_receiver u_kbd (
        .clk      (clk_cpu),
        .rst_n    (btn_rst_n),
        .ps2_clk  (ps2_kbd_clk),
        .ps2_data (ps2_kbd_dat),
        .rx_data  (kbd_data),
        .rx_ready (kbd_ready)
    );

    ps2_receiver u_mouse (
        .clk      (clk_cpu),
        .rst_n    (btn_rst_n),
        .ps2_clk  (ps2_mouse_clk),
        .ps2_data (ps2_mouse_dat),
        .rx_data  (mouse_data),
        .rx_ready (mouse_ready)
    );

    // HDMI Framebuffer Generator
    wire [21:0] fb_addr;
    wire [15:0] fb_pixel;
    wire        fb_req;
    wire [15:0] rgb_video;
    wire        hsync, vsync, active_video;

    hdmi_framebuffer u_fb (
        .pixel_clk     (clk_pixel),
        .rst_n         (btn_rst_n),
        .fb_read_addr  (fb_addr),
        .fb_pixel_data (fb_pixel),
        .fb_req        (fb_req),
        .pixel_x       (),
        .pixel_y       (),
        .hsync         (hsync),
        .vsync         (vsync),
        .video_active  (active_video),
        .rgb_out       (rgb_video)
    );

    // Speichercontroller fuer den externen 8 MB PSRAM
    wire        arb_cmd_en, arb_we, psram_ready;
    wire [21:0] arb_addr;
    wire [31:0] arb_wdata, psram_rdata;

    psram_controller u_psram (
        .clk        (clk_cpu),
        .rst_n      (btn_rst_n),
        .cmd_en     (arb_cmd_en),
        .we         (arb_we),
        .addr       (arb_addr),
        .wdata      (arb_wdata),
        .rdata      (psram_rdata),
        .ready      (psram_ready),
        .psram_ce_n (O_psram_cs_n),
        .psram_sclk (O_psram_ck),
        .psram_sio  (IO_psram_dq)
    );

    // Bus Arbiter: Verteilt Zugriffe zwischen den 6 CPU-Kernen und HDMI
    wire [5:0]   core_req;
    wire [5:0]   core_we;
    wire [131:0] core_addr_packed;
    wire [191:0] core_wdata_packed;
    wire [31:0]  shared_rdata;
    wire [5:0]   core_grant;

    bus_arbiter u_arbiter (
        .clk              (clk_cpu),
        .rst_n            (btn_rst_n),
        .hdmi_req         (fb_req),
        .hdmi_addr        (fb_addr),
        .hdmi_data        (fb_pixel),
        .cpu_req          (core_req),
        .cpu_we           (core_we),
        .cpu_addr_packed  (core_addr_packed),
        .cpu_wdata_packed (core_wdata_packed),
        .cpu_rdata        (shared_rdata),
        .cpu_grant        (core_grant),
        .psram_cmd_en     (arb_cmd_en),
        .psram_we         (arb_we),
        .psram_addr       (arb_addr),
        .psram_wdata      (arb_wdata),
        .psram_rdata      (psram_rdata),
        .psram_ready      (psram_ready)
    );

    // 6 parallele RV32I Prozessorkerne
    genvar c;
    generate
    for (c = 0; c < 6; c = c + 1) begin : CORES
        wire [31:0] pc_debug;
        wire [31:0] r1_debug;
        wire [31:0] r2_debug;

        // Keine Speicherports vorhanden - Dummy-Werte an den Arbiter-Bus
        assign core_addr_packed[c*22 +: 22]  = pc_debug[21:0];
        assign core_wdata_packed[c*32 +: 32] = r1_debug;
        assign core_req[c]                   = 1'b0;
        assign core_we[c]                    = 1'b0;

        cpu u_core (
            .CLK     (clk_cpu),
            .CLR     (~btn_rst_n),
            .PC_Test (pc_debug),
            .R1_Test (r1_debug),
            .R2_Test (r2_debug)
        );
        end
    endgenerate

    // Onboard LEDs: Signalisiert Bus-Aktivitaet der Kerne und Tastatureingang
    assign leds[0] = ~core_grant[0];
    assign leds[1] = ~core_grant[1];
    assign leds[2] = ~core_grant[2];
    assign leds[3] = ~core_grant[3];
    assign leds[4] = ~core_grant[4];
    assign leds[5] = ~kbd_ready;

endmodule