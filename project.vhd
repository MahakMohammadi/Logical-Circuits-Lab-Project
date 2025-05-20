library IEEE;

use IEEE.STD_LOGIC_1164.all;

use IEEE.STD_LOGIC_UNSIGNED.all;

use IEEE.NUMERIC_STD.all;

entity project is
	
	port( CLK, RST_N: in std_logic;
	
		key: in std_logic_vector(7 downto 0);
	
	   sevenSegments: out std_logic_vector(6 downto 0);
		   
		an: out std_logic_vector(3 downto 0)
		
		);
end project;



architecture project of project is 

	subtype STATE_TYPE is std_ulogic_vector(2 downto 0);

	signal current_state: STATE_TYPE;
	
	constant S_WAIT: STATE_TYPE := "000";
	
	constant S_2025: STATE_TYPE := "001";
	
	constant S_COUNT: STATE_TYPE := "010";
	
	constant S_GOAL: STATE_TYPE := "011";
	
	constant S_BLINK: STATE_TYPE := "100";
	
	signal seg_selectors : std_logic_vector(3 downto 0) := "1110";
	
	signal seg0 : std_logic_vector(6 downto 0) := "1111111";
	
	signal seg1 : std_logic_vector(6 downto 0) := "1111111";
	
	signal seg2 : std_logic_vector(6 downto 0) := "1111111";
	
	signal seg3 : std_logic_vector(6 downto 0) := "1111111";
	
	signal counter_player1: integer:= 0; 
	
	signal counter_player2: integer:= 0;
	
	signal blinker: std_logic:= '0';
	
	type array2d is Array(7 downto 0) of std_logic_vector(6 downto 0);
	
	signal goal_shifter : array2d;	  
	
	impure function bcd_to_sseg(bcd  : unsigned(3 downto 0)) return std_logic_vector is   
	begin
		case bcd  is
				when "0000" => return "1000000"; -- 0
				when "0001" => return "1111001"; -- 1
				when "0010" => return "0100100"; -- 2
				when "0011" => return "0110000"; -- 3
				when "0100" => return "0011001"; -- 4
				when "0101" => return "0010010"; -- 5
				when "0110" => return "0000010"; -- 6
				when "0111" => return "1111000"; -- 7
				when "1000" => return "0000000"; -- 8
				when "1001" => return "0010000"; -- 9  
				when "1100" => return "0001000"; -- A
				when "1110" => return "1000111"; -- L
				when others => return "1111111"; -- Blank display for invalid BCD
		end case;
end bcd_to_sseg;
	
begin	
	
	--change selector to choose one of segments each time
	process (CLK) 
	
		variable counter : integer range 0 to 5000 := 0;
	
	begin
		
		if rising_edge(CLK) then
			
			counter := counter + 1;
			
			if (counter = 4999) then
				
				counter := 0;  
				
				seg_selectors <= seg_selectors(0) & seg_selectors(3 downto 1);
				
			end if;	
			
		end if;	
		
	end process; 
	
	an <= seg_selectors;
	
	--to show sth on seven-segments
	process (seg_selectors, seg0, seg1, seg2, seg3)
	begin
		
		case seg_selectors is
			
			when "1110" => sevenSegments <= seg0; 
			
			when "1101" => sevenSegments <= seg1;  
			
			when "1011" => sevenSegments <= seg2;
			
			when "0111" => sevenSegments <= seg3;
			
			when others => sevenSegments <= "1111111";
			
		end case;
		
	end process;
	
	process(CLK, RST_N)
	begin 
		
		if RST_N = '0' then
			
			current_state <= S_WAIT;
			
		elsif rising_edge(CLK) then
			
			case current_state is
				
				when S_WAIT => if key(0) = '1' then	 current_state <= S_2025; end if;
					
				when S_2025 => if key(1) = '1'  then current_state <= S_COUNT; end if;
				
				when S_COUNT =>	if key(3) = '1' and key(2) = '1' then current_state <= S_GOAL; end if;
				
				when S_GOAL =>	current_state <= S_BLINK;
				
				when S_BLINK =>	null;
				
				when others =>	current_state <= S_WAIT;
				
			end case;
			
		end if;
		
	end process;
	
	--counter of player1
	process (CLK, RST_N)
		variable counter : integer range 0 to 24000001 := 0;
	begin 
		
		if RST_N = '0' then
			
			counter := 0;
			
			counter_player1 <= 0;
			
		elsif rising_edge(CLK) then 
			
			counter := counter + 1;
			
			if (current_state = S_COUNT and key(3) = '0') and counter >= 24_000_000 then
				
				counter := 0;	
				if counter_player1 >= 99 then
					counter_player1 <= 0;
				else
					counter_player1 <= counter_player1 + 1; --Add counter after 24000000 clk edge
				end if;	
			end if;
			
		end if;
		
	end process; 
	
	--counter of player2
	process (CLK, RST_N)
		variable counter : integer range 0 to 24000001 := 0;
	begin 
		
		if RST_N = '0' then
			
			counter := 0;
			
			counter_player2 <= 0;
			
		elsif rising_edge(CLK) then 
			
			counter := counter + 1;
			
			if (current_state = S_COUNT and key(2) = '0') and counter >= 24_000_000 then
				
				counter := 0;
				if counter_player2 >= 99 then
					counter_player2 <= 0;
				else
					counter_player2 <= counter_player2 + 1; --Add counter after 24000000 clk edge
				end if;
				
			end if;
			
		end if;
		
	end process;
	
	--to show sth on seven-segments based on current_state
	process (current_state, counter_player1,counter_player2, blinker,goal_shifter)
	begin
		
		case current_state is
			
			when S_WAIT => 
			
				seg0 <= bcd_to_sseg("1111");
				seg1 <= bcd_to_sseg("1111");
				seg2 <= bcd_to_sseg("1111");
				seg3 <= bcd_to_sseg("1111");
				
			when S_2025 =>
			
				seg0 <= bcd_to_sseg("0010"); --2
				seg1 <= bcd_to_sseg("0000"); --0
				seg2 <= bcd_to_sseg("0010"); --2
				seg3 <= bcd_to_sseg("0101"); --5
				
			when S_COUNT =>
			
				seg0 <= bcd_to_sseg(to_unsigned((counter_player1  /  10),4)); 
				seg1 <= bcd_to_sseg(to_unsigned((counter_player1 rem 10), 4));
				seg2 <= bcd_to_sseg(to_unsigned((counter_player2  /  10), 4));
				seg3 <= bcd_to_sseg(to_unsigned((counter_player2 rem 10), 4));
				
			when S_GOAL =>
			
				seg0 <= bcd_to_sseg("0110"); --G
				seg1 <= bcd_to_sseg("0000"); --O
				seg2 <= bcd_to_sseg("1100"); --A
				seg3 <= bcd_to_sseg("1110"); --L
				
			when S_BLINK =>	
			
		
				seg0 <= goal_shifter(3); --G
				seg1 <= goal_shifter(2); --O
				seg2 <= goal_shifter(1); --A
				seg3 <= goal_shifter(0); --L  
				
			when others =>
			
				seg0 <= "1111111";
				seg1 <= "1111111";
				seg2 <= "1111111";
				seg3 <= "1111111"; 
				
		end case;
		
	end process;
	
	--process for blinking	
	process(CLK, RST_N)
	
	    variable temp : std_logic_vector(6 downto 0);
		variable counter : integer:= 0;
	
	begin
		
		if RST_N = '0' then
			goal_shifter(7)	 <= bcd_to_sseg("1111");
			goal_shifter(6)	 <= bcd_to_sseg("1111");
			goal_shifter(5)	 <= bcd_to_sseg("1111");
			goal_shifter(4)	 <= bcd_to_sseg("1111");
			goal_shifter(3)	 <= bcd_to_sseg("0110");
			goal_shifter(2)	 <= bcd_to_sseg("0000");
			goal_shifter(1)	 <= bcd_to_sseg("1100");
			goal_shifter(0)	 <= bcd_to_sseg("1110");
		
		elsif rising_edge(CLK) then
			
			if current_state = S_BLINK then
			
				counter:= counter + 1;
				
				if counter >= 24000000 then
					
					counter := 0;
					temp := goal_shifter(0);
					for i in 0 to 6 loop
						goal_shifter(i) <= goal_shifter(i+1);
					end loop;
					goal_shifter(7) <= temp;
					
					
				end if;
				
			end if;
			
		end if;
		
	end process;
			
end project;
