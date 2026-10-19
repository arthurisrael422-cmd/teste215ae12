# Exporta os 90208 bytes uteis da RAM de historico pela instancia ISSP "H100".
# Execute no Prompt de Comando do Quartus 18.1:
#   quartus_stp -t exportar_hist32.tcl

package require ::quartus::insystem_source_probe 1.0

set hardwares [get_hardware_names]
if {[llength $hardwares] == 0} {
    error "Nenhum hardware JTAG encontrado. Verifique o USB-Blaster."
}
set hardware [lindex $hardwares 0]
set devices [get_device_names -hardware_name $hardware]
if {[llength $devices] == 0} {
    error "Nenhum FPGA encontrado no hardware $hardware."
}
set device [lindex $devices 0]

set instances [get_insystem_source_probe_instance_info \
    -hardware_name $hardware -device_name $device]
set selected_index -1
foreach item $instances {
    set instance_index [lindex $item 0]
    set source_width   [lindex $item 1]
    set probe_width    [lindex $item 2]
    set instance_name  [lindex $item 3]
    if {$instance_name eq "H100" && $source_width == 18 && $probe_width == 8} {
        set selected_index $instance_index
    }
}
if {$selected_index < 0} {
    puts "Instancias encontradas: $instances"
    error "Instancia H100 nao encontrada. Programe o .sof da revisao HIST100."
}

set output_name "historico.mif"
set output [open $output_name "w"]
puts $output "WIDTH=8;"
puts $output "DEPTH=90208;"
puts $output "ADDRESS_RADIX=HEX;"
puts $output "DATA_RADIX=HEX;"
puts $output "CONTENT BEGIN"

puts "USB-Blaster: $hardware"
puts "FPGA: $device"
puts "Lendo HIST100/H100..."

start_insystem_source_probe -hardware_name $hardware -device_name $device
set failed 0
if {[catch {
    for {set address 0} {$address < 90208} {incr address} {
        set source_value [format "%05X" [expr {0x20000 | $address}]]
        write_source_data -instance_index $selected_index \
            -value $source_value -value_in_hex
        set value [read_probe_data -instance_index $selected_index -value_in_hex]
        set value [string toupper [string trim $value]]
        scan $value "%x" numeric_value
        puts $output [format "%05X : %02X;" $address $numeric_value]
        if {($address % 4096) == 0} {
            puts [format "  %6d / 90208 bytes" $address]
        }
    }
} message]} {
    set failed 1
    puts "ERRO durante a leitura: $message"
}

# Libera imediatamente a porta B para a visualizacao VGA.
write_source_data -instance_index $selected_index -value "00000" -value_in_hex
end_insystem_source_probe
puts $output "END;"
close $output

if {$failed} {
    error "Exportacao interrompida; historico.mif esta incompleto."
}
puts "Concluido: $output_name"
puts "Agora execute: python analisar_historico.py historico.mif"
