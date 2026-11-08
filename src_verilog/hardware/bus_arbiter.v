module bus_arbiter (
    input  wire        clk,
    input  wire        rst_n,

    // Port 0: HDMI Framebuffer (Prioritäts-Port)
    input  wire        hdmi_req,
    input  wire [21:0] hdmi_addr,
    output reg  [15:0] hdmi_data,

    // Port 1-6: 6 CPU Cores (Gepackte Busse zur LUT-Minimierung)
    input  wire [5:0]  cpu_req,          // Request-Bits für Core 0 bis 5
    input  wire [5:0]  cpu_we,           // Write-Enable (1=SW, 0=LW)
    input  wire [131:0] cpu_addr_packed, // 6 x 22-Bit Adressen
    input  wire [191:0] cpu_wdata_packed,// 6 x 32-Bit Schreibdaten
    output reg  [31:0] cpu_rdata,        // Gelesenes 32-Bit-Wort für alle Kerne
    output reg  [5:0]  cpu_grant,        // Rückmeldung, welcher Kern aktiv ist

    // Verbindung zum PSRAM-Controller
    output reg         psram_cmd_en,
    output reg         psram_we,
    output reg  [21:0] psram_addr,
    output reg  [31:0] psram_wdata,
    input  wire [31:0] psram_rdata,
    input  wire        psram_ready
);

    reg [2:0] turn; // 0 bis 5 (Zustand 6 und 7 entfallen)

    // Entpacken der Bus-Leitungen
    wire [21:0] c_addr  [0:5];
    wire [31:0] c_wdata [0:5];

    assign c_addr[0]  = cpu_addr_packed[21:0];
    assign c_addr[1]  = cpu_addr_packed[43:22];
    assign c_addr[2]  = cpu_addr_packed[65:44];
    assign c_addr[3]  = cpu_addr_packed[87:66];
    assign c_addr[4]  = cpu_addr_packed[109:88];
    assign c_addr[5]  = cpu_addr_packed[131:110];

    assign c_wdata[0] = cpu_wdata_packed[31:0];
    assign c_wdata[1] = cpu_wdata_packed[63:32];
    assign c_wdata[2] = cpu_wdata_packed[95:64];
    assign c_wdata[3] = cpu_wdata_packed[127:96];
    assign c_wdata[4] = cpu_wdata_packed[159:128];
    assign c_wdata[5] = cpu_wdata_packed[191:160];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            turn         <= 3'd0;
            cpu_grant    <= 6'b000000;
            psram_cmd_en <= 1'b0;
            psram_we     <= 1'b0;
            psram_addr   <= 22'd0;
            psram_wdata  <= 32'd0;
            cpu_rdata    <= 32'd0;
            hdmi_data    <= 16'd0;
        end else begin
            psram_cmd_en <= 1'b0;
            cpu_grant    <= 6'b000000;

            if (hdmi_req) begin
                // HDMI Prio-Zugriff
                psram_addr   <= hdmi_addr;
                psram_we     <= 1'b0;
                psram_cmd_en <= 1'b1;
                if (psram_ready)
                    hdmi_data <= psram_rdata[15:0];
            end else if (cpu_req[turn]) begin
                // Aktiver CPU-Kern ist am Zug
                psram_addr        <= c_addr[turn];
                psram_wdata       <= c_wdata[turn];
                psram_we          <= cpu_we[turn];
                psram_cmd_en      <= 1'b1;
                cpu_grant[turn]   <= psram_ready;
                if (psram_ready) begin
                    cpu_rdata <= psram_rdata;
                    // Weiter zum nächsten Kern
                    turn <= (turn == 3'd5) ? 3'd0 : turn + 1'b1;
                end
            end else begin
                // Kein Request auf diesem Kern -> sofort weiterschalten
                turn <= (turn == 3'd5) ? 3'd0 : turn + 1'b1;
            end
        end
    end

endmodule