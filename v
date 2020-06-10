`timescale 1ns/10ps
module RC4(clk,rst,key_valid,key_in,plain_read,plain_in_valid,plain_in,plain_write,plain_out,cipher_write,cipher_out,cipher_read,cipher_in,cipher_in_valid,done);
    input clk,rst;
    input key_valid,plain_in_valid,cipher_in_valid;
    input [7:0] key_in,cipher_in,plain_in;
    output done;
    output plain_write,cipher_write,plain_read,cipher_read;
    output [7:0] cipher_out,plain_out;
    
    reg [7:0] key[31:0];
    reg [7:0] key_count;
    reg [7:0] Sbox[63:0];
    reg [7:0] j;
    wire [5:0] key_index,i_new,j_new;
    wire [5:0] temp;
    
    reg done;
    reg plain_write,cipher_write,plain_read,cipher_read;
    reg [7:0] cipher_out;
    reg [7:0] plain_out;
    
    parameter  state_bit = 4;
    localparam [ state_bit - 1 : 0 ]    WaitKey         = 0;
    localparam [ state_bit - 1 : 0 ]    GetKey          = 1;
    localparam [ state_bit - 1 : 0 ]    SboxProcess     = 2;
    localparam [ state_bit - 1 : 0 ]    GetPlain        = 3;
    localparam [ state_bit - 1 : 0 ]    WriteCipher     = 4;
    localparam [ state_bit - 1 : 0 ]    InitSbox        = 5;
    localparam [ state_bit - 1 : 0 ]    SboxProcess2    = 6;
    localparam [ state_bit - 1 : 0 ]    GetCipher       = 7;
    localparam [ state_bit - 1 : 0 ]    WritePlain      = 8;
    localparam [ state_bit - 1 : 0 ]    Done            = 9;
    reg [ state_bit - 1 : 0 ] cur_state,next_state;

    integer i;

    assign key_index = ( j + Sbox[key_count] + key[key_count[4:0]] );
    assign i_new = key_count + 1;
    assign j_new = j + Sbox[i_new];
    assign temp = Sbox[i_new] + Sbox[j_new];

    always @ ( * ) begin
        case ( cur_state ) 
            WaitKey : begin
                if ( key_valid )
                    next_state = GetKey;
                else 
                    next_state = WaitKey;
            end
            GetKey : begin
                if ( !key_valid )
                    next_state = SboxProcess;
                else
                    next_state = GetKey;
            end
            SboxProcess : begin
                if ( key_count < 63)
                    next_state = SboxProcess;
                else
                    next_state = GetPlain;
            end
            GetPlain : begin
                next_state = WriteCipher;
            end
            WriteCipher : begin
                if (!plain_in_valid)
                    next_state = InitSbox;
                else
                    next_state = WriteCipher;
            end
            InitSbox : 
                next_state = SboxProcess2;
            SboxProcess2 : begin
                if ( key_count < 63)
                    next_state = SboxProcess2;
                else
                    next_state = GetCipher;
            end
            GetCipher : 
                next_state = WritePlain;
            WritePlain : begin
                if (!cipher_in_valid)
                    next_state = Done;
                else
                    next_state = WritePlain;
            end
            default : begin
                next_state = Done;
            end
        endcase
    end
    
    always @ ( posedge clk or posedge rst ) begin
        if (rst) begin
            key_count <= 0;
            cur_state <= WaitKey;
            for ( i = 0 ; i < 64 ; i = i + 1 ) begin
                Sbox[i] <= i;
            end
            plain_write <= 0;
            cipher_write <= 0;
            plain_read <= 0;
            cipher_read <= 0;
            j <= 0;
            done <= 0;
        end
        else begin
            cur_state <= next_state;
            case ( cur_state )
                GetKey : begin
                    if ( key_valid ) begin
                        key_count <= key_count + 1;
                        key[key_count] <= key_in;
                    end
                    else begin 
                        key_count <= 0;
                    end
                end
                SboxProcess : begin
                    j <= key_index;
                    Sbox[key_count] <= Sbox[key_index];
                    Sbox[key_index] <= Sbox[key_count];
                    key_count <= key_count + 1;
                end
                GetPlain: begin
                    plain_read <= 1;
                    j <= 0;
                    key_count <= 0; //i
                end
                WriteCipher : begin
                    if (plain_in_valid) begin
                        plain_read <= 1;
                        Sbox[i_new] <= Sbox[j_new];
                        Sbox[j_new] <= Sbox[i_new];
                        if ( temp == i_new)
                            cipher_out <= plain_in ^ Sbox[j_new];
                        else if ( temp == j_new )
                            cipher_out <= plain_in ^ Sbox[i_new];
                        else 
                            cipher_out <= plain_in ^ Sbox[temp];
                        cipher_write <= 1;
                        key_count <= i_new;
                        j <= j_new;
                    end
                    else
                        plain_read <= 0;
                end
                InitSbox : begin
                    cipher_write <= 0;
                    for ( i = 0 ; i < 64 ; i = i + 1 ) begin
                        Sbox[i] <= i;
                    end
                    j <=0;
                    key_count <= 0;
                end
                SboxProcess2 : begin
                    j <= key_index;
                    Sbox[key_count] <= Sbox[key_index];
                    Sbox[key_index] <= Sbox[key_count];
                    key_count <= key_count + 1;
                end
                GetCipher : begin
                    cipher_read <= 1;
                    j <= 0;
                    key_count <= 0; //i
                end
                WritePlain : begin
                    if (cipher_in_valid) begin
                        cipher_read <= 1;
                        Sbox[i_new] <= Sbox[j_new];
                        Sbox[j_new] <= Sbox[i_new];
                        if ( temp == i_new)
                            plain_out <= cipher_in ^ Sbox[j_new];
                        else if ( temp == j_new )
                            plain_out <= cipher_in ^ Sbox[i_new];
                        else 
                            plain_out <= cipher_in ^ Sbox[temp];
                        plain_write <= 1;
                        key_count <= i_new;
                        j <= j_new;
                    end
                    else
                        cipher_read <= 0;
                end
                Done : begin
                    plain_write <= 0;
                    done <= 1;
                end
            endcase
        end
    end


endmodule
