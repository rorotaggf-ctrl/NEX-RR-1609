module ps2_receiver (
    input  wire       clk,        // 27 MHz
    input  wire       rst_n,      // Reset (Low-aktiv)
    input  wire       ps2_clk,
    input  wire       ps2_data,
    output reg  [7:0] rx_data,
    output reg        rx_ready
);
    reg [5:0] filter;
    reg       ps2_clk_clean;
    reg       ps2_clk_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter        <= 6'b111111;
            ps2_clk_clean <= 1'b1;
            ps2_clk_prev  <= 1'b1;
        end else begin
            filter <= {filter[4:0], ps2_clk};
            if (filter == 6'b000000)
                ps2_clk_clean <= 1'b0;
            else if (filter == 6'b111111)
                ps2_clk_clean <= 1'b1;
            ps2_clk_prev <= ps2_clk_clean;
        end
    end

    wire clk_edge = (ps2_clk_prev == 1'b1 && ps2_clk_clean == 1'b0);

    reg [10:0] shift_reg;
    reg [3:0]  count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count     <= 4'd0;
            shift_reg <= 11'd0;
            rx_data   <= 8'd0;
            rx_ready  <= 1'b0;
        end else begin
            rx_ready <= 1'b0;
            if (clk_edge) begin
                shift_reg <= {ps2_data, shift_reg[10:1]};
                if (count == 4'd10) begin
                    rx_data  <= shift_reg[9:2]; // Nutzdaten
                    rx_ready <= 1'b1;
                    count    <= 4'd0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule