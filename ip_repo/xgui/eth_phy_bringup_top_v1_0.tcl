# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"


}

proc update_PARAM_VALUE.BRINGUP_REG_ADDR { PARAM_VALUE.BRINGUP_REG_ADDR } {
	# Procedure called to update BRINGUP_REG_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRINGUP_REG_ADDR { PARAM_VALUE.BRINGUP_REG_ADDR } {
	# Procedure called to validate BRINGUP_REG_ADDR
	return true
}

proc update_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to update CLK_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to validate CLK_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.MDC_FREQ_HZ { PARAM_VALUE.MDC_FREQ_HZ } {
	# Procedure called to update MDC_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MDC_FREQ_HZ { PARAM_VALUE.MDC_FREQ_HZ } {
	# Procedure called to validate MDC_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.PHY_ADDR { PARAM_VALUE.PHY_ADDR } {
	# Procedure called to update PHY_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PHY_ADDR { PARAM_VALUE.PHY_ADDR } {
	# Procedure called to validate PHY_ADDR
	return true
}

proc update_PARAM_VALUE.POLL_CYCLES { PARAM_VALUE.POLL_CYCLES } {
	# Procedure called to update POLL_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POLL_CYCLES { PARAM_VALUE.POLL_CYCLES } {
	# Procedure called to validate POLL_CYCLES
	return true
}

proc update_PARAM_VALUE.RESET_LOW_CYCLES { PARAM_VALUE.RESET_LOW_CYCLES } {
	# Procedure called to update RESET_LOW_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_LOW_CYCLES { PARAM_VALUE.RESET_LOW_CYCLES } {
	# Procedure called to validate RESET_LOW_CYCLES
	return true
}

proc update_PARAM_VALUE.STABLE_WAIT_CYCLES { PARAM_VALUE.STABLE_WAIT_CYCLES } {
	# Procedure called to update STABLE_WAIT_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STABLE_WAIT_CYCLES { PARAM_VALUE.STABLE_WAIT_CYCLES } {
	# Procedure called to validate STABLE_WAIT_CYCLES
	return true
}


proc update_MODELPARAM_VALUE.CLK_FREQ_HZ { MODELPARAM_VALUE.CLK_FREQ_HZ PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ_HZ}] ${MODELPARAM_VALUE.CLK_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.MDC_FREQ_HZ { MODELPARAM_VALUE.MDC_FREQ_HZ PARAM_VALUE.MDC_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MDC_FREQ_HZ}] ${MODELPARAM_VALUE.MDC_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.PHY_ADDR { MODELPARAM_VALUE.PHY_ADDR PARAM_VALUE.PHY_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PHY_ADDR}] ${MODELPARAM_VALUE.PHY_ADDR}
}

proc update_MODELPARAM_VALUE.BRINGUP_REG_ADDR { MODELPARAM_VALUE.BRINGUP_REG_ADDR PARAM_VALUE.BRINGUP_REG_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRINGUP_REG_ADDR}] ${MODELPARAM_VALUE.BRINGUP_REG_ADDR}
}

proc update_MODELPARAM_VALUE.RESET_LOW_CYCLES { MODELPARAM_VALUE.RESET_LOW_CYCLES PARAM_VALUE.RESET_LOW_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_LOW_CYCLES}] ${MODELPARAM_VALUE.RESET_LOW_CYCLES}
}

proc update_MODELPARAM_VALUE.STABLE_WAIT_CYCLES { MODELPARAM_VALUE.STABLE_WAIT_CYCLES PARAM_VALUE.STABLE_WAIT_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STABLE_WAIT_CYCLES}] ${MODELPARAM_VALUE.STABLE_WAIT_CYCLES}
}

proc update_MODELPARAM_VALUE.POLL_CYCLES { MODELPARAM_VALUE.POLL_CYCLES PARAM_VALUE.POLL_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POLL_CYCLES}] ${MODELPARAM_VALUE.POLL_CYCLES}
}

