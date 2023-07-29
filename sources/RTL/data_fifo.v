/*************************************************************/
//function: 32*1bit同步FIFO模块
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2023.3.15
//Version : V 1.0
/*************************************************************/
`timescale 1 ns / 1 ps

module data_fifo (clk,rst_n,s_axis_tdata,s_axis_tvalid,s_axis_tready,m_axis_tdata,m_axis_tvalid,m_axis_tready);
/************************工作参数设置************************/
parameter width=1;                /*定义FIFO宽度*/
parameter deepth=32;              /*定义FIFO深度(2的n次方)*/
/************************************************************/
input clk;                        /*系统时钟*/
input rst_n;                      /*低电平异步复位信号*/

input [width-1:0] s_axis_tdata;   /*输入数据*/
input s_axis_tvalid;              /*输入数据有效标志,高电平有效*/
output s_axis_tready;             /*当FIFO未满时,s_axis_tready为高电平,指示前级模块可向FIFO输入数据*/

output [width-1:0] m_axis_tdata;  /*输出数据*/
output reg m_axis_tvalid;         /*输出数据有效标志,高电平有效*/
input m_axis_tready;              /*后级模块传来的读请求或读确认信号,高电平有效*/


reg [width-1:0] fifo_mem [deepth-1:0];


/************************判断FIFO空满************************/
reg [$clog2(deepth)-1:0] wr_addr; /*写指针*/
reg [$clog2(deepth)-1:0] rd_addr; /*读指针*/
reg full;                         /*满标志信号*/
reg empty;                        /*空标志信号*/
wire wr_en;                       /*写使能信号*/
wire rd_en;                       /*读使能信号*/
wire [$clog2(deepth)-1:0] wr_addr_next;
wire [$clog2(deepth)-1:0] rd_addr_next;

assign wr_addr_next=wr_addr+1;
assign rd_addr_next=rd_addr+1;
assign s_axis_tready=!full;                 /*FIFO未满时,允许前级模块向FIFO传输数据*/
assign wr_en=s_axis_tready&&s_axis_tvalid;  /*FIFO未满且前级产生有效输出时,FIFO发生写入行为;系统复位时,前级模块传来的s_axis_tvalid信号必为低电平,此时wr_en=0,不允许进行写入*/
assign rd_en=(!empty)&&m_axis_tready;       /*FIFO非空且后级模块可以接收FIFO的数据输出时,FIFO发生读出行为;系统复位时,FIFO为空,empty=1,此时rd_en=0,不允许进行读出*/

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    full<=1'b0;/*初始情况下FIFO为空*/
  else
    begin
      if(wr_en&&(wr_addr_next==rd_addr))/*发生本次写入后,读写指针重合,代表FIFO满*/
        full<=1'b1;
      else if(full&&rd_en)/*FIFO满状态下进行了读出操作,导致FIFO脱离满状态*/
        full<=1'b0;
      else
        full<=full;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    empty<=1'b1;/*初始情况下FIFO为空*/    
  else
    begin
      if(rd_en&&(rd_addr_next==wr_addr))/*发生本次读取后,读写指针重合,代表FIFO空*/
        empty<=1'b1;
      else if(empty&&wr_en)/*FIFO空状态下进行了写入操作,导致FIFO脱离空状态*/
        empty<=1'b0;
      else
        empty<=empty;
    end
end
/************************************************************/



/***********************向FIFO读写数据***********************/
reg [width-1:0] data_out_reg;

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    wr_addr<=0;
  else
    begin
      if(wr_en)
        wr_addr<=wr_addr+1;
      else
        wr_addr<=wr_addr;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    rd_addr<=0;
  else
    begin
      if(rd_en)
        rd_addr<=rd_addr+1;
      else
        rd_addr<=rd_addr;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    m_axis_tvalid<=1'b0;
  else
    begin
      if(rd_en)
        m_axis_tvalid<=1'b1;
      else
        begin
          if(m_axis_tready)/*m_axis_tready=1而rd_en=0,说明后级模块仍能够继续接收数据,但FIFO已经被读空;当后级模块取走FIFO的最后一次输出后,输出有效标志信号m_axis_tvalid被拉低*/
            m_axis_tvalid<=1'b0;
          else
            m_axis_tvalid<=m_axis_tvalid;
        end
    end
end

always@(posedge clk)
begin
  if(wr_en)
    fifo_mem[wr_addr]<=s_axis_tdata;
  else
    fifo_mem[wr_addr]<=fifo_mem[wr_addr];
end

always@(posedge clk)
begin
  if(rd_en)
    data_out_reg<=fifo_mem[rd_addr];
  else
    data_out_reg<=data_out_reg;
end

assign m_axis_tdata=data_out_reg;/*虽然m_axis_tdata没有受到复位信号的控制,但其输出有效标志信号能够被复位信号清零*/
/************************************************************/

endmodule