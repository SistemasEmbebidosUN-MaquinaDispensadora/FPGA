`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:58:40 12/03/2020 
// Design Name: 
// Module Name:    FPGA 
// Project Name: 
// Target Devices: 
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
module FPGA(
						input clk, //100MHz
						input reset, //reset
						input rx,					 //entrada de datos del modulo bluetooth
						output reg motor,
					   output reg bomba,
				    	output reg valvula,
						output reg[7:0] led		//Leds
						); 
						
/////////// INICIALIZA LOS DATOS PARA EL CONTROL DE LOS ACTUADORES		
			
initial
begin
led = 8'b00000000;
motor = 1'b0;
bomba = 1'b0;
valvula = 1'b0;
end
reg [26:0] cl = 27'b0;						
reg [8:0] Orden = 9'b000000000;
				

//fsm maquina de estados finitos
reg [1:0] Estadopresente, Estadosiguiente;
parameter Estado_1 = 3'b00;
parameter Estado_0 = 3'b01;

//señales
reg control=0; //indica cuando ocurre el bit de start
reg done=0; // bandera que indica que termino de recibir los datos
reg[8:0]tmp=9'b000000000; //registro que recibe los datos enviados

//contadores para los retardos
reg [3:0]i = 4'b0000; //contador de los bits recibidos
reg [10:0]c = 11'b11111111111; //contador de retardos
reg delay = 0; //algoritmo para los retardos
reg [1:0] c2 = 2'b11;
reg capture = 0;

//proceso de retardo al triple de la frecuencia con la que envia los datos el Bluetooth
//1736*10ns = 17.36us
//17.36us*3 = 58.08us
//58.08us*2 = 104.16us =1/9600baudios o bits/seg
always@(posedge clk)
begin
	if(c < 1734)
		c=c+1;
	else
		begin
			c=0;
			delay=~delay;
		end
end

//proceso para el contador C2 para la captura del dato en la mitad de tiempo de cada bits
always@(posedge delay)
begin
	if (c2>1)
		c2=0;
	else
		c2=c2+1;
	end
	
//proceso para capturar en el bit de en medio (capture)
always@(c2)
begin
	if (c2==1)
		capture=1;
	else
		capture=0;
end


//FSM actualiza la maquina de estados finitos 
always@(posedge capture, posedge reset)
	if (reset) 
		Estadopresente <= Estado_1 ; // deja todo en 0
	else 
		Estadopresente <= Estadosiguiente;
	
//FSM  maquina de estados finitos.
always@(*)
begin
case(Estadopresente)
		Estado_1 :
		if(rx==1 && done==0)
			begin
				control=0;
				Estadosiguiente= Estado_1 ;
			end
		else if(rx==0 && done==0)
			begin
				control=1;
				Estadosiguiente= Estado_0;
			end
		else
			begin
				control=0;
				Estadosiguiente= Estado_1 ;
			end
		Estado_0:
		begin
			if(done==0)
				begin
					control=1;
					Estadosiguiente= Estado_0;
				end
			else
				begin
					control=0;
					Estadosiguiente= Estado_1 ;
				end
		end
		default
			Estadosiguiente= Estado_1 ;
endcase
end


//proceso de recepción de datos
always@(posedge capture)
begin
	if (control==1 && done==0)
	begin
		tmp <= {rx,tmp[8:1]};
	end
end


//proceso que cuenta los bits que llegan (9 bits)
always@(posedge capture)
begin
	if (control)
		begin
			if(i>=9)
				begin
					i=0;
					done=1;
					led<=tmp[8:1];
					Orden<=tmp[8:1];
				end
			else
				begin
					i=i+1;
					done=0;
				end
			end
	else
		done=0;
end



/////////////////////////// ENVIA ORDENES A LOS ACTUADORES/////////////////////////////////
always @(posedge clk)
begin	  
	if (Orden == 8'b00000010) 
		begin
			motor = 1'b1;
		end
	else if(Orden == 8'b00000001)
		begin
			bomba = 1'b1;
			if(cl<300_000_000)
				cl = cl + 27'b01;
			else	
			begin
				valvula = 1'b1;
				cl = 27'b0;
			end
		end
	else 
		begin
			motor = 1'b0;
			bomba = 1'b0;
			valvula = 1'b0;
		end		
end
endmodule
