
-- VHDL Test Bench Created from source file piano.vhd -- 01:25:43 12/17/2004
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY piano_tb IS
END piano_tb;

ARCHITECTURE behavior OF piano_tb IS 

	COMPONENT piano
	PORT(
		CLK_IN : IN std_logic;
		pb_in : IN std_logic_vector(3 downto 0);          
        switch_in: in std_logic_vector(7 downto 0);
        SPK_N : OUT std_logic;
		SPK_P : OUT std_logic;
		led_out : OUT std_logic_vector(7 downto 0);
		digit_out : OUT std_logic_vector(3 downto 0);
		seg_out : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	SIGNAL CLK_IN :  std_logic;
	SIGNAL pb_in :  std_logic_vector(3 downto 0);
	SIGNAL SPK_N :  std_logic;
	SIGNAL SPK_P :  std_logic;
	SIGNAL led_out :  std_logic_vector(7 downto 0);
    SIGNAL switch_in: std_logic_vector(7 downto 0);
	SIGNAL digit_out :  std_logic_vector(3 downto 0);
	SIGNAL seg_out :  std_logic_vector(7 downto 0);

BEGIN

	uut: piano PORT MAP(
		CLK_IN => CLK_IN,
		pb_in => pb_in,
                switch_in => switch_in,
		SPK_N => SPK_N,
		SPK_P => SPK_P,
		led_out => led_out,
		digit_out => digit_out,
		seg_out => seg_out
	);

clk_gen: PROCESS 
BEGIN
	CLK_IN <= '0';
	wait for 5 ns;
	CLK_IN <= '1';
	wait for 5 ns;
END PROCESS;

-- *** Test Bench - User Defined Section ***
   tb : PROCESS
   BEGIN
		
		-- pb_in(0) := pushbutton0 / reset
		-- pb_in(3) := pushbutton3 / octave
		-- switch_in := 8-bit-logic-vector / note being played
		-- System Reset
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;
		
		-- On System Reset:
		-- **Song Begins**
		-- Row, Row, Row your boat
		-- C C C D E
		-- e.g. first note:
		-- First Note: C4
		-- Set Octave with pushbutton 3: pb_in(3) <= ‘1’;
		-- Select Note with switch: switch_in <= x”80” (‘1000 0000’ = ‘C’)
		-- Must allow note to play for enough time (one full period)
		-- Briefly reset with pushbuttons, play next note
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: D4
		pb_in(3) <= '1';
		switch_in <= x"40";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E4
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- Gently down the stream
		-- E D E F G
		-- note: E4
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: D4
		pb_in(3) <= '1';
		switch_in <= x"40";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E4
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: F4
		pb_in(3) <= '1';
		switch_in <= x"10";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: G4
		pb_in(3) <= '1';
		switch_in <= x"08";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- Merrily, merrily, merrily, merrily
		-- C C C G G G E E E C C C
		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: G
		pb_in(3) <= '1';
		switch_in <= x"08";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: G
		pb_in(3) <= '1';
		switch_in <= x"08";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: G
		pb_in(3) <= '1';
		switch_in <= x"08";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- Life is but a dream
		-- G F E D C
		-- note: G4
		pb_in(3) <= '1';
		switch_in <= x"08";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: F4
		pb_in(3) <= '1';
		switch_in <= x"10";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: E4
		pb_in(3) <= '1';
		switch_in <= x"20";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: D4
		pb_in(3) <= '1';
		switch_in <= x"40";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;

		-- note: C4
		pb_in(3) <= '1';
		switch_in <= x"80";
		wait for 4ms;
		pb_in(0) <= '1';
		wait for 50 ns;
		pb_in <= "0000";
		wait for 100 ns;
----------------------------------------------------------------------
   END PROCESS;
-- *** End Test Bench - User Defined Section ***

END;
