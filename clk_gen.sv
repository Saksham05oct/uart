module clk_gen(
    input clk, rst,
    input [16:0] baud,
    output tx_clk, rx_clk
);

int rx_max = 0, tx_max = 0;
int rx_cnt = 0, tx_cnt = 0;

always@(posedge clk) begin
    if(rst) begin
        tx_max <= 0;
        rx_max <= 0;
    end
    else begin
        case(baud)
            4800: begin
                rx_max <= 11'd651; // 10416 / 16 == 651
                tx_max <= 14'd10416;
            end
            9600: begin
                rx_max <= 11'd325;
                tx_max <= 14'd5208;
            end
            14400: begin
                rx_max <= 11'd217;
                tx_max <= 14'd3472;
            end
            19200: begin
                rx_max <= 11'd163;
                tx_max <= 14'd2604;
            end
            38400: begin
                rx_max <= 11'd81;
                tx_max <= 14'd1302;
            end
            57600: begin
                rx_max <= 11'd54;
                tx_max <= 14'd868;
            end
            default: begin
                rx_max <= 11'd325;
                tx_max <= 14'd5208;
            end
        endcase
    end
end

always@(posedge clk) begin
    if(rst) begin
        rx_cnt <= 0;
    end
    else begin
        if(rx_cnt < rx_max) begin
            rx_cnt <= rx_cnt + 1;
        end
        else begin   
            rx_cnt <= 0;
        end
    end
end

assign rx_clk = ( rx_cnt ==rx_max );

always@(posedge clk) begin
    if(rst) begin
        tx_cnt <= 0;
    end
    else begin
        if(tx_cnt < tx_max) begin
            tx_cnt <= tx_cnt + 1;
        end
        else begin 
            tx_cnt <= 0;
        end
    end
end

assign tx_clk = (tx_cnt == tx_max);
endmodule



interface clk_if;
    logic clk, rst;
    logic [16:0] baud;
    logic tx_clk, rx_clk;
endinterface