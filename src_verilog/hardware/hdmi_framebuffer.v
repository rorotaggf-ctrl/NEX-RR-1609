module hdmi_framebuffer (
    input  wire        pixel_clk,     // 25.2 MHz VGA Pixeltakt
    input  wire        rst_n,

    // Speicherbus-Verbindung zum Arbiter
    output reg  [21:0] fb_read_addr,
    input  wire [15:0] fb_pixel_data, // RGB565 Bilddaten
    output reg         fb_req,

    // Bildkoordinaten fuer interne Overlays / Logik
    output wire [9:0]  pixel_x,
    output wire [9:0]  pixel_y,
    output reg         hsync,
    output reg         vsync,
    output reg         video_active,
    output reg  [15:0] rgb_out
);

    // 640x480 @ 60 Hz Parameter
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = 525;

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    assign pixel_x = (h_cnt < H_ACTIVE) ? h_cnt : 10'd0;
    assign pixel_y = (v_cnt < V_ACTIVE) ? v_cnt : 10'd0;

    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt        <= 10'd0;
            v_cnt        <= 10'd0;
            hsync        <= 1'b1;
            vsync        <= 1'b1;
            video_active <= 1'b0;
            fb_read_addr <= 22'd0;
            fb_req       <= 1'b0;
            rgb_out      <= 16'd0;
        end else begin
            // Zeilen- und Bildzaehler
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 10'd0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end

            // Sync-Impulse (VGA Standard: Active LOW)
            hsync <= ~((h_cnt >= (H_ACTIVE + H_FRONT)) && (h_cnt < (H_ACTIVE + H_FRONT + H_SYNC)));
            vsync <= ~((v_cnt >= (V_ACTIVE + V_FRONT)) && (v_cnt < (V_ACTIVE + V_FRONT + V_SYNC)));

            // Sichtbarer Bildbereich
            if ((h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE)) begin
                video_active <= 1'b1;
                fb_req       <= 1'b1;
                // Lineare Framebuffer-Adresse: y * 640 + x
                fb_read_addr <= (v_cnt * H_ACTIVE) + h_cnt;
                rgb_out      <= fb_pixel_data;
            end else begin
                video_active <= 1'b0;
                fb_req       <= 1'b0;
                rgb_out      <= 16'd0;
            end
        end
    end

endmodule