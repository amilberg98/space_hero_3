
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_controller is
    port(
        vga_clk     : in  std_logic;  -- Input clock (24.175 MHz expected)
		y   		: out std_logic_vector(9 downto 0);
		x 		: out std_logic_vector(9 downto 0);
		vga_counter : out std_logic_vector(18 downto 0);
        hsync       : out std_logic;  -- Horizontal sync
        vsync       : out std_logic;  -- Vertical sync
        valid       : out std_logic  -- Signal to indicate active display region
    );
end vga_controller;

architecture synth of vga_controller is
	signal y_temp : unsigned(9 downto 0);
	signal x_temp : unsigned(9 downto 0);
   
begin
 
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
			if (x_temp = 10d"799") then
				x_temp <= 10d"0";
				if (y_temp = 10d"524") then
					y_temp <= 10d"0";
					vga_counter <= 19d"0";
				else
					y_temp <= y_temp + 1b"1";
					vga_counter <= std_logic_vector(unsigned(vga_counter) + 19d"1");
				end if;
			else
				vga_counter <= std_logic_vector(unsigned(vga_counter) + 19d"1");
				x_temp <= x_temp + 1b"1";
			end if;
			
		end if;
    end process;
	hsync <= '1' when (x_temp <= 10d"656" or x_temp >= 10d"752") else '0';
	vsync <= '1' when (y_temp <= 10d"490" or y_temp >= 10d"492") else '0';
	valid <= '0' when (x_temp >= 10d"640" or y_temp >= 10d"480") else '1';
	x <= std_logic_vector(x_temp);
	y <= std_logic_vector(y_temp);
end synth;
