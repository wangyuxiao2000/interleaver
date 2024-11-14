/*************************************************************/
//function: 块交织器
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2023.1.15
//Version : V 1.4
/*************************************************************/
`timescale 1 ns / 1 ps

module interleaver (clk,rst_n,s_axis_tdata,s_axis_tvalid,s_axis_tready,m_axis_tdata,m_axis_tvalid,m_axis_tlast,m_axis_tready);
/************************************************工作参数设置************************************************/
parameter deepth=4;                 /*设定输入接口的内置FIFO深度*/ 
parameter mode="Speed_optimized";   /*"Area_optimized"为面积优先模式; "Speed_optimized"为速度优先模式*/
parameter width=1;                  /*单个元素的位宽*/
parameter row=512;                  /*交织器的行数*/
parameter col=32;                   /*交织器的列数*/
/***********************************************************************************************************/
input clk;                       /*系统时钟*/
input rst_n;                     /*低电平异步复位信号*/

input [width-1:0] s_axis_tdata;  /*输入数据*/
input s_axis_tvalid;             /*输入数据有效标志,高电平有效*/
output s_axis_tready;            /*向上游模块发送读请求或读确认信号,高电平有效*/

output [width-1:0] m_axis_tdata; /*输出数据*/
output m_axis_tvalid;            /*输出数据有效标志,高电平有效*/
output m_axis_tlast;             /*交织块输出结束标志,高电平有效*/
input m_axis_tready;             /*下游模块传来的读请求或读确认信号,高电平有效*/



/***********************************************************************************************************/
generate
  if(mode=="Speed_optimized")/*速度优先模式*/
    begin
      wire [width-1:0] fifo_out_axis_tdata;
      wire fifo_out_axis_tvalid;
      wire fifo_out_axis_tready;

      wire [width-1:0] A_s_axis_tdata;
      wire A_s_axis_tvalid;
      wire A_s_axis_tready;
      wire [width-1:0] B_s_axis_tdata;
      wire B_s_axis_tvalid;
      wire B_s_axis_tready;

      wire [width-1:0] A_m_axis_tdata;
      wire A_m_axis_tvalid;
      wire A_m_axis_tlast;
      wire A_m_axis_tready;
      wire [width-1:0] B_m_axis_tdata;
      wire B_m_axis_tvalid;
      wire B_m_axis_tlast;
      wire B_m_axis_tready;

      reg in_sel;
      reg out_sel;

      data_fifo #(.width(width),
                  .deepth(deepth)
                 ) U1 (.clk(clk),
                       .rst_n(rst_n),
                       .s_axis_tdata(s_axis_tdata),
                       .s_axis_tvalid(s_axis_tvalid),
                       .s_axis_tready(s_axis_tready),
                       .m_axis_tdata(fifo_out_axis_tdata),
                       .m_axis_tvalid(fifo_out_axis_tvalid),
                       .m_axis_tready(fifo_out_axis_tready)
                      );
      demux1_2 #(.width(width),
                 .mode(1)
                ) U2 (.clk(clk),
                      .rst_n(rst_n),
                      .sel(in_sel),
                      .s_axis_tdata(fifo_out_axis_tdata),
                      .s_axis_tvalid(fifo_out_axis_tvalid),
                      .s_axis_tlast(1'b0),
                      .s_axis_tready(fifo_out_axis_tready),
                      .m0_axis_tdata(A_s_axis_tdata),
                      .m0_axis_tvalid(A_s_axis_tvalid),
                      .m0_axis_tlast(),
                      .m0_axis_tready(A_s_axis_tready),
                      .m1_axis_tdata(B_s_axis_tdata),
                      .m1_axis_tvalid(B_s_axis_tvalid),
                      .m1_axis_tlast(),
                      .m1_axis_tready(B_s_axis_tready)
                      );
      interleaver_sub #(.width(width),
                        .row(row),
                        .col(col)
                       ) U3 (.clk(clk),
                             .rst_n(rst_n),
                             .s_axis_tdata(A_s_axis_tdata),
                             .s_axis_tvalid(A_s_axis_tvalid),
                             .s_axis_tready(A_s_axis_tready),
                             .m_axis_tdata(A_m_axis_tdata),
                             .m_axis_tvalid(A_m_axis_tvalid),
                             .m_axis_tlast(A_m_axis_tlast),
                             .m_axis_tready(A_m_axis_tready)
                            );	
      interleaver_sub #(.width(width),
                        .row(row),
                        .col(col)
                       ) U4 (.clk(clk),
                             .rst_n(rst_n),
                             .s_axis_tdata(B_s_axis_tdata),
                             .s_axis_tvalid(B_s_axis_tvalid),
                             .s_axis_tready(B_s_axis_tready),
                             .m_axis_tdata(B_m_axis_tdata),
                             .m_axis_tvalid(B_m_axis_tvalid),
                             .m_axis_tlast(B_m_axis_tlast),
                             .m_axis_tready(B_m_axis_tready)
                            );
      mux2_1 #(.width(width),
               .mode(1)
              ) U5 (.clk(clk),
                    .rst_n(rst_n),
                    .sel(out_sel),
                    .s0_axis_tdata(A_m_axis_tdata),
                    .s0_axis_tvalid(A_m_axis_tvalid),
                    .s0_axis_tlast(A_m_axis_tlast),
                    .s0_axis_tready(A_m_axis_tready),
                    .s1_axis_tdata(B_m_axis_tdata),
                    .s1_axis_tvalid(B_m_axis_tvalid),
                    .s1_axis_tlast(B_m_axis_tlast),
                    .s1_axis_tready(B_m_axis_tready),
                    .m_axis_tdata(m_axis_tdata),
                    .m_axis_tvalid(m_axis_tvalid),
                    .m_axis_tlast(m_axis_tlast),
                    .m_axis_tready(m_axis_tready)
                    );
      
      reg out_tvalid_reg;
      always@(posedge clk or negedge rst_n)
      begin
        if(!rst_n)
          begin
            in_sel<=0;
            out_tvalid_reg<=0;
          end
        else
          begin
            case(in_sel)
              0 : begin/*外部数据输入至功能单元A进行交织*/
                    if(out_tvalid_reg==0&&A_m_axis_tvalid)
                      begin
                        in_sel<=1;
                        out_tvalid_reg<=B_m_axis_tvalid;
                      end
                    else
                      begin
                        in_sel<=in_sel;
                        out_tvalid_reg<=A_m_axis_tvalid;
                      end
                  end
              1 : begin/*外部数据输入至功能单元B进行交织*/
                    if(out_tvalid_reg==0&&B_m_axis_tvalid)
                      begin
                        in_sel<=0;
                        out_tvalid_reg<=A_m_axis_tvalid;
                      end
                    else
                      begin
                        in_sel<=in_sel;
                        out_tvalid_reg<=B_m_axis_tvalid;
                      end
                  end
            endcase
          end
      end

      reg out_tlast_reg;
      always@(posedge clk or negedge rst_n)
      begin
        if(!rst_n)
          begin
            out_sel<=0;
            out_tlast_reg<=0;
          end
        else
          begin
            case(out_sel)
              0 : begin
                    if(out_tlast_reg==1&&A_m_axis_tlast==0)
                      begin
                        out_sel<=1;
                        out_tlast_reg<=B_m_axis_tlast;
                      end
                    else
                      begin
                        out_sel<=out_sel;
                        out_tlast_reg<=A_m_axis_tlast;
                      end
                  end
              1 : begin
                    if(out_tlast_reg==1&&B_m_axis_tlast==0)
                      begin
                        out_sel<=0;
                        out_tlast_reg<=A_m_axis_tlast;
                      end
                    else
                      begin
                        out_sel<=out_sel;
                        out_tlast_reg<=B_m_axis_tlast;
                      end
                  end
            endcase
          end
      end 
    end
  else/*面积优先模式*/
    begin
      wire [width-1:0] fifo_out_axis_tdata;
      wire fifo_out_axis_tvalid;
      wire fifo_out_axis_tready;
      data_fifo #(.width(width),
                  .deepth(deepth)
                 ) U1 (.clk(clk),
                       .rst_n(rst_n),
                       .s_axis_tdata(s_axis_tdata),
                       .s_axis_tvalid(s_axis_tvalid),
                       .s_axis_tready(s_axis_tready),
                       .m_axis_tdata(fifo_out_axis_tdata),
                       .m_axis_tvalid(fifo_out_axis_tvalid),
                       .m_axis_tready(fifo_out_axis_tready)
                      );
      interleaver_sub #(.width(width),
                        .row(row),
                        .col(col)
                       ) U2 (.clk(clk),
                             .rst_n(rst_n),
                             .s_axis_tdata(fifo_out_axis_tdata),
                             .s_axis_tvalid(fifo_out_axis_tvalid),
                             .s_axis_tready(fifo_out_axis_tready),
                             .m_axis_tdata(m_axis_tdata),
                             .m_axis_tvalid(m_axis_tvalid),
                             .m_axis_tlast(m_axis_tlast),
                             .m_axis_tready(m_axis_tready)
                            );	
    end
endgenerate

endmodule