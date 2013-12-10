----------------------------------------------------------------------------------
-- Created by Sam Rohrer                                                        --
-- Beamforms in the nearfield based on a generic for distance                   -- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity testbench_nearfield is
	
	port(
	--sys_clock           : in     std_logic; -- system clk signal
	swt_distance        : in     std_logic_vector (4 downto 0); -- switch 0 to 4
	--but_reset           : in     std_logic ; --Button D
	--pin_sampleclock     : in     std_logic ; -- JB 7
	
	pin_dataout         :    out std_logic_vector (7 downto 0); -- JA 0 to 7
	pin_channel         :    out std_logic_vector (4 downto 0); -- JB 0 to 4
	
	--Memory Access
	MemAdr              :    out std_logic_vector (26 downto 1); -- memory address
	MemDB               : in     std_logic_vector (15 downto 0)	 -- memory address
	
	);
end testbench_nearfield;

architecture Behavioral of testbench_nearfield is
	
	--******************* Signal Processing ***************--
	component nearfield_processing is
		
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
	
		o_dataout         :    out std_logic_vector (7 downto 0); -- 8 bit to be multiplexed 
		o_channel         :    out std_logic_vector (4 downto 0)  -- 5 bit to select which DAC to enable
		);
		
	end component;
	
	--****************** Memory Access ********************--
	
	component mem_access is
		
		port(
		o_datain_r        :    out std_logic_vector (7 downto 0); -- 8 bit from memory
		o_datain_l        :    out std_logic_vector (7 downto 0); -- 8 bit from memory
		o_addressbus      :    out std_logic_vector (26 downto 1);
	
		i_databus         : in     std_logic_vector (15 downto 0);
		i_sampleclock     : in     std_logic;
		i_clock           : in     std_logic;
		i_reset           : in     std_logic	
		);
	
	end component;
	
	--****************** RAM Component *******************--
	
	component cellram is
		
		port(
	    	clk; 
	   	 	adv_n;
	    	cre;
	   	 	o_wait;
	   	 	ce_n;
	   	 	oe_n;
	   	 	we_n;
	   	 	lb_n;
	   	 	ub_n;
	   	 	addr;
	    	dq 
		);
		
	end component; 
	
	--**************** User Signals ***************--
	
	signal mem_datain_r    : std_logic_vector (7 downto 0) := X"00";
	signal mem_datain_l    : std_logic_vector (7 downto 0) := X"00";
	
	signal sys_clock       : std_logic;
	signal pin_sampleclock : std_logic;
	signal but_reset       : std_logic;

	--**************** End User Signals ***********--

begin
	
	--*************** User Processes **************--
	but_reset <= '0', '1' after 100 ns, '0' after 1000 ns;
	
	data:process (pin_sampleclock)
	begin
	if (rising_edge(pin_sampleclock)) then
		mem_datain_r <= mem_datain_r + X"1";
		mem_datain_l <= mem_datain_l + X"1";
	end if;
	end process;

	clk: process
	begin
		sys_clock   <= '0';
		wait for 5 ns;
		sys_clock   <= '1';
		wait for 5 ns;
	end process; 

	sampleclock_division : process(but_reset, sys_clock)
	begin
			if (but_reset = '1') then
				clockpulses                 <= 0;
				pin_sampleclock             <= '0';

			elsif(rising_edge(sys_clock)) then
				clockpulses                 <= clockpulses + 1 ;
				if(clockpulses = 2200) then 
					pin_sampleclock         <= Not pin_sampleclock;
					clockpulses             <= 0;
				end if;
			
			end if;
	end process;
 
	--*************** End User Processes **********--
	
--**************** Signal Processing Port Map ***********--	
	
	fpga : nearfield_processing
	generic map(
		divisor           	=> 50,
		speed_sound         => 13397,
		speaker_distance    => 2
		)

	port map(
		i_datain_r          => mem_datain_r,
		i_datain_l          => mem_datain_l,
		i_clock             => sys_clock,
		i_distance          => swt_distance,
		i_reset             => but_reset,
		i_sampleclock       => pin_sampleclock,

		o_dataout           => pin_dataout,
		o_channel           => pin_channel
		);
		
--*************************** Memory Port Map ******************--
		
	memory: mem_access
	port map(
	--o_datain_r              => mem_datain_r, 
	--o_datain_l              => mem_datain_l,
	o_addressbus            => MemAdr,
	
	i_databus               => MemDB,
	i_sampleclock           => pin_sampleclock,
	i_clock                 => sys_clock,
	i_reset                 => but_reset
	);
	
	
end Behavioral;