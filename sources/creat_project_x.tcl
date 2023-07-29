#设置工程名(将[]替换为工程名)
set project_name interleaver
#设置芯片型号(将[]替换为芯片型号)
set chip_type xc7a200tfbg484-1
#是否将当前设计导出为自定义IP核(ip_out_p=1进行)
set ip_out_p 1
#是否进行布局布线、生成比特流的操作(bitstream_p=1进行)
set bitstream_p 0
#是否在所有操作结束后关闭工程(close_p=1关闭)
set close_p 0

#规定线程数(提升线程数可以使运行更快)
set_param general.maxThreads 12
#新建outputs文件夹,存储 RTL视图、比特流文件、综合报告等输出
file delete -force ./outputs
file mkdir ./outputs
#创建工程
create_project -part $chip_type -force $project_name    
#添加RTL设计文件至sources_1文件集
add_files -fileset sources_1 -norecurse -scan_for_includes ../sources/RTL
#添加测试文件至sim_1文件集
add_files -fileset sim_1 -norecurse -scan_for_includes ../sources/TB
#添加约束文件至constrs_1文件集
if {$bitstream_p=="1"} {
add_files -fileset constrs_1 ../sources/CONSTRS
}
#更新编译顺序(形成模块间的层次关系,找到顶层模块)
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
#生成RTL视图并导出为PDF
synth_design -rtl -rtl_skip_mlo -name rtl_1
write_schematic -format pdf -orientation portrait ./schematic.pdf
file copy -force ./schematic.pdf ./outputs/schematic.pdf
file delete -force ./schematic.pdf
#进行综合
launch_runs synth_1 -jobs 12
wait_on_run synth_1

#将当前设计导出为IP
if {$ip_out_p=="1"} { 
file delete -force ../../../my_ip/$project_name
file mkdir ../../../my_ip/$project_name
ipx::package_project -root_dir ../../../my_ip/$project_name -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core ../../../my_ip/$project_name/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory ../../../my_ip/$project_name ../../../my_ip/$project_name/component.xml

set_property name $project_name [ipx::current_core]
set_property version 1.0 [ipx::current_core]
set_property display_name $project_name [ipx::current_core]

set_property description {wyxee2000@163.com} [ipx::current_core]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "deepth" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "mode" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "row" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 3 [ipgui::get_guiparamspec -name "col" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "deepth" -component [ipx::current_core] ]
set_property tooltip {FIFO depth of input interface (must be 2^n).} [ipgui::get_guiparamspec -name "deepth" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "mode" -component [ipx::current_core] ]
set_property tooltip {0:Area optimized; 1:Speed optimized.} [ipgui::get_guiparamspec -name "mode" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "row" -component [ipx::current_core] ]
set_property tooltip {Number of rows in block interleaver.} [ipgui::get_guiparamspec -name "row" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "col" -component [ipx::current_core] ]
set_property tooltip {Number of cols in block interleaver.} [ipgui::get_guiparamspec -name "col" -component [ipx::current_core] ]

ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete
}

#布局布线、生成比特流(若不使用wait_on_run命令,布局布线还没执行完就会执行生成比特流的命令,从而导致错误)
if {$bitstream_p=="1"} { 
launch_runs impl_1 -jobs 12
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1
file copy -force ./$project_name.runs/impl_1/$project_name.bit ./outputs/$project_name.bit
file delete -force ./$project_name.runs/impl_1/$project_name.bit
}

#结束后关闭工程
if {$close_p=="1"} { 
close_project
stop_gui
exit
}  