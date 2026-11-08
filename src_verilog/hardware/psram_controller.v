module psram_controller (
    input  wire        clk,        // Systemtakt (40.5 MHz)
    input  wire        rst_n,

    // Schnittstelle vom Bus-Arbiter
    input  wire        cmd_en,
    input  wire        we,         // 1 = Write, 0 = Read
    input  wire [21:0] addr,       // Wortadresse (32-Bit ausgerichtet)
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output reg         ready,

    // Physische Pins zum externen PSRAM-Chip
    output reg         psram_ce_n,
    output reg         psram_sclk,
    inout  wire [3:0]  psram_sio
);

    localparam IDLE  = 3'd0;
    localparam CMD   = 3'd1;
    localparam ADDR  = 3'd2;
    localparam DUMMY = 3'd3;
    localparam DATA  = 3'd4;
    localparam DONE  = 3'd5;

    reg [2:0] state;
    reg [4:0] step;
    reg [3:0] sio_out;
    reg       sio_oe;

    assign psram_sio = sio_oe ? sio_out : 4'bzzzz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            step       <= 5'd0;
            psram_ce_n <= 1'b1;
            psram_sclk <= 1'b0;
            sio_oe     <= 1'b0;
            ready      <= 1'b0;
            rdata      <= 32'd0;
        end else begin
            ready <= 1'b0;
            case (state)
                IDLE: begin
                    psram_ce_n <= 1'b1;
                    psram_sclk <= 1'b0;
                    sio_oe     <= 1'b0;
                    step       <= 5'd0;
                    if (cmd_en) begin
                        psram_ce_n <= 1'b0;
                        state      <= CMD;
                    end
                end

                CMD: begin
                    // QPI Fast Read (0xEB) oder Quad Write (0x38)
                    sio_oe     <= 1'b1;
                    psram_sclk <= ~psram_sclk;
                    if (psram_sclk) begin
                        step <= step + 1'b1;
                        if (step == 5'd1) begin
                            step  <= 5'd0;
                            state <= ADDR;
                        end
                    end
                    sio_out <= we ? 4'h3 : 4'hE;
                end

                ADDR: begin
                    // 24-Bit-Adressübertragung in 6 Halbzyklen
                    psram_sclk <= ~psram_sclk;
                    if (psram_sclk) begin
                        step <= step + 1'b1;
                        if (step == 5'd5) begin
                            step  <= 5'd0;
                            state <= we ? DATA : DUMMY;
                        end
                    end
                    sio_out <= addr[21:18];
                end

                DUMMY: begin
                    // Wait-States für Read-Latenz
                    sio_oe     <= 1'b0;
                    psram_sclk <= ~psram_sclk;
                    if (psram_sclk) begin
                        step <= step + 1'b1;
                        if (step == 5'd5) begin
                            step  <= 5'd0;
                            state <= DATA;
                        end
                    end
                end

                DATA: begin
                    psram_sclk <= ~psram_sclk;
                    if (we) begin
                        sio_oe  <= 1'b1;
                        sio_out <= wdata[31:28];
                    end else begin
                        sio_oe <= 1'b0;
                        if (!psram_sclk)
                            rdata <= {rdata[27:0], psram_sio};
                    end

                    if (psram_sclk) begin
                        step <= step + 1'b1;
                        if (step == 5'd7) begin
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    psram_ce_n <= 1'b1;
                    psram_sclk <= 1'b0;
                    ready      <= 1'b1;
                    state      <= IDLE;
                end
            endcase
        end
    end

endmodule