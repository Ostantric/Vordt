# FPGA 
## Bugs to fix
* I2C_Slave module can't read 8th bit. Fix timing and listen_buffer
 
* Decoder outputs huge random when you reach 0 as velocity setpoint. its because two's comp translation error. Fix the average_velocity block in decoder.vhd

* PID_Velocity can't do reverse. ---Fix decoder.vhd first---
