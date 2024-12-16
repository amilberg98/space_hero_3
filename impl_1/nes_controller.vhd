

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nes_controller is
port(
	  data : in std_logic;
	  data_output : out std_logic_vector(7 downto 0);
	  latch : out std_logic;
	  clk_controller : out std_logic
  );
end nes_controller;

architecture synth of nes_controller is

	component HSOSC is
	generic (
		CLKHF_DIV : String := "0b00"); -- Divide 48MHz clock by 2?N (0-3)
	port(
		CLKHFPU : in std_logic := 'X'; -- Set to 1 to power up
		CLKHFEN : in std_logic := 'X'; -- Set to 1 to enable output
		CLKHF :  out std_logic := 'X'); -- Clock output
	end component;

	signal counter : unsigned(25 downto 0) := 26b"0";
	signal NESclk : std_logic;
	signal NEScount : unsigned(7 downto 0) := 8b"0";
	signal clk : std_logic;
	signal data_out : std_logic_vector(7 downto 0);
	signal output : unsigned(7 downto 0) := 8b"0";
	
begin
	
	
    osc : HSOSC generic map ( CLKHF_DIV => "0b00")
		port map (CLKHFPU => '1',
		CLKHFEN => '1',
		CLKHF => clk);
	
	process(clk) begin
		if rising_edge(clk) then
			counter <= counter + 26d"1";		
		end if;
	end process;
	
	latch <= '1' when NEScount = 8d"255" else '0';
	clk_controller <= NESclk when (NEScount < d"8") else '0';
	NESclk <= counter(8);
	NEScount <= counter(16 downto 9);
	
	
	
	process(clk_controller) begin
		if rising_edge(clk_controller) then
				data_out(0) <= not data; --right
				data_out(1) <= data_out(0); --left
				data_out(2) <= data_out(1); --down
				data_out(3) <= data_out(2); --up
				data_out(4) <= data_out(3); --start
				data_out(5) <= data_out(4); --select
				data_out(6) <= data_out(5); --B
				data_out(7) <= data_out(6); --A
			
				
				
				--data_output(0) <= not data;
				--data_output(7 downto 1) <= data_output(6 downto 0);
		end if;
	end process;
	
	data_output <= data_out when NEScount = 8 else data_output;
	

	
	
end;
