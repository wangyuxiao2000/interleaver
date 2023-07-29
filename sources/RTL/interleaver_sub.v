/*************************************************************/
//function: 块交织器功能单元(行进列出)
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2023.5.5
//Version : V 1.1
/*************************************************************/
`timescale 1 ns / 1 ps

module interleaver_sub (clk,rst_n,s_axis_tdata,s_axis_tvalid,s_axis_tready,m_axis_tdata,m_axis_tvalid,m_axis_tlast,m_axis_tready);
/************************************************工作参数设置************************************************/
parameter row=512;    /*交织器的行数*/
parameter col=32;     /*交织器的列数*/
/***********************************************************************************************************/
input clk;                 /*系统时钟*/
input rst_n;               /*低电平异步复位信号*/

input s_axis_tdata;        /*输入数据*/
input s_axis_tvalid;       /*输入数据有效标志,高电平有效*/
output reg s_axis_tready;  /*向上游模块发送读请求或读确认信号,高电平有效*/

output reg m_axis_tdata;   /*输出数据*/
output reg m_axis_tvalid;  /*输出数据有效标志,高电平有效*/
output reg m_axis_tlast;   /*交织块输出结束标志,高电平有效*/
input m_axis_tready;       /*下游模块传来的读请求或读确认信号,高电平有效*/



/**************************************************进行交织**************************************************/
localparam block_once_need=row*col;  /*写满一次交织块或读空一次交织块需要进行的数据传输次数*/  

localparam STATE_data_in=1'b0;    /*向交织块按行输入数据*/
localparam STATE_data_out=1'b1;   /*从交织块按列读取数据*/

reg state;                                  /*状态机*/
reg [$clog2(block_once_need):0] in_out_cnt; /*输入/输出计数器*/
reg [0:0] block [row*col-1:0];              /*交织块存储器*/
wire [0:0] block_tr [col*row-1:0];          /*block的转置*/

genvar j,i;
generate
  for(j=0;j<=row-1;j=j+1)
    begin
      for(i=0;i<=col-1;i=i+1)
        begin
          assign block_tr[row*col-1-(i*row+j)]=block[row*col-1-(j*col+i)];/*求解block的转置矩阵*/
        end
    end
endgenerate

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      in_out_cnt<=0;
      s_axis_tready<=0;
      m_axis_tdata<=0;
      m_axis_tvalid<=0;
      m_axis_tlast<=0;
      state<=STATE_data_in;
    end
  else
    begin
      case(state)
        STATE_data_in : begin
                          block[row*col-1-in_out_cnt]<=s_axis_tdata;
                          m_axis_tdata<=0;
                          m_axis_tvalid<=0;
                          m_axis_tlast<=0;
                          if(s_axis_tready&&s_axis_tvalid)
                            begin
                              if(in_out_cnt==block_once_need-1)
                                begin
                                  in_out_cnt<=0;
                                  s_axis_tready<=0;
                                  state<=STATE_data_out;
                                end
                              else
                                begin
                                  in_out_cnt<=in_out_cnt+1;
                                  s_axis_tready<=1;
                                  state<=state;
                                end
                            end
                          else
                            begin
                              in_out_cnt<=in_out_cnt;
                              s_axis_tready<=1;
                              state<=state;
                            end
                        end
        STATE_data_out : begin
                           if(!m_axis_tvalid)
                             begin
                               in_out_cnt<=0;
                               s_axis_tready<=0;
                               m_axis_tdata<=block_tr[row*col-1];
                               m_axis_tvalid<=1;
                               m_axis_tlast<=0;
                               state<=state;
                             end
                           else if(m_axis_tready&&m_axis_tvalid)
                             begin
                               if(in_out_cnt==block_once_need-1)
                                 begin
                                   in_out_cnt<=0;
                                   s_axis_tready<=1;
                                   m_axis_tdata<=0;
                                   m_axis_tvalid<=0;
                                   state<=STATE_data_in;
                                 end
                               else if(in_out_cnt==block_once_need-2)
                                 begin
                                   in_out_cnt<=in_out_cnt+1;
                                   s_axis_tready<=0;
                                   m_axis_tdata<=block_tr[row*col-1-(in_out_cnt+1)];/*对block按列读取,相当于对block的转置按行读取*/
                                   m_axis_tvalid<=1;
                                   m_axis_tlast<=1;
                                   state<=state;                                   
                                 end
                               else
                                 begin
                                   in_out_cnt<=in_out_cnt+1;
                                   s_axis_tready<=0;
                                   m_axis_tdata<=block_tr[row*col-1-(in_out_cnt+1)];/*对block按列读取,相当于对block的转置按行读取*/
                                   m_axis_tvalid<=1;
                                   m_axis_tlast<=0;
                                   state<=state;
                                 end                                
                             end
                           else
                             begin
                               in_out_cnt<=in_out_cnt;
                               s_axis_tready<=0;
                               m_axis_tdata<=m_axis_tdata;
                               m_axis_tvalid<=m_axis_tvalid;
                               m_axis_tlast<=m_axis_tlast;
                               state<=state;
                             end
                         end
      endcase
    end
end
/***********************************************************************************************************/

endmodule