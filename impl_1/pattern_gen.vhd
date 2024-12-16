

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity pattern_gen is
	port(
		clk: in std_logic;
		y: in std_logic_vector(9 downto 0);
		x: in std_logic_vector(9 downto 0);
		vga_counter : in std_logic_vector(18 downto 0);
		valid: in std_logic;
		vga_r: out std_logic_vector(1 downto 0);
		vga_g: out std_logic_vector(1 downto 0);
		vga_b: out std_logic_vector(1 downto 0);
		data_out: in std_logic_vector(7 downto 0)
	);
end pattern_gen;


architecture synth of pattern_gen is

	component background is
	port(
		clk     : in std_logic;
		y       : in std_logic_vector(9 downto 2);
		x       : in std_logic_vector(9 downto 2);
    	rgb     : out std_logic_vector(5 downto 0)
  	 );
    end component;
	
	component tie_fighter_spawn is
    port(
        clk       : in std_logic;                      -- Clock signal
        reset     : in std_logic;                    -- Reset signal
        spawn_y   : out std_logic_vector(9 downto 0)   -- Random Y-coordinate
    );
	end component;
	
	component xwing is
    port(
            clk      : in std_logic;
			valid    : in std_logic;
            y        : in std_logic_vector(9 downto 0);
            x        : in std_logic_vector(9 downto 0);
            rgb      : out std_logic_vector(5 downto 0)
        );
	end component;
	
	--component state_machine is
	--port(
			--clk               : in std_logic;
			--controller_data   : in std_logic_vector (7 downto 0);
			--game_state        : out std_logic_vector(3 downto 0); -- (0001 for menu, 0010 for game, 0100 for win, 1000 for loose)
			--wing_alive        : in std_logic;
			--gold_alive        : in std_logic 
	  --);
	--end component;
	
	component TieFighter is
    port(
            clk      : in std_logic;
			valid    : in std_logic;
            y        : in std_logic_vector(9 downto 0);
            x        : in std_logic_vector(9 downto 0);
            rgb      : out std_logic_vector(5 downto 0)
        );
	end component;
	
	component enemy_one is
	port(
        	clk : in std_logic;                      -- Clock signal
        	x   : in std_logic_vector(9 downto 0);  -- X-coordinate
        	y   : in std_logic_vector(9 downto 0);   -- Y-coordinate
			collision : in std_logic;
			alive : out std_logic;
			reset : in std_logic
	);
	end component enemy_one;
	
	
	signal back_rgb    : std_logic_vector(5 downto 0);
	signal xwing_rgb   : std_logic_vector(5 downto 0);
	signal xwing_y     : unsigned(9 downto 0);
	signal xwing_x     : unsigned(9 downto 0);
	signal rgb_out     : std_logic_vector(5 downto 0);
	signal x_scroll    : unsigned(9 downto 0);
	signal offset	   : unsigned(25 downto 0);
	signal offset_clk  : unsigned(18 downto 0);
	signal offclk_last : unsigned(18 downto 0);
	signal game_over   : std_logic;
	signal win_state   : std_logic;
	signal pause_pos   : std_logic;
	
	
	--signal speedclk, speedclk_last : std_logic;
	--signal speedcount : unsigned(8 downto 0);
	--signal speed : unsigned(8 downto 0) := b"000001111";
	
	
	signal enemy_A_scrl : unsigned(9 downto 0);
	signal enemy_one_adr   : std_logic_vector(19 downto 0);
	signal enemy_one_rgb : std_logic_vector(5 downto 0);
	
	signal enemy_B_scrl : unsigned(9 downto 0);
	signal enemy_two_adr   : std_logic_vector(19 downto 0);
	signal enemy_two_rgb : std_logic_vector(5 downto 0);
	
	signal enemy_C_scrl : unsigned(9 downto 0);
	signal enemy_three_adr   : std_logic_vector(19 downto 0);
	signal enemy_three_rgb : std_logic_vector(5 downto 0);
	
	signal enemy_D_scrl : unsigned(9 downto 0);
	signal enemy_four_adr   : std_logic_vector(19 downto 0);
	signal enemy_four_rgb : std_logic_vector(5 downto 0);
	
	signal enemy_E_scrl : unsigned(9 downto 0);
	signal enemy_five_adr   : std_logic_vector(19 downto 0);
	signal enemy_five_rgb : std_logic_vector(5 downto 0);
	
	signal enemy_F_scrl : unsigned(9 downto 0);
	signal enemy_six_adr   : std_logic_vector(19 downto 0);
	signal enemy_six_rgb : std_logic_vector(5 downto 0);
	
	signal collision : std_logic_vector(5 downto 0); --one bit for every sprite we have
	signal reset : std_logic; -- resets tie-fighters after the x-wing dies
	signal kills : unsigned(7 downto 0);
	
	--Lasers
	signal laser_x, laser_y : unsigned(9 downto 0);
	signal laser_valid : std_logic;
	signal laser_rgb : std_logic_vector(5 downto 0) := "110000";
	
	constant laser_width : unsigned(3 downto 0) := "1100";  -- 12
	constant laser_height : unsigned(1 downto 0) := "11"; -- 3
	
	signal laser_two_x, laser_two_y : unsigned(9 downto 0);
	signal laser_two_valid : std_logic;
	signal laser_two_rgb : std_logic_vector(5 downto 0) := "110000";
begin

	BACK: background
		port map(
			clk => clk,
			x => std_logic_vector(x_scroll(9 downto 2)),
			y => y(9 downto 2),
			rgb => back_rgb
		);
		
	HERO: xwing
		port map(
			clk => clk,
			valid => valid,
			y   => std_logic_vector(unsigned(y) + xwing_y), 
			x   => std_logic_vector(unsigned(x) + xwing_x), 
			rgb => xwing_rgb
		);
		   
	EA_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_one_adr(19 downto 10))),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_one_adr(9 downto 0)) + enemy_A_scrl),
			rgb => enemy_one_rgb
		);
		
	EB_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_two_adr(19 downto 10)) - 70),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_two_adr(9 downto 0)) + enemy_B_scrl),
			rgb => enemy_two_rgb
		);

	EC_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_three_adr(19 downto 10)) - 140),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_three_adr(9 downto 0)) + enemy_C_scrl),
			rgb => enemy_three_rgb
		);
		
	ED_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_four_adr(19 downto 10)) - 210),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_four_adr(9 downto 0)) + enemy_D_scrl),
			rgb => enemy_four_rgb
		);
		
	EE_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_five_adr(19 downto 10)) - 280),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_five_adr(9 downto 0)) + enemy_E_scrl),
			rgb => enemy_five_rgb
		);
		
	EF_RGB: TieFighter
		port map(
			clk => clk,
			valid => valid,
			y => std_logic_vector(unsigned(y) + unsigned(enemy_six_adr(19 downto 10)) - 350),
			x => std_logic_vector(unsigned(x) + unsigned(enemy_six_adr(9 downto 0)) + enemy_F_scrl),
			rgb => enemy_six_rgb
		);
	


	
	-- player movement
	process(clk) begin
		if rising_edge(clk) then
			if offset_clk(16) and not offclk_last(16) then
				--if pause_pos = '0' then
					-- Player vertical movement
					if data_out(3) = '1' then -- moves up
							xwing_y <= xwing_y + 1;
					elsif data_out(2) = '1' then -- moves down
							xwing_y <= xwing_y - 1; 
					else xwing_y <= xwing_y;
					end if;

					-- Player horizontal movement
					if data_out(1) = '1' then -- moves left
							xwing_x <= xwing_x + 1; 
					elsif data_out(0) = '1' then -- moves right
							xwing_x <= xwing_x - 1;
					else xwing_x <= xwing_x;
					end if;
				--else
					--xwing_x <= xwing_x; -- stays the same
					--xwing_y <= xwing_y; -- stays the same
				--end if;
			end if;
		end if;
	end process;
	
	-- Laser Logic
	process(clk)
	begin
		if rising_edge(clk) then
			-- Fire bullet if button pressed and bullet not already valid
			if data_out(7)  = '1' then
				-- Places bullet at player position + 10
				laser_x <= (unsigned(xwing_x) - 34); 
				laser_y <= (unsigned(xwing_y) - 4);
				laser_two_x <= (unsigned(xwing_x) - 34); 
				laser_two_y <= (unsigned(xwing_y) - 38);

				laser_valid <= '1';
				laser_two_valid <= '1';
				
			
							
			else 
				if ((laser_valid) and (offset_clk(15) and not offclk_last(15))) then
					laser_x <= (unsigned(laser_x) - 1);
				 end if;
				 if ((laser_two_valid) and (offset_clk(15) and not offclk_last(15))) then
					laser_two_x <= (unsigned(laser_two_x) - 1);
				 end if;
				 if unsigned(laser_x) < 48 then 
					laser_valid <= '0';
				 end if;
				 if unsigned(laser_two_x) < 48 then 
					laser_two_valid <= '0';
				 end if;
			end if;
		end if;

	end process;
		
	process(clk) is
	  begin
		if rising_edge(clk) then
			offclk_last <= offset_clk;
			offset_clk <= offset_clk + d"2";
			
			if offset_clk(18) and not offclk_last(18) then
				offset <= offset + d"1";
			end if;
		end if;
	end process;
	
	x_scroll <= (unsigned(x) + offset(9 downto 0)) mod d"640";
	
	-- Sets priority for rgb output
	process(valid, y, x)
	begin
		if valid = '1' then
			if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) <= 45) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
				rgb_out <= xwing_rgb;
			elsif (unsigned(laser_rgb) > b"000000") and ((unsigned(x) + laser_x) < 12)
			and ((unsigned(x) - laser_x >= 0))
			and ((unsigned(y) + laser_y < 4) and (unsigned(y) + laser_y) >= 0) then
				rgb_out <= laser_rgb;
			elsif (unsigned(laser_two_rgb) > b"000000") and ((unsigned(x) + laser_two_x) < 12)
			and ((unsigned(x) - laser_two_x >= 0))
			and ((unsigned(y) + laser_two_y < 4) and (unsigned(y) + laser_two_y) >= 0) then
				rgb_out <= laser_two_rgb;
			elsif (unsigned(enemy_one_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_A_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_A_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) < 47) and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) >= 0) then
				rgb_out <= enemy_one_rgb;
			elsif (unsigned(enemy_two_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_B_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_B_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) < 117) and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) >= 70) then
				rgb_out <= enemy_two_rgb;
			elsif (unsigned(enemy_three_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_C_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_C_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) < 187) and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) >= 140) then
				rgb_out <= enemy_three_rgb;
			elsif (unsigned(enemy_four_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_D_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_D_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) < 257) and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) >= 210) then
				rgb_out <= enemy_four_rgb;
			elsif (unsigned(enemy_five_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_E_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_E_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) < 327) and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) >= 280) then
				rgb_out <= enemy_five_rgb;
			elsif (unsigned(enemy_six_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_F_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_F_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) < 397) and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) >= 350) then
				rgb_out <= enemy_six_rgb;
			else
				rgb_out <= back_rgb;
			end if;
		else
			rgb_out <= "000000";
		end if;
	end process;
	
	--collision module
	process(clk) begin
      if rising_edge(clk) then
        -- If at the current (x,y) coordinate, both xwing and tie1 are being drawn, then they are colliding.
		-- Enemy one
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_one_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_A_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_A_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) < 47) and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) >= 0) then
				  enemy_A_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_one_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_A_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_A_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) < 47) and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) >= 0) then
				  kills        <= kills + 8b"1";
				  enemy_A_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_one_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_A_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_A_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) < 47) and ((unsigned(y) + unsigned(enemy_one_adr(19 downto 10))) >= 0) then
				  kills        <= kills + d"1";
				  enemy_A_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					--if enemy_A = '1' then
					enemy_A_scrl <= enemy_A_scrl + 1;
		  end if;
		  
	-- Enemy two
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_two_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_B_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_B_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) < 117) and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) >= 70) then
				  enemy_B_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					
					enemy_B_scrl <= enemy_B_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_two_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_B_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_B_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) < 117) and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) >= 70) then
				  kills        <= kills + 8b"1";
				  enemy_B_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_two_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_B_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_B_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) < 117) and ((unsigned(y) + unsigned(enemy_two_adr(19 downto 10))) >= 70) then
				  kills        <= kills + d"1";
				  enemy_B_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					enemy_B_scrl <= enemy_B_scrl + 1;
		  end if;
		  
		  
	-- Enemy three
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_three_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_C_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_C_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) < 187) and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) >= 140) then
				  enemy_C_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					
					enemy_C_scrl <= enemy_C_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_three_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_C_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_C_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) < 187) and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) >= 140) then
				  kills        <= kills + 8b"1";
				  enemy_C_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_three_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_C_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_C_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) < 187) and ((unsigned(y) + unsigned(enemy_three_adr(19 downto 10))) >= 140) then
				  kills        <= kills + d"1";
				  enemy_C_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					enemy_C_scrl <= enemy_C_scrl + 1;
		  end if;  
	
	-- Enemy four
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_four_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_D_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_D_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) < 257) and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) >= 210) then
				  enemy_D_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					
					enemy_D_scrl <= enemy_D_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_four_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_D_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_D_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) < 257) and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) >= 210) then
				  kills        <= kills + 8b"1";
				  enemy_D_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_four_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_D_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_D_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) < 257) and ((unsigned(y) + unsigned(enemy_four_adr(19 downto 10))) >= 210) then
				  kills        <= kills + d"1";
				  enemy_D_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					enemy_D_scrl <= enemy_D_scrl + 1;
		  end if;  
	-- Enemy five
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_five_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_E_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_E_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) < 327) and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) >= 280) then
				  enemy_E_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then					
					enemy_E_scrl <= enemy_E_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_five_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_E_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_E_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) < 327) and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) >= 280) then
				  kills        <= kills + 8b"1";
				  enemy_E_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_five_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_E_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_E_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) < 327) and ((unsigned(y) + unsigned(enemy_five_adr(19 downto 10))) >= 280) then
				  kills        <= kills + d"1";
				  enemy_E_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
				end if;
			end if;
		else 
			if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					enemy_E_scrl <= enemy_E_scrl + 1;
		  end if;  

	-- Enemy six
        if (unsigned(xwing_rgb) > b"000000") and ((unsigned(x) + unsigned(xwing_x)) < 83) 
			and ((unsigned(x) - unsigned(xwing_x)) >= 0) 
			and ((unsigned(y) + unsigned(xwing_y)) < 46) and ((unsigned(y) + unsigned(xwing_y)) >= 0) then
			if (unsigned(enemy_six_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_F_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_F_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) < 397) and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) >= 350) then
				  enemy_F_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then					
					enemy_F_scrl <= enemy_F_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
			end if;
        end if;
		if ((unsigned(laser_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_y)) < 3) and ((unsigned(y) + unsigned(laser_y)) >= 0) then
			if (unsigned(enemy_six_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_F_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_F_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) < 397) and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) >= 350) then
				  kills        <= kills + 8b"1";
				  enemy_F_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
				end if;
			end if;
		else 
			collision <= b"000000";
			if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
			end if;
        end if;
			if ((unsigned(laser_two_rgb)) > b"000000") and ((unsigned(x) + unsigned(laser_two_x)) < 12) 
			and ((unsigned(x) - unsigned(laser_two_x)) >= 0) 
			and ((unsigned(y) + unsigned(laser_two_y)) < 3) and ((unsigned(y) + unsigned(laser_two_y)) >= 0) then
			if (unsigned(enemy_six_rgb) > b"000000") and ((unsigned(x) + unsigned(enemy_F_scrl)) < 50) 
			and ((unsigned(x) + unsigned(enemy_F_scrl)) >= 0) 
			and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) < 397) and ((unsigned(y) + unsigned(enemy_six_adr(19 downto 10))) >= 350) then
				  kills        <= kills + d"1";
				  enemy_F_scrl <= 10d"48";
			else
				if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
				end if;
			end if;
		else 
			if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
			end if;
        end if;
		if offset_clk(17) and not offclk_last(17) then
					enemy_F_scrl <= enemy_F_scrl + 1;
		  end if;  

      end if;
	end process;
	
	
	reset <= not collision(0); -- if the xwing is alove then the reset is not asserted but if the xwing dies the reset asserts
	
	
	vga_r <= rgb_out(5 downto 4);
	vga_g <= rgb_out(3 downto 2);
	vga_b <= rgb_out(1 downto 0);
	
	
end synth;
