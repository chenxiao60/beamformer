-----------------------------------------------------------------------------------
-- Created by Sam Rohrer                                                        --
-- Beamforms in the nearfield based on a generic for distance                   --
-- This is the actual processing that was written for the FPGA                  -- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity farfield_processing is
	generic(
	divisor           : integer := 50; -- difference between system clock 1 us 
	speed_sound       : integer := 13397; -- in inches/second
	speaker_distance  : integer := 2 -- in inches
	);
	
	port(
	i_datain_r        : in     std_logic_vector (7 downto 0); -- 8 bit from memory
	i_datain_l        : in     std_logic_vector (7 downto 0); -- 8 bit from memory
	i_clock           : in     std_logic;                     -- 
	i_distance        : in     std_logic_vector (4 downto 0); -- Switches determine distance
	i_reset           : in     std_logic ;                    -- To reset the entire system
	i_sampleclock     : in     std_logic ;                    -- Rate at which the music is playing
	
	o_speaker_enable  :    out std_logic; --LDAC enable
	o_dataout         :    out std_logic_vector (7 downto 0); -- 8 bit to be multiplexed 
	o_channel         :    out std_logic_vector (4 downto 0)  -- 5 bit to select which DAC to enable
	);

end farfield_processing;

architecture Behavioral of farfield_processing is

	-- Holding Data
	type   sr_array is array(natural range <>) of std_logic_vector(7 downto 0);
	signal shift_register_l  : sr_array(4 downto 0);
	signal shift_register_r  : sr_array(4 downto 0);
	
	--Sound dataout signals to hold before output
	signal data_r_0          : std_logic_vector(7 downto 0);
	signal data_r_1          : std_logic_vector(7 downto 0);
	signal data_r_2          : std_logic_vector(7 downto 0);
	signal data_r_3          : std_logic_vector(7 downto 0);
	signal data_r_4          : std_logic_vector(7 downto 0);
	
	signal data_l_0          : std_logic_vector(7 downto 0);
	signal data_l_1          : std_logic_vector(7 downto 0);
	signal data_l_2          : std_logic_vector(7 downto 0);
	signal data_l_3          : std_logic_vector(7 downto 0);
	signal data_l_4          : std_logic_vector(7 downto 0);

	--Counts through delays
	signal sample_edges       : integer range 0 to 7;

	signal output_counter_l_0 : integer range 0 to 127;
	signal output_counter_r_0 : integer range 0 to 127;
	
	signal output_counter_l_1 : integer range 0 to 127;
	signal output_counter_r_1 : integer range 0 to 127;
	
	signal output_counter_l_2 : integer range 0 to 127;
	signal output_counter_r_2 : integer range 0 to 127;
	
	signal output_counter_l_3 : integer range 0 to 127;
	signal output_counter_r_3 : integer range 0 to 127;
	
	signal output_counter_l_4 : integer range 0 to 127;
	signal output_counter_r_4 : integer range 0 to 127;

	-- Counts through 5 different channels 
	signal mux_counter       : integer range 0 to 5;
		
	signal temp_extended_0   : std_logic_vector (8 downto 0);
	signal temp_extended_2_0 : std_logic_vector (8 downto 0);
	signal temp_extended_1   : std_logic_vector (8 downto 0);
	signal temp_extended_2_1 : std_logic_vector (8 downto 0);
	signal temp_extended_2   : std_logic_vector (8 downto 0);
	signal temp_extended_2_2 : std_logic_vector (8 downto 0);
	signal temp_extended_3   : std_logic_vector (8 downto 0);
	signal temp_extended_2_3 : std_logic_vector (8 downto 0);
	signal temp_extended_4   : std_logic_vector (8 downto 0);
	signal temp_extended_2_4 : std_logic_vector (8 downto 0);
	
	signal result_0          : std_logic_vector (8 downto 0);
	signal result_1          : std_logic_vector (8 downto 0);
	signal result_2          : std_logic_vector (8 downto 0);
	signal result_3          : std_logic_vector (8 downto 0);
	signal result_4          : std_logic_vector (8 downto 0);
					
	
	--Delays & Calculation Signals 
	signal sample_period     : integer range 0 to 25;
	signal delay_1           : integer range 0 to 127;
	signal delay_2           : integer range 0 to 127;
	signal delay_3           : integer range 0 to 127;
	signal delay_4           : integer range 0 to 127;
	signal us_clock          : std_logic;
	signal ds_squareroot     : integer range 0 to 100;
	signal ds_squared        : integer range 0 to 5000;
	
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
				if(clockpulses = divisor) then 
					us_clock                 <= Not us_clock;
					clockpulses              <= 0;
				end if;
			
			end if;
	end process;

--*************** Distance to delay converter*******--
distance_to_delay : process (i_clock)
begin
--		-- Delay 1 calculations
--		ds_squared <= (i_distance*i_distance + (speaker_distance)*(speaker_distance));
--		for n in 0 to 20 loop
--			ds_squareroot <=  ((50 + ds_squared/ds_squareroot)/2);
--		end loop;
--		delay_1 <= (ds_squareroot - i_distance)/ speed_sound;
--
--		-- Delay 2 calculations
--		ds_squared <= (i_distance*i_distance + (speaker_distance*2)*(speaker_distance*2));
--		for n in 0 to 20 loop
--			ds_squareroot <=  ((50 + ds_squared/ds_squareroot)/2);
--		end loop;
--		delay_2 <= (ds_squareroot - i_distance)/ speed_sound;
--		
--		-- Delay 3 calculations
--		ds_squared <= (i_distance*i_distance + (speaker_distance*3)*(speaker_distance*3));
--		for n in 0 to 20 loop
--			ds_squareroot <=  ((50 + ds_squared/ds_squareroot)/2);
--		end loop;
--		delay_3 <= (ds_squareroot - i_distance)/ speed_sound;
--
--		-- Delay 4 calculations
--		ds_squared <= (i_distance*i_distance + (speaker_distance*4)*(speaker_distance*4));
--		for n in 0 to 20 loop
--			ds_squareroot <=  ((50 + ds_squared/ds_squareroot)/2);
--		end loop;
--		delay_4 <= (ds_squareroot - i_distance)/ speed_sound;		

		--********** Manually Set Delays ****************--
		
		delay_1 <= 22;
		delay_2 <= 44;
		delay_3 <= 66;
		delay_4 <= 88;
		sample_period <= 22;
		
		--********** End Manually Set Delays ************--
end process;

--**************** Filling Shift Registers ************--
fill_regs : process (i_reset, i_sampleclock)
begin
	if (i_reset = '1') then
		shift_register_l <= (others => X"00");
		shift_register_r <= (others => X"00");
		        		
	-- Conditions to shift in the shift register (every new sample)
	elsif( rising_edge (i_sampleclock)) then
		if(sample_edges = 0) then 
			shift_register_r(0) <= i_datain_r;
			shift_register_l(0) <= i_datain_l;
			
		elsif(sample_edges = 1) then
			shift_register_r(1) <= i_datain_r;
			shift_register_l(1) <= i_datain_l;
		
		elsif(sample_edges = 2) then
			shift_register_r(2) <= i_datain_r;
			shift_register_l(2) <= i_datain_l; 
	
		elsif(sample_edges = 3) then
			shift_register_r(3) <= i_datain_r;
			shift_register_l(3) <= i_datain_l;
	
		elsif(sample_edges = 4) then
			shift_register_r(4) <= i_datain_r;
			shift_register_l(4) <= i_datain_l;
		
		end if;
	end if;	

end process;	
	
--******************* Sample Edge Counter ***********************--
sample_edge_counter : process (i_reset, i_sampleclock)
begin

	if(i_reset = '1') then 
		sample_edges <= 0;
	elsif (rising_edge(i_sampleclock)) then
		sample_edges <= sample_edges +1;
		if (sample_edges = 4) then
			sample_edges <= 0;
		end if;
	end if;
	
end process; 
	
--************* Processes data by inserting delays **************-- 
speaker_processing_l : process(i_reset, us_clock, i_sampleclock)
begin
		
		if(i_reset = '1') then
			output_counter_l_0 <= 0;
			output_counter_l_1 <= sample_period;
			output_counter_l_2 <= (sample_period*2);
			output_counter_l_3 <= (sample_period*3);
			output_counter_l_4 <= (sample_period*4);												

		elsif (rising_edge(us_clock)) then	
			
		-- change this based on if its working... should cause samples to be 20 us long vs 6 us long
			--if(mux_counter = 5) then
			--	data_l_0 <= "10000000";
			--	data_l_1 <= "10000000";
			--	data_l_2 <= "10000000";
			--	data_l_3 <= "10000000";
			--	data_l_4 <= "10000000";
			--end if;
			
			--Output Conditions based on delays calculated or inserted
			if(output_counter_l_0 = 0) then
				data_l_0 <= shift_register_l(0);
			elsif(output_counter_l_0 = delay_1) then
				data_l_1 <= shift_register_l(0);
			elsif(output_counter_l_0 = delay_2) then
				data_l_2 <= shift_register_l(0); 
			elsif(output_counter_l_0 = delay_3) then
				data_l_3 <= shift_register_l(0);
			elsif(output_counter_l_0 = delay_4) then
				data_l_4 <= shift_register_l(0);
			end if;
			
			if(output_counter_l_1 = 0) then
				data_l_0 <= shift_register_l(1);
			elsif(output_counter_l_1 = delay_1) then
				data_l_1 <= shift_register_l(1);
			elsif(output_counter_l_1 = delay_2) then
				data_l_2 <= shift_register_l(1); 
			elsif(output_counter_l_1 = delay_3) then
				data_l_3 <= shift_register_l(1);
			elsif(output_counter_l_1 = delay_4) then
				data_l_4 <= shift_register_l(1);
			end if;
			
			if(output_counter_l_2 = 0) then
				data_l_0 <= shift_register_l(2);
			elsif(output_counter_l_2 = delay_1) then
				data_l_1 <= shift_register_l(2);
			elsif(output_counter_l_2 = delay_2) then
				data_l_2 <= shift_register_l(2); 
			elsif(output_counter_l_2 = delay_3) then
				data_l_3 <= shift_register_l(2);
			elsif(output_counter_l_2 = delay_4) then
				data_l_4 <= shift_register_l(2);
			end if;
			
			if(output_counter_l_3 = 0) then
				data_l_0 <= shift_register_l(3);
			elsif(output_counter_l_3 = delay_1) then
				data_l_1 <= shift_register_l(3);
			elsif(output_counter_l_3 = delay_2) then
				data_l_2 <= shift_register_l(3); 
			elsif(output_counter_l_3 = delay_3) then
				data_l_3 <= shift_register_l(3);
			elsif(output_counter_l_3 = delay_4) then
				data_l_4 <= shift_register_l(3);
			end if;
			
			if(output_counter_l_4 = 0) then
				data_l_0 <= shift_register_l(4);
			elsif(output_counter_l_4 = delay_1) then
				data_l_1 <= shift_register_l(4);
			elsif(output_counter_l_4 = delay_2) then
				data_l_2 <= shift_register_l(4); 
			elsif(output_counter_l_4 = delay_3) then
				data_l_3 <= shift_register_l(4);
			elsif(output_counter_l_4 = delay_4) then
				data_l_4 <= shift_register_l(4);
			end if;
			
			--Increments every 1 us
			output_counter_l_0 <= output_counter_l_0 +1;
			output_counter_l_1 <= output_counter_l_1 +1;
			output_counter_l_2 <= output_counter_l_2 +1;
			output_counter_l_3 <= output_counter_l_3 +1;
			output_counter_l_4 <= output_counter_l_4 +1;
			
		end if; 	
		
		if(rising_edge(us_clock)) then
			if(sample_edges = 0) then 
				output_counter_l_0 <= 0;
			elsif(sample_edges = 1) then
				output_counter_l_1 <= 0;
			elsif(sample_edges = 2) then
				output_counter_l_2 <= 0;
			elsif(sample_edges = 3) then
				output_counter_l_3 <= 0;
			elsif(sample_edges = 4) then
				output_counter_l_4 <= 0;						
			end if;
		end if;
		
	end process;

--************* Processes data by inserting delays **************-- 
speaker_processing_r : process(i_reset, us_clock, i_sampleclock)
begin
		
		if(i_reset = '1') then
			output_counter_r_0 <= 0;
			output_counter_r_1 <= sample_period;
			output_counter_r_2 <= (sample_period*2);
			output_counter_r_3 <= (sample_period*3);
			output_counter_r_4 <= (sample_period*4);												

		elsif (rising_edge(us_clock)) then	
		
		-- change this based on if its working... should cause samples to be 20 us long vs 6 us long	
			--if(mux_counter = 5) then
			--	data_r_0 <= "10000000";
			--	data_r_1 <= "10000000";
			--	data_r_2 <= "10000000";
			--	data_r_3 <= "10000000";
			--	data_r_4 <= "10000000";
			--end if;
			
			--Output Conditions based on delays calculated or inserted
			if(output_counter_r_0 = 0) then
				data_r_0 <= shift_register_r(0);
			elsif(output_counter_r_0 = delay_1) then
				data_r_1 <= shift_register_r(0);
			elsif(output_counter_r_0 = delay_2) then
				data_r_2 <= shift_register_r(0); 
			elsif(output_counter_r_0 = delay_3) then
				data_r_3 <= shift_register_r(0);
			elsif(output_counter_r_0 = delay_4) then
				data_r_4 <= shift_register_r(0);
			end if;
			
			if(output_counter_r_1 = 0) then
				data_r_0 <= shift_register_r(1);
			elsif(output_counter_r_1 = delay_1) then
				data_r_1 <= shift_register_r(1);
			elsif(output_counter_r_1 = delay_2) then
				data_r_2 <= shift_register_r(1); 
			elsif(output_counter_r_1 = delay_3) then
				data_r_3 <= shift_register_r(1);
			elsif(output_counter_r_1 = delay_4) then
				data_r_4 <= shift_register_r(1);
			end if;
			
			if(output_counter_r_2 = 0) then
				data_r_0 <= shift_register_r(2);
			elsif(output_counter_r_2 = delay_1) then
				data_r_1 <= shift_register_r(2);
			elsif(output_counter_r_2 = delay_2) then
				data_r_2 <= shift_register_r(2); 
			elsif(output_counter_r_2 = delay_3) then
				data_r_3 <= shift_register_r(2);
			elsif(output_counter_r_2 = delay_4) then
				data_r_4 <= shift_register_r(2);
			end if;
			
			if(output_counter_r_3 = 0) then
				data_r_0 <= shift_register_r(3);
			elsif(output_counter_r_3 = delay_1) then
				data_r_1 <= shift_register_r(3);
			elsif(output_counter_r_3 = delay_2) then
				data_r_2 <= shift_register_r(3); 
			elsif(output_counter_r_3 = delay_3) then
				data_r_3 <= shift_register_r(3);
			elsif(output_counter_r_3 = delay_4) then
				data_r_4 <= shift_register_r(3);
			end if;
			
			if(output_counter_r_4 = 0) then
				data_r_0 <= shift_register_r(4);
			elsif(output_counter_r_4 = delay_1) then
				data_r_1 <= shift_register_r(4);
			elsif(output_counter_r_4 = delay_2) then
				data_r_2 <= shift_register_r(4); 
			elsif(output_counter_r_4 = delay_3) then
				data_r_3 <= shift_register_r(4);
			elsif(output_counter_r_4 = delay_4) then
				data_r_4 <= shift_register_r(4);
			end if;
	
			--Increments every 1 us
			output_counter_r_0 <= output_counter_r_0 +1;
			output_counter_r_1 <= output_counter_r_1 +1;
			output_counter_r_2 <= output_counter_r_2 +1;
			output_counter_r_3 <= output_counter_r_3 +1;
			output_counter_r_4 <= output_counter_r_4 +1;
			
		end if; 	
		
		if(rising_edge(us_clock)) then
			if(sample_edges = 0) then 
				output_counter_r_0 <= 0;
			elsif(sample_edges = 1) then
				output_counter_r_1 <= 0;
			elsif(sample_edges = 2) then
				output_counter_r_2 <= 0;
			elsif(sample_edges = 3) then
				output_counter_r_3 <= 0;
			elsif(sample_edges = 4) then
				output_counter_r_4 <= 0;						
			end if;
		end if;
	
end process;

----************* Output Selector (through MUX) *************--
output_selector : process (i_reset, us_clock, i_clock)
begin
	
	if (i_reset = '1') then
		mux_counter <= 0;
	
	elsif(clockpulses = 40) then
			o_channel <= (OTHERS => '1');
			o_speaker_enable <= '1';
	
	elsif (rising_edge (us_clock)) then
		
		--Selects which DAC to output to (cycles every 6 us)
		  -- also selects the data to use on each output
		if(mux_counter = 0) then
			o_dataout <= result_0 (8 downto 1);
			mux_counter <= mux_counter + 1;	
			o_speaker_enable <= '1';	
			o_channel <= (0=>'0', OTHERS=>'1');

		elsif (mux_counter = 1) then 
			o_dataout <= result_1 (8 downto 1);
			mux_counter <= mux_counter + 1;
			o_speaker_enable <= '1';
			o_channel <= (1=>'0', OTHERS=>'1');

		elsif (mux_counter = 2) then
			o_dataout <= result_2 (8 downto 1);		
			mux_counter <= mux_counter + 1;
			o_speaker_enable <= '1';
			o_channel <= (2=>'0', OTHERS=>'1');
		
		elsif (mux_counter = 3) then
			o_dataout <= result_3 (8 downto 1);
			mux_counter <= mux_counter + 1;
			o_speaker_enable <= '1';
			o_channel <= (3=>'0', OTHERS=>'1');
		
		elsif (mux_counter = 4) then
			o_dataout <= result_4 (8 downto 1);		
			mux_counter <= mux_counter + 1;
			o_speaker_enable <= '1';
			o_channel <= (4=>'0', OTHERS=>'1');
			
		elsif (mux_counter = 5) then
			o_dataout <= X"00";		
			mux_counter <= 0;
			o_speaker_enable <= '0';
			o_channel <= (OTHERS=>'1');

		end if;
	end if;
	
end process;

--********************* Combinatorial to add data together **************************--
generating_result: process (i_clock)
begin
	
	--Combinatorial Logic to fill the result registers
	temp_extended_0   <= '0' & data_r_0;
	temp_extended_2_0 <= '0' & data_l_4;
	result_0 <= temp_extended_0 + temp_extended_2_0;
	
	temp_extended_1   <= '0' & data_r_1;
	temp_extended_2_1 <= '0' & data_l_3;
	result_1 <= temp_extended_1 + temp_extended_2_1;
	
	temp_extended_2 <= '0' & data_r_2;
	temp_extended_2_2 <= '0' & data_l_2;
	result_2 <= temp_extended_2 + temp_extended_2_2;
	
	temp_extended_3 <= '0' & data_r_3;
	temp_extended_2_3 <= '0' & data_l_1;
	result_3 <= temp_extended_3 + temp_extended_2_3;
	
	temp_extended_4 <= '0' & data_r_4;
	temp_extended_2_4 <= '0' & data_l_0;
	result_4 <= temp_extended_4 + temp_extended_2_4;
	
end process;
--**************************************************************--
	
end Behavioral;
