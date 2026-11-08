module sound_gen (
    input  wire        clk,        // Systemtakt (40.5 MHz)
    input  wire        rst_n,

    // Bus-Anbindung fuer CPU (Memory-Mapped IO an 0x80000008)
    input  wire        we,         // Write-Enable
    input  wire [31:0] wdata,      // Bits [15:0] = Frequenzteiler, Bit [16] = Enable

    output reg  [15:0] audio_pcm   // 16-Bit Audiosample an HDMI-Audio
);

    reg [3:0]  prescaler;
    reg [15:0] period_cnt;
    reg [15:0] divider;
    reg        sound_en;
    reg        sq_wave;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler  <= 4'd0;
            divider    <= 16'd0;
            sound_en   <= 1'b0;
            period_cnt <= 16'd0;
            sq_wave    <= 1'b0;
            audio_pcm  <= 16'd0;
        end else begin
            if (we) begin
                divider  <= wdata[15:0];
                sound_en <= wdata[16];
            end

            // Prescaler teilt 40.5 MHz durch 16 -> Basis = ca. 2.531.250 Hz
            prescaler <= prescaler + 1'b1;
            if (prescaler == 4'd15) begin
                if (sound_en && (divider > 0)) begin
                    if (period_cnt >= divider) begin
                        period_cnt <= 16'd0;
                        sq_wave    <= ~sq_wave;
                    end else begin
                        period_cnt <= period_cnt + 1'b1;
                    end
                    audio_pcm <= sq_wave ? 16'h3FFF : 16'hC000;
                end else begin
                    period_cnt <= 16'd0;
                    sq_wave    <= 1'b0;
                    audio_pcm  <= 16'd0;
                end
            end
        end
    end

endmodule