`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:     Universidad Nacional de Colombia
// Engineer: 	 Ingenieria Electronica
// 
// Create Date:    01:24:41 10/24/2020 
// Design Name: 	 Servo motor
// Module Name:    servo 
// Project Name:     
// Target Devices:  Nexys4
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module servo(
					input clk,
					input  indicador,
					output reg led,
					output reg pwm
		);

reg [20:0] cont;
reg [9:0] cont_div1;
reg clk1;
reg [17:0] Pulsos;

initial
begin
cont = 21'b111111111111111111111;
cont_div1 = 10'b11111111111;
Pulsos = 18'd50_000;
clk1 = 1'b1;
pwm = 1'b1;
led = 1'b0;
end

/////////////////////////// Divisor de frecuencia /////////////////////////////////
always @(posedge clk)
begin	  
	if (cont_div1<1023) 
		cont_div1 = cont_div1 + 10'b01;
	else	begin
		clk1=~clk1;	
		cont_div1 = 0; end	   
end


always  @(posedge clk1)
begin
	if(indicador == 1'b1 && Pulsos<240_000)
		begin
			led =1'b1;
			Pulsos = Pulsos + 18'b01;
		end
	else if(indicador == 1'b0 && Pulsos>50_000)
		begin  
			led = 1'b0;
			Pulsos = Pulsos - 18'b01; 
		end
	else 
			Pulsos = Pulsos;
end

///////////////////////////  Señal de PWM /////////////////////////////////
/////////     Entre 0.5 [ms] y 2.4 [ms]                 ///////////////////
/////////     para 0° y 180° Respectivamente            ///////////////////
/////////     <---->                                    ///////////////////
/////////      ____                            ____     ///////////////////
/////////     |    |									 |    |	  ///////////////////
///////// ____|    |__________________________|    |__  ///////////////////
/////////     <------------------------------->         ///////////////////
/////////                T = 20 [ms]                    ///////////////////


always @(posedge clk)
begin
cont = cont + 20'b1;

if (cont < Pulsos)  				// señal pwm con ciclo positivo de 1 ms
		pwm = 1'b1;
else
	begin
		pwm = 1'b0;
		if(cont == 2_000_000)
			cont = 20'b0;				
	end
end


endmodule

