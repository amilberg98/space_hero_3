

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity top is
    port(
		exclk         : in std_logic; --12MHz from the FPGA
        data          : in std_logic; -- NES controller data
        latch         : out std_logic; -- NES latch
        clk_controller: out std_logic; -- NES clock
        rst           : in std_logic; -- Reset
        hsync         : out std_logic; -- Horizontal sync
        vsync         : out std_logic; -- Vertical sync
        vga_r         : out std_logic_vector(1 downto 0); -- Red channel
        vga_g         : out std_logic_vector(1 downto 0); -- Green channel
        vga_b         : out std_logic_vector(1 downto 0)  -- Blue channel
    );
end top;
architecture synth of top is
	component mypll is
		port(
			ref_clk_i   : in std_logic;
			rst_n_i     : in std_logic;
			outcore_o   : out std_logic;
			outglobal_o : out std_logic
		);
	end component;
	
    component nes_controller is
        port(
            data           : in std_logic;
            data_output    : out std_logic_vector(7 downto 0);
            latch          : out std_logic;
            clk_controller : out std_logic
        );
    end component;
	
	
    component vga_controller is
        port(
			vga_clk         : in  std_logic;  -- Input clock (24.175 MHz expected)
			y   		: out std_logic_vector(9 downto 0);
			x 		: out std_logic_vector(9 downto 0);
			vga_counter : out std_logic_vector(18 downto 0);
			hsync       : out std_logic;  -- Horizontal sync
			vsync       : out std_logic;  -- Vertical sync
			valid       : out std_logic  -- Signal to indicate active display region
            --player_x    : in integer range 0 to 639; -- Player X position
            --player_y    : in integer range 0 to 479  -- Player Y position
        );
    end component;
	
	component pattern_gen is
		port (
			clk: in std_logic;
			y: in std_logic_vector(9 downto 0);
			x: in std_logic_vector(9 downto 0);
			vga_counter : out std_logic_vector(18 downto 0);
			valid: in std_logic;
			vga_r: out std_logic_vector(1 downto 0);
			vga_b: out std_logic_vector(1 downto 0);
			vga_g: out std_logic_vector(1 downto 0);
			data_out: in std_logic_vector(7 downto 0)
		);
	end component;
    signal data_out    : std_logic_vector(7 downto 0);
    signal latch_sig   : std_logic;
    signal clk_control : std_logic;
    signal player_x_pos: integer range 0 to 639 := 320; -- Player X-coordinate
    signal player_y_pos: integer range 0 to 479 := 240; -- Player Y-coordinate
	signal vga_clk     : std_logic; --25.175MHz
	signal vga_counter : std_logic_vector(18 downto 0);
	signal meep        : std_logic; ---nothing
	signal valid       : std_logic;
	signal y           : std_logic_vector(9 downto 0);
	signal x           : std_logic_vector(9 downto 0);
	signal rgb         : std_logic_vector(5 downto 0);
	signal hsync_meep  : std_logic; --internal
	signal vsync_meep  : std_logic; --internal
begin
    pll_inst : mypll
        port map (
            ref_clk_i  => exclk,        -- 50 MHz input clock
            rst_n_i => '1',     -- 25.175 MHz pixel clock
            outcore_o   => meep,
            outglobal_o  => vga_clk
        );
    NES_CTRL: nes_controller
        port map(
            data => data, 
            data_output => data_out, 
            latch => latch_sig, 
            clk_controller => clk_control
        );
    VGA_CTRL: vga_controller
        port map(
			vga_clk => vga_clk,
			y => y,
			x => x,
		    vga_counter => vga_counter,
            hsync => hsync_meep, 
            vsync => vsync_meep,
			valid => valid
            --player_x => player_x_pos,
            --player_y => player_y_pos
        );
	
	PTRN_GEN: pattern_gen
		port map(
			clk => vga_clk,
			y => y,
			x => x,
			vga_counter => vga_counter,
			valid => valid,
			vga_r => vga_r,
			vga_b => vga_b,
			vga_g => vga_g,
			data_out => data_out
		);
		
	
    latch <= latch_sig;
    clk_controller <= clk_control;
	
	process(vga_clk) begin
		if rising_edge(vga_clk) then
			hsync <= hsync_meep;
			vsync <= vsync_meep;
		end if;
	end process;
	
  
end synth;
