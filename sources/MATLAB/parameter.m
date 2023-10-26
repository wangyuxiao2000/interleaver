%初始化
clear; 
close all;
clc;

%设定参数
row=512;                      %设定块交织器行数
col=32;                       %设定块交织器列数

ploy=[1 0 0 0 0 0 0 1 0 0 1]; %设定生成多项式系数
seed=[1 0 0 0 0 0 0 0 0 0];   %设定种子值
data_rate=1000;               %设定数据速率
frame_length=row*col;         %设定原始数据的帧长
frame_number=2;               %设定仿真帧长数

%配置m序列作为仿真数据源
ploy_PN=fliplr(ploy); 
m_length=2^(length(seed))-1;
total_point=frame_length*(frame_number+1); %simulink中使用了buffer,最初会输出一个全零帧;
total_time=(total_point-1)*(1/data_rate);

%执行simulink仿真并输出数据
simulink_out=sim("interleaver",total_time);
fid_stimulus=fopen("../TB/stimulus.txt",'w');
fprintf(fid_stimulus,'%d\r\n',simulink_out.stimulus((frame_length+1):total_point));%simulink中使用了buffer,最初会输出一个全零帧,从第二帧开始才是有效数据;
fclose(fid_stimulus);
fid_response=fopen("../TB/response.txt",'w');
fprintf(fid_response,'%d\r\n',simulink_out.response((frame_length+1):total_point));
fclose(fid_response);