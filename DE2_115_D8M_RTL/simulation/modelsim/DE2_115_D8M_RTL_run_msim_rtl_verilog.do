transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src {D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src/i2c_top.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src {D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src/debounce_explicit.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src {D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src/camera_interface.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src {D:/intelFPGA_lite/18.1/codigo/FPGA_OV7670_Camera_Interface-main/src/asyn_fifo.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/pll_test.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/RESET_DELAY.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/CLOCKMEM.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/FpsMonitor.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/Sdram_WR_FIFO.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/Sdram_RD_FIFO.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/VIDEO_PLL.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/de2_115_d8m_rtl.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db/pll_test_altpll.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db/video_pll_altpll.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/db/sdram_pll_altpll.v}
vlib sdram_pll
vmap sdram_pll sdram_pll
vlog -vlog01compat -work sdram_pll +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V/sdram_pll.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/VGA_Controller {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/VGA_Controller/VGA_Controller.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/Sdram_Control.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/sdr_data_path.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/control_interface.v}
vlog -vlog01compat -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/DE2_115_D8M_RTL/V_Sdram_Control/command.v}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/contour.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/contour_draw.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/mnist_classifier_top.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/RGB2GRAY.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/mac_array.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/mac.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/line_buffer_group.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/fmap_III.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/fmap_II.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/fmap_I.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/ff_line_buffer_groups.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/controller.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/cnn_sender.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/cnn_receiver.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/cam2cnn.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/bi_mem0.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem7.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem6.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem5.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem4.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem3.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem2.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem1.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_mem0.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem7.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem6.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem5.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem4.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem3.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem2.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem1.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/wt_fc1_mem0.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/top.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/sram.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/segment7.sv}
vlog -sv -work work +incdir+D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA {D:/intelFPGA_lite/18.1/codigo/MNIST_Classification_FPGA-master/Project_FPGA/mod_N_counter.sv}

