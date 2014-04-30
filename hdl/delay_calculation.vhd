----------------------------------------------------------------------------------
-- Created by Sam Rohrer                                                        --
-- Calculates delays from the generic for distance given                        --
-- This is the actual processing that was written for the FPGA                  -- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity delay_calculation is
	generic(
	divisor           : integer := 50; -- difference between system clock 1 us 
	speed_sound       : integer := 13397; -- in inches/second
	speaker_distance  : integer := 2 -- in inches
	);
	
	port(
		o_delay_1     :   out integer; 
		o_delay_2     :   out integer;
		o_delay_3     :   out integer;
		o_delay_4     :   out integer
	);

end delay_calculation;

architecture Behavioral of delay_calculation is

	--Delays & Calculation Signals 
	signal delay_1           : integer range 0 to 127;
	signal delay_2           : integer range 0 to 127;
	signal delay_3           : integer range 0 to 127;
	signal delay_4           : integer range 0 to 127;
	signal us_clock          : std_logic;
	
	signal sqrt_est          : ufixed (4 downto -6);
	
	signal dif_dist_sq_1     : ufixed (4 downto -6);
	signal dif_dist_sq_2     : ufixed (4 downto -6);
	signal dif_dist_sq_3     : ufixed (4 downto -6);
	signal dif_dist_sq_4     : ufixed (4 downto -6);
	
	signal dif_dist_sqrt_1   : ufixed (4 downto -6);
	signal dif_dist_sqrt_2   : ufixed (4 downto -6);
	signal dif_dist_sqrt_3   : ufixed (4 downto -6);
	signal dif_dist_sqrt_4   : ufixed (4 downto -6);
	
	signal dif_time_1        : ufixed (4 downto -6);
	signal dif_time_2        : ufixed (4 downto -6);
	signal dif_time_3        : ufixed (4 downto -6);
	signal dif_time_4        : ufixed (4 downto -6);

	-- Converting between fixed and std_logic Signals
	signal distance               : integer range 0 to 127;	
	signal speaker_distance_std   : std_logic_vector (4 downto 0);
	signal speed_sound_std        : std_logic_vector (14 downto 0);
	
	signal distance_fixed         : ufixed (4 downto -6);
	signal speaker_distance_fixed : ufixed (4 downto -6);
	signal sqrt_est_fixed         : ufixed (4 downto -6);
	signal speed_sound_fixed      : ufixed (14 downto -6);
	
	signal delay_1_fixed          : ufixed (4 downto -6);
	signal delay_2_fixed          : ufixed (4 downto -6);
	signal delay_3_fixed          : ufixed (4 downto -6);
	signal delay_4_fixed          : ufixed (4 downto -6);
	
	--Clock Division
	signal clockpulses       : integer range 0 to 127;
	
begin

--************** From system clock to 1 us *************--
clock_division : process(i_reset, i_clock)
begin	
	if (i_reset = '1') then
		clockpulses                 <= 0;
		us_clock                    <= '0';
	elsif(rising_edge(i_clock)) then
		clockpulses                 <= clockpulses + 1 ;
		if(clockpulses = (divisor-1)) then 
			us_clock                 <= Not us_clock;
			clockpulses              <= 0;
		end if;
	end if;
end process;

--*************** Integer to fixed **************--
	
	distance                <= i_distance; -- need to convert to ufixed
	speaker_distance_std    <= conv_std_logic_vector(speaker_distance, 5);
	speed_sound_std         <= conv_std_logic_vector(speed_sound, 14);
	
	distance_fixed          <= distance & "000000";
	speaker_distance_fixed  <= speaker_distance_std & "000000";
	speed_sound_fixed       <= speed_sound_std & "000000";

--*************** Distance to delay converter*******--
distance_to_delay : process (i_reset, i_clock, clockpulses,distance)
begin
	
	if(i_reset = '1') then 
		delay_1    <= 0;
		delay_2    <= 0;
		delay_3    <= 0;
		delay_4    <= 0;
		sqrt_est   <= "11001000000";
		
		dif_time_1 <= "00000000000";
		dif_time_2 <= "00000000000";
		dif_time_3 <= "00000000000";
		dif_time_4 <= "00000000000";
		
	elsif(rising_edge(i_clock)) then
		if(clockpulses = 1) then
			dif_dist_sq_1   <= (distance_fixed*distance_fixed + (1 * speaker_distance_fixed) * (1 * speaker_distance_fixed));
			dif_dist_sq_2   <= (distance_fixed*distance_fixed + (2 * speaker_distance_fixed) * (2 * speaker_distance_fixed));			
			dif_dist_sq_3   <= (distance_fixed*distance_fixed + (3 * speaker_distance_fixed) * (3 * speaker_distance_fixed));
			dif_dist_sq_4   <= (distance_fixed*distance_fixed + (4 * speaker_distance_fixed) * (4 * speaker_distance_fixed));
			
			dif_dist_sqrt_1 <= sqrt_est;
			dif_dist_sqrt_2 <= sqrt_est;
			dif_dist_sqrt_3 <= sqrt_est;
			dif_dist_sqrt_4 <= sqrt_est;
						
		elsif(clockpulses = 2) then
			dif_dist_sqrt_1  <= ((dif_dist_sqrt_1 + (dif_dist_sq_1 / dif_dist_sqrt_1))/2);
			dif_dist_sqrt_2  <= ((dif_dist_sqrt_2 + (dif_dist_sq_2 / dif_dist_sqrt_2))/2);
			dif_dist_sqrt_3  <= ((dif_dist_sqrt_3 + (dif_dist_sq_3 / dif_dist_sqrt_3))/2);
			dif_dist_sqrt_4  <= ((dif_dist_sqrt_4 + (dif_dist_sq_4 / dif_dist_sqrt_4))/2);
			
		elsif(clockpulses = 3) then
			dif_dist_sqrt_1  <= ((dif_dist_sqrt_1 + (dif_dist_sq_1 / dif_dist_sqrt_1))/2);
			dif_dist_sqrt_2  <= ((dif_dist_sqrt_2 + (dif_dist_sq_2 / dif_dist_sqrt_2))/2);
			dif_dist_sqrt_3  <= ((dif_dist_sqrt_3 + (dif_dist_sq_3 / dif_dist_sqrt_3))/2);
			dif_dist_sqrt_4  <= ((dif_dist_sqrt_4 + (dif_dist_sq_4 / dif_dist_sqrt_4))/2);
						
		elsif(clockpulses = 4) then
			dif_dist_sqrt_1  <= ((dif_dist_sqrt_1 + (dif_dist_sq_1 / dif_dist_sqrt_1))/2);
			dif_dist_sqrt_2  <= ((dif_dist_sqrt_2 + (dif_dist_sq_2 / dif_dist_sqrt_2))/2);
			dif_dist_sqrt_3  <= ((dif_dist_sqrt_3 + (dif_dist_sq_3 / dif_dist_sqrt_3))/2);
			dif_dist_sqrt_4  <= ((dif_dist_sqrt_4 + (dif_dist_sq_4 / dif_dist_sqrt_4))/2);
						
		elsif(clockpulses = 5) then
			dif_dist_sqrt_1  <= ((dif_dist_sqrt_1 + (dif_dist_sq_1 / dif_dist_sqrt_1))/2);
			dif_dist_sqrt_2  <= ((dif_dist_sqrt_2 + (dif_dist_sq_2 / dif_dist_sqrt_2))/2);
			dif_dist_sqrt_3  <= ((dif_dist_sqrt_3 + (dif_dist_sq_3 / dif_dist_sqrt_3))/2);
			dif_dist_sqrt_4  <= ((dif_dist_sqrt_4 + (dif_dist_sq_4 / dif_dist_sqrt_4))/2);		
			
		elsif(clockpulses = 6) then
			dif_time_1    <= ((dif_dist_sqrt_1 - distance_fixed)/ speed_sound_fixed);
			dif_time_2    <= ((dif_dist_sqrt_2 - distance_fixed)/ speed_sound_fixed);
			dif_time_3    <= ((dif_dist_sqrt_3 - distance_fixed)/ speed_sound_fixed);
			dif_time_4    <= ((dif_dist_sqrt_4 - distance_fixed)/ speed_sound_fixed);
		
		elsif(clockpulses = 7) then
			delay_1_fixed <= (dif_time_4 - dif_time_3);
			delay_2_fixed <= (dif_time_4 - dif_time_2);
			delay_3_fixed <= (dif_time_4 - dif_time_1);
			delay_4_fixed <= (dif_time_4);
		
		elsif(clockpulses = 8) then	
			delay_1       <= conv_integer(delay_1_fixed(4 downto 0));
			delay_2       <= conv_integer(delay_2_fixed(4 downto 0));
			delay_3       <= conv_integer(delay_3_fixed(4 downto 0));
			delay_4       <= conv_integer(delay_4_fixed(4 downto 0));
		
		elsif(clockpulses = 9) then
			o_delay_1     <= delay_1;
			o_delay_2     <= delay_2;
			o_delay_3     <= delay_3;
			o_delay_4     <= delay_4;
		end if;
	
	end if;
		
		--********** Manually Set Delays ****************--
		
--		delay_1 <= (22+2); --42
--		delay_2 <= (44+2); --72
--		delay_3 <= (66+2); --91
--		delay_4 <= (88+2); --97
--		sample_period <= 22;
		
		--********** End Manually Set Delays ************--
end process;
	
end Behavioral;
