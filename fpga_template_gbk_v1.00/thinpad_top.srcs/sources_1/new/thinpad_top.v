`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч  chipenable
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );
reg reset_of_clk10M,reset_of_clk50M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end



 //base ram
wire[3:0] cpu_base_sel_o;
wire cpu_base_ce_o; 
(*mark_debug = "TRUE"*)reg cpu_base_we; 
wire [31:0] cpu_base_addr;
wire [31:0] cpu_data_to_base;
reg [31:0] cpu_data_from_base=32'd0;

reg [31:0] get_basedata;
//extra ram
wire[3:0] cpu_ext_sel_o;
reg cpu_ext_ce_o; 
wire cpu_ext_we_o; 
reg [31:0] cpu_data_to_ext;
reg [31:0] cpu_data_from_ext=32'd0;
//uart
wire [31:0] cpu_data_to_uart;
wire [31:0] cpu_data_from_uart;
//cpu output
(*mark_debug = "TRUE"*)wire [31:0] cpu_dout;
(*mark_debug = "TRUE"*)wire[31:0] cpu_addr_o;
(*mark_debug = "TRUE"*)wire cpu_ce_o;
reg [31:0]cpu_din;

MYmips cpu_v1(
 .clk(clk_10M),
 .rst(reset_of_clk10M),
  //base_ram
 .rom_data_i(cpu_data_from_base),
 .rom_addr_o(cpu_base_addr),
 .rom_ce_o(cpu_base_ce_o),
  //extra_ram
 .ram_data_i(cpu_din),
 .ram_addr_o(cpu_addr_o),
 .ram_data_o(cpu_dout),
 .ram_we_o(cpu_ext_we_o),
 .ram_sel_o(cpu_ext_sel_o),
 .ram_ce_o(cpu_ce_o)
);

wire base_iodata_en,ext_iodata_en;
wire base_read_ready,ext_read_ready;

sram32_con base_ram_controller(
    .clk(clk_10M),    .rst(reset_of_clk10M),
    .clk_50M(clk_50M),
    .we_i(cpu_base_we),//д����   ����Ч   ��cpu��we
//    .we_i(1'b0),//д����   ����Ч   ��cpu��we
    .ce_i(cpu_base_ce_o),
    .read_ready(base_read_ready),//����ɣ��Ѵ�ram��ȡ��dataʱ����
    .iodata_en(base_iodata_en),//��̬�ſ����ź�
    .ce_n(base_ram_ce_n),//ce  chipenabled
    .oe_n(base_ram_oe_n),//��ʹ��
    .we_n(base_ram_we_n)//weдʹ��
    );
    assign base_ram_be_n = (!cpu_addr_o[22]&&cpu_ce_o)?~cpu_ext_sel_o:4'b0;
    assign base_ram_data = base_iodata_en ? cpu_data_to_ext:32'hzzzz;//cpu_data_to_ext,������д��base ram
    assign base_ram_addr = (!cpu_addr_o[22]&&cpu_ce_o)?cpu_addr_o[21:2]:cpu_base_addr[21:2];

(*mark_debug = "TRUE"*)reg [31:0]inst_buffer;
(*mark_debug = "TRUE"*)reg [31:0]data_buffer_for_baseram;
always@(*) begin
    if(reset_of_clk10M)begin
        inst_buffer=32'b0;
        data_buffer_for_baseram=32'b0;
    end
    else begin
        if(!cpu_addr_o[22]&&cpu_ce_o&&base_read_ready)begin
            inst_buffer =32'b0;
            data_buffer_for_baseram = base_ram_data;
        end else begin
        inst_buffer = base_read_ready ? base_ram_data:32'b0;
        data_buffer_for_baseram =32'b0;
        end
    end
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        cpu_data_from_base<=32'b0;
        get_basedata<=32'b0;
    end else begin
        cpu_data_from_base<=inst_buffer;
        get_basedata<=data_buffer_for_baseram;
    end
end

sram32_con ext_ram_controller(
    .clk(clk_10M),    .rst(reset_of_clk10M), 
    .clk_50M(clk_50M),
    .we_i(cpu_ext_we_o),//д����   ����Ч   ��cpu��we
    .ce_i(cpu_ext_ce_o),
    .read_ready(ext_read_ready),//����ɣ��Ѵ�ram��ȡ��dataʱ����
    .iodata_en(ext_iodata_en),//��̬�ſ����ź�
    .ce_n(ext_ram_ce_n),//ce  chipenabled
    .oe_n(ext_ram_oe_n),//��ʹ��
    .we_n(ext_ram_we_n)//weдʹ��
    );
    assign ext_ram_be_n = ~cpu_ext_sel_o;
    assign ext_ram_data = ext_iodata_en ? cpu_data_to_ext:32'hzzzz;//дram
    
     assign ext_ram_addr = cpu_addr_o[21:2];
    wire [19:0]forsim_ram_addr;
    assign forsim_ram_addr = cpu_addr_o[19:0];//��ram�ô��ַ

(*mark_debug = "TRUE"*)reg [31:0]data_buffer_for_extram;
always@(*) begin
    if(reset_of_clk10M)begin
        data_buffer_for_extram<=32'b0;//data������
    end
    else begin
        if(cpu_addr_o[22]&&cpu_ce_o&&ext_read_ready)begin
            data_buffer_for_extram <= ext_ram_data;
        end else begin
            data_buffer_for_extram <=32'b0;
        end
    end
end    
always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        cpu_data_from_ext<=32'b0;
    end else begin
        cpu_data_from_ext<=data_buffer_for_extram;
    end
end    

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
(*mark_debug = "TRUE"*)reg  [7:0] ext_uart_buffer, ext_uart_tx;
(*mark_debug = "TRUE"*)wire ext_uart_ready;
(*mark_debug = "TRUE"*)wire ext_uart_busy;
(*mark_debug = "TRUE"*)reg ext_uart_start, ext_uart_avai;
reg ext_uart_clear=1'b1;//��ʼ����ʹrxd_ready=0

//���ڿ�����
`define uart_addr 32'hbfd003f8
`define uart_state_addr 32'hbfd003fc

reg [7:0] cpu_to_uart;
(*mark_debug = "TRUE"*)reg cpu_uart_ce_o;
//���ڡ�baseram��extram�ٲ�
always@(*) begin
    cpu_din=32'b0;
    cpu_to_uart=8'b00000000;
    if(reset_of_clk10M)begin//Ĭ�Ϲرմ��ں�ram
            cpu_ext_ce_o=1'b0;
            cpu_uart_ce_o=1'b0;
            cpu_base_we=1'b0;//base ram Ĭ�϶�����
            ext_uart_clear = 1'b1;
//             cpu_din=32'b0;
//            cpu_to_uart=8'b00000000;
            cpu_data_to_ext=32'b0;
        end
    else begin
        if(cpu_ext_we_o&&cpu_ce_o)//дram or �򴮿ڷ�����
        begin
            ext_uart_clear = 1'b0;//����ն���־
            if(cpu_addr_o==`uart_addr)begin//����
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b1;//�򿪴���
                cpu_base_we=1'b0;//base ram Ĭ�϶�����
//                 cpu_din=32'b0;
                cpu_to_uart=cpu_dout[7:0];//��8λ
                cpu_data_to_ext=32'b0;
            end
            else if(cpu_addr_o==`uart_state_addr)begin//����״̬λ��ֻ�ɶ�������д
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                cpu_base_we=1'b0;//base ram Ĭ�϶�����
//                 cpu_din=32'b0;
//                cpu_to_uart=8'b00000000;//��
                cpu_data_to_ext=32'b0;
            end
            else if(!cpu_addr_o[22])begin//����baseram
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                cpu_base_we=1'b1;//base ram д����
//                 cpu_din=32'b0;
                cpu_data_to_ext=cpu_dout;
//                cpu_to_uart=8'b00000000;//��
            end
            else begin
                cpu_ext_ce_o=1'b1;//��ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                cpu_base_we=1'b0;//base ram Ĭ�϶�����
//                 cpu_din=32'b0;
                cpu_data_to_ext=cpu_dout;
//                cpu_to_uart=8'b00000000;//��
            end
        end
        else if(!cpu_ext_we_o&&cpu_ce_o)//�� or �Ӵ���ȡ����
        begin
            cpu_base_we=1'b0;//base ram Ĭ�϶�����
            if(cpu_addr_o==`uart_addr)begin//����
                cpu_din={24'b0,ext_uart_buffer};//8λ��չ��32λ,unsigned extended!!
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                ext_uart_clear = 1'b1;//�������ݣ���ն���־
                
//                cpu_to_uart=8'b00000000;//��
                cpu_data_to_ext=32'b0;
            end
            else if(cpu_addr_o==`uart_state_addr)begin//����״̬λ��ֻ�ɶ�
                cpu_din={30'b0,ext_uart_ready,~ext_uart_busy};//
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                ext_uart_clear = 1'b0;//����ն���־
                
//                cpu_to_uart=8'b00000000;//��
                cpu_data_to_ext=32'b0;
            end
            else if(!cpu_addr_o[22])begin//����baseram
            
//                cpu_din=get_basedata;
                cpu_din=data_buffer_for_baseram;
                                
                cpu_ext_ce_o=1'b0;//�ر�ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                ext_uart_clear = 1'b0;//����ն���־
                
//                cpu_to_uart=8'b00000000;//��
                cpu_data_to_ext=32'b0;
            end
            else begin
//                cpu_din=cpu_data_from_ext;
                cpu_din=data_buffer_for_extram;
                
                cpu_ext_ce_o=1'b1;//��ext_ram
                cpu_uart_ce_o=1'b0;//�رմ���
                ext_uart_clear = 1'b0;//����ն���־
                
//                cpu_to_uart=8'b00000000;//��
                cpu_data_to_ext=32'b0;
            end
        end
        else begin//�رմ��ں�ram
            //�����ź�
            cpu_ext_ce_o=1'b0;
            cpu_uart_ce_o=1'b0;
            ext_uart_clear = 1'b0;//����ն���־
            cpu_base_we=1'b0;//base ram Ĭ�϶�����
            
            //data
//            cpu_to_uart<=8'b00000000;//��
//            cpu_din=32'b0;
            cpu_data_to_ext=32'b0;
        end
    end
end
   
assign number = ext_uart_buffer;//�����������ʾͼ��

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

//assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��

always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );
always @(posedge clk_50M) begin //��cpu������data���ͳ�ȥ
//    if(!ext_uart_busy && ext_uart_avai&&cpu_uart_ce_o)begin 
      if(!ext_uart_busy &&cpu_uart_ce_o)begin 
        ext_uart_tx <= cpu_to_uart;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
        led_bits <= 16'h1;
    end
    else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //������
    .vdata(),      //������
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
