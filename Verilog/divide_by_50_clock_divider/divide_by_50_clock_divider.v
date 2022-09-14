module divide_by_50_clock_divider (
    input n_RST,
    input CLK_IN,
    output reg CLK_OUT
);
    reg [5:0] counter;
    always @ (n_RST, posedge CLK_IN) begin
        if (~n_RST) begin
            counter <= 5'd24;
            CLK_OUT <= 1;
        end else begin
            if (counter == 6'd0) begin
                counter [4:0] <= 5'd24;
                CLK_OUT <= ~CLK_OUT;
            end else begin
                counter [4:0] <= counter - 1'b1;
            end
        end
    end        
endmodule