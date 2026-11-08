module spi_sd_reader (
    input  wire        clk,        // Systemtakt (40.5 MHz)
    input  wire        rst_n,

    // CPU-Bus-Schnittstelle
    input  wire        cs_ctrl,    // 1 = SD_CS High (deaktiviert), 0 = SD_CS Low (aktiviert)
    input  wire        start_tx,   // 1 Takt Impuls: Starte Byte-Transfer
    input  wire [7:0]  tx_data,    // Zu sendendes Byte
    output reg  [7:0]  rx_data,    // Empfangenes Byte
    output reg         busy,       // 1 = Transfer laeuft

    // Physische SPI-Pins zur SD-Karte
    output reg         sd_cs_n,
    output reg         sd_sck,
    output reg         sd_mosi,
    input  wire        sd_miso
);

    reg [5:0] clk_div;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg [1:0] state;

    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sd_cs_n   <= 1'b1;
            sd_sck    <= 1'b0;
            sd_mosi   <= 1'b1;
            rx_data   <= 8'hFF;
            busy      <= 1'b0;
            state     <= IDLE;
            clk_div   <= 6'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'hFF;
        end else begin
            sd_cs_n <= cs_ctrl;

            case (state)
                IDLE: begin
                    sd_sck  <= 1'b0;
                    sd_mosi <= 1'b1;
                    if (start_tx) begin
                        shift_reg <= tx_data;
                        bit_cnt   <= 3'd7;
                        clk_div   <= 6'd0;
                        busy      <= 1'b1;
                        state     <= RUN;
                    end else begin
                        busy <= 1'b0;
                    end
                end

                RUN: begin
                    // Teilt 40.5 MHz auf ca. 400 kHz fuer Initialisierung herunter
                    clk_div <= clk_div + 1'b1;
                    if (clk_div == 6'd49) begin
                        sd_sck  <= 1'b1;
                        // MISO einlesen
                        shift_reg[0] <= sd_miso;
                    end else if (clk_div == 6'd99) begin
                        clk_div <= 6'd0;
                        sd_sck  <= 1'b0;
                        if (bit_cnt == 3'd0) begin
                            rx_data <= shift_reg;
                            busy    <= 1'b0;
                            state   <= IDLE;
                        end else begin
                            shift_reg <= {shift_reg[6:0], 1'b1};
                            bit_cnt   <= bit_cnt - 1'b1;
                        end
                    end
                    sd_mosi <= shift_reg[7];
                end
            endcase
        end
    end

endmodule