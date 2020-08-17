`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效  chipenable
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );
reg reset_of_clk10M,reset_of_clk50M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
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
    .we_i(cpu_base_we),//写请求   高有效   接cpu的we
//    .we_i(1'b0),//写请求   高有效   接cpu的we
    .ce_i(cpu_base_ce_o),
    .read_ready(base_read_ready),//读完成：已从ram获取到data时拉高
    .iodata_en(base_iodata_en),//三态门控制信号
    .ce_n(base_ram_ce_n),//ce  chipenabled
    .oe_n(base_ram_oe_n),//读使能
    .we_n(base_ram_we_n)//we写使能
    );
    assign base_ram_be_n = (!cpu_addr_o[22]&&cpu_ce_o)?~cpu_ext_sel_o:4'b0;
    assign base_ram_data = base_iodata_en ? cpu_data_to_ext:32'hzzzz;//cpu_data_to_ext,将数据写入base ram
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
    .we_i(cpu_ext_we_o),//写请求   高有效   接cpu的we
    .ce_i(cpu_ext_ce_o),
    .read_ready(ext_read_ready),//读完成：已从ram获取到data时拉高
    .iodata_en(ext_iodata_en),//三态门控制信号
    .ce_n(ext_ram_ce_n),//ce  chipenabled
    .oe_n(ext_ram_oe_n),//读使能
    .we_n(ext_ram_we_n)//we写使能
    );
    assign ext_ram_be_n = ~cpu_ext_sel_o;
    assign ext_ram_data = ext_iodata_en ? cpu_data_to_ext:32'hzzzz;//写ram
    
     assign ext_ram_addr = cpu_addr_o[21:2];
    wire [19:0]forsim_ram_addr;
    assign forsim_ram_addr = cpu_addr_o[19:0];//看ram访存地址

(*mark_debug = "TRUE"*)reg [31:0]data_buffer_for_extram;
always@(*) begin
    if(reset_of_clk10M)begin
        data_buffer_for_extram<=32'b0;//data缓冲区
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

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
(*mark_debug = "TRUE"*)reg  [7:0] ext_uart_buffer, ext_uart_tx;
(*mark_debug = "TRUE"*)wire ext_uart_ready;
(*mark_debug = "TRUE"*)wire ext_uart_busy;
(*mark_debug = "TRUE"*)reg ext_uart_start, ext_uart_avai;
reg ext_uart_clear=1'b1;//初始化，使rxd_ready=0

//串口控制器
`define uart_addr 32'hbfd003f8
`define uart_state_addr 32'hbfd003fc

reg [7:0] cpu_to_uart;
(*mark_debug = "TRUE"*)reg cpu_uart_ce_o;
//串口、baseram、extram仲裁
always@(*) begin
    cpu_din=32'b0;
    cpu_to_uart=8'b00000000;
    if(reset_of_clk10M)begin//默认关闭串口和ram
            cpu_ext_ce_o=1'b0;
            cpu_uart_ce_o=1'b0;
            cpu_base_we=1'b0;//base ram 默认读请求
            ext_uart_clear = 1'b1;
//             cpu_din=32'b0;
//            cpu_to_uart=8'b00000000;
            cpu_data_to_ext=32'b0;
        end
    else begin
        if(cpu_ext_we_o&&cpu_ce_o)//写ram or 向串口发数据
        begin
            ext_uart_clear = 1'b0;//不清空读标志
            if(cpu_addr_o==`uart_addr)begin//串口
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b1;//打开串口
                cpu_base_we=1'b0;//base ram 默认读请求
//                 cpu_din=32'b0;
                cpu_to_uart=cpu_dout[7:0];//低8位
                cpu_data_to_ext=32'b0;
            end
            else if(cpu_addr_o==`uart_state_addr)begin//串口状态位，只可读，不可写
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                cpu_base_we=1'b0;//base ram 默认读请求
//                 cpu_din=32'b0;
//                cpu_to_uart=8'b00000000;//空
                cpu_data_to_ext=32'b0;
            end
            else if(!cpu_addr_o[22])begin//访问baseram
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                cpu_base_we=1'b1;//base ram 写请求
//                 cpu_din=32'b0;
                cpu_data_to_ext=cpu_dout;
//                cpu_to_uart=8'b00000000;//空
            end
            else begin
                cpu_ext_ce_o=1'b1;//打开ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                cpu_base_we=1'b0;//base ram 默认读请求
//                 cpu_din=32'b0;
                cpu_data_to_ext=cpu_dout;
//                cpu_to_uart=8'b00000000;//空
            end
        end
        else if(!cpu_ext_we_o&&cpu_ce_o)//读 or 从串口取数据
        begin
            cpu_base_we=1'b0;//base ram 默认读请求
            if(cpu_addr_o==`uart_addr)begin//串口
                cpu_din={24'b0,ext_uart_buffer};//8位扩展至32位,unsigned extended!!
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                ext_uart_clear = 1'b1;//读到数据，清空读标志
                
//                cpu_to_uart=8'b00000000;//空
                cpu_data_to_ext=32'b0;
            end
            else if(cpu_addr_o==`uart_state_addr)begin//串口状态位，只可读
                cpu_din={30'b0,ext_uart_ready,~ext_uart_busy};//
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                ext_uart_clear = 1'b0;//不清空读标志
                
//                cpu_to_uart=8'b00000000;//空
                cpu_data_to_ext=32'b0;
            end
            else if(!cpu_addr_o[22])begin//访问baseram
            
//                cpu_din=get_basedata;
                cpu_din=data_buffer_for_baseram;
                                
                cpu_ext_ce_o=1'b0;//关闭ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                ext_uart_clear = 1'b0;//不清空读标志
                
//                cpu_to_uart=8'b00000000;//空
                cpu_data_to_ext=32'b0;
            end
            else begin
//                cpu_din=cpu_data_from_ext;
                cpu_din=data_buffer_for_extram;
                
                cpu_ext_ce_o=1'b1;//打开ext_ram
                cpu_uart_ce_o=1'b0;//关闭串口
                ext_uart_clear = 1'b0;//不清空读标志
                
//                cpu_to_uart=8'b00000000;//空
                cpu_data_to_ext=32'b0;
            end
        end
        else begin//关闭串口和ram
            //控制信号
            cpu_ext_ce_o=1'b0;
            cpu_uart_ce_o=1'b0;
            ext_uart_clear = 1'b0;//不清空读标志
            cpu_base_we=1'b0;//base ram 默认读请求
            
            //data
//            cpu_to_uart<=8'b00000000;//空
//            cpu_din=32'b0;
            cpu_data_to_ext=32'b0;
        end
    end
end
   
assign number = ext_uart_buffer;//用于数码管显示图形

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_50M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

//assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中

always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_50M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );
always @(posedge clk_50M) begin //将cpu送来的data发送出去
//    if(!ext_uart_busy && ext_uart_avai&&cpu_uart_ce_o)begin 
      if(!ext_uart_busy &&cpu_uart_ce_o)begin 
        ext_uart_tx <= cpu_to_uart;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED为初始值
        led_bits <= 16'h1;
    end
    else begin //每次按下时钟按钮，LED循环左移
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
