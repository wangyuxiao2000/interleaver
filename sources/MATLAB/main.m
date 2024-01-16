% 初始化
clear; 
close all;
clc;

% 设定参数
width = 1;                 % 设定交织元素的比特位宽
row = 512;                 % 设定块交织器行数
col = 32;                  % 设定块交织器列数
block_number = 5;          % 设定仿真交织块数

% 配置m序列作为仿真数据源
block_size = row*col;
ploy = [1 0 0 0 0 0 0 1 0 0 1];
seed = [1 0 0 0 0 0 0 0 0 0];
data = m_sequence(seed, ploy, block_size*width*block_number);
data = reshape(data(1:end-mod(length(data), width)), width, []);
data = bi2de(data.')';

% 进行交织
result = zeros(1,block_size*block_number);
for i = 1:block_number
    result(block_size*(i-1)+1 : block_size*i) = matintrlv(data(block_size*(i-1)+1 : block_size*i), row, col);
end

% 将测试用例导出,作为RTL代码测试向量
fid_stimulus = fopen("../TB/stimulus.txt",'w');
fprintf(fid_stimulus,'%d\r\n', data);
fclose(fid_stimulus);
fid_response = fopen("../TB/response.txt",'w');
fprintf(fid_response,'%d\r\n', result);
fclose(fid_response);