/*************************************************************/
//function: AXIS接口的2选1数据选择器
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2023.5.5
//Version : V 1.0
/*************************************************************/
`timescale 1 ns / 1 ps

module mux2_1 (clk,rst_n,sel,s0_axis_tdata,s0_axis_tvalid,s0_axis_tlast,s0_axis_tready,s1_axis_tdata,s1_axis_tvalid,s1_axis_tlast,s1_axis_tready,m_axis_tdata,m_axis_tvalid,m_axis_tlast,m_axis_tready);
/************************************************工作参数设置************************************************/
parameter width=1;   /*定义输入及输出接口的宽度*/
parameter mode=1;    /*mode=1时,为组合逻辑模式,sel信号发生变化后,立即切换数据通道; mode=0时,为时序逻辑模式,sel信号在时钟上升沿同步有效*/
/***********************************************************************************************************/
input clk;                         /*系统时钟*/
input rst_n;                       /*低电平异步复位信号*/
input sel;                         /*数据选择信号;当sel=0时,选择s0接口的数据作为输出;当sel=1时,选择s1接口的数据作为输出*/

input [width-1:0] s0_axis_tdata;   /*输入口输入数据*/
input s0_axis_tvalid;              /*输入数据有效标志,高电平有效*/
input s0_axis_tlast;               /*上游模块传来的帧结束标志位*/
output s0_axis_tready;             /*向上游模块发送读请求或读确认信号,高电平有效*/
input [width-1:0] s1_axis_tdata;   /*输入数据*/
input s1_axis_tvalid;              /*输入数据有效标志,高电平有效*/
input s1_axis_tlast;               /*上游模块传来的帧结束标志位*/
output s1_axis_tready;             /*向上游模块发送读请求或读确认信号,高电平有效*/

output [width-1:0] m_axis_tdata;   /*输出数据*/
output m_axis_tvalid;              /*输出数据有效标志,高电平有效*/
output m_axis_tlast;               /*帧结束标志,高电平有效*/
input m_axis_tready;               /*下游模块传来的读请求或读确认信号,高电平有效*/



/**************************************************选择数据**************************************************/
generate
  if(mode)/*组合逻辑模式*/
    begin
      assign s0_axis_tready=rst_n?(sel?0:m_axis_tready):0;
      assign s1_axis_tready=rst_n?(sel?m_axis_tready:0):0;
      assign m_axis_tdata=rst_n?(sel?s1_axis_tdata:s0_axis_tdata):0;
      assign m_axis_tvalid=rst_n?(sel?s1_axis_tvalid:s0_axis_tvalid):0;
      assign m_axis_tlast=rst_n?(sel?s1_axis_tlast:s0_axis_tlast):0;
    end
  else/*时序逻辑模式*/
    begin
      reg s0_axis_tready_reg;
      reg s1_axis_tready_reg;
      reg [width-1:0] m_axis_tdata_reg;
      reg m_axis_tvalid_reg;
      reg m_axis_tlast_reg;
      always@(posedge clk or negedge rst_n)
      begin
        if(!rst_n)
          begin
            s0_axis_tready_reg<=0;
            s1_axis_tready_reg<=0;
            m_axis_tdata_reg<=0;
            m_axis_tvalid_reg<=0;
            m_axis_tlast_reg<=0;
          end
        else
          begin
            if(sel)/*选择s1接口的数据作为输出*/
              begin
                s0_axis_tready_reg<=0;
                s1_axis_tready_reg<=m_axis_tready;
                m_axis_tdata_reg<=s1_axis_tdata;
                m_axis_tvalid_reg<=s1_axis_tvalid;
                m_axis_tlast_reg<=s1_axis_tlast;
              end
            else/*选择s0接口的数据作为输出*/
              begin
                s0_axis_tready_reg<=m_axis_tready;
                s1_axis_tready_reg<=0;
                m_axis_tdata_reg<=s0_axis_tdata;
                m_axis_tvalid_reg<=s0_axis_tvalid;
                m_axis_tlast_reg<=s0_axis_tlast;
              end
          end
      end
      assign s0_axis_tready=s0_axis_tready_reg;
      assign s1_axis_tready=s1_axis_tready_reg;
      assign m_axis_tdata=m_axis_tdata_reg;
      assign m_axis_tvalid=m_axis_tvalid_reg;
      assign m_axis_tlast=m_axis_tlast_reg;
    end
endgenerate
/***********************************************************************************************************/
endmodule