module collision_detector (
    input WRITE_DATA,
    input n_SEND,
    inout DATALINE,
    output reg COLLISION_DETECTED
);
    // let the line float high if not writing
    assign DATALINE = !n_SEND ? WRITE_DATA : 1;

    always @ (*) begin
        if (DATALINE != WRITE_DATA)
            COLLISION_DETECTED = 1;
        else
            COLLISION_DETECTED = 0;
    end
endmodule