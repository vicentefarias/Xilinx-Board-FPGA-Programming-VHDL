--
-- piano.vhd - FPGA Piano
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity piano is
    port ( CLK_IN       : in std_logic;
           pb_in        : in std_logic_vector(3 downto 0);
           switch_in    : in std_logic_vector(7 downto 0);
           SPK_N        : out std_logic; 
           SPK_P        : out std_logic;
           led_out      : out std_logic_vector(7 downto 0);
           digit_out    : out std_logic_vector(3 downto 0);
           seg_out      : out std_logic_vector(7 downto 0)
         );
end piano;

architecture Behavioral of piano is
   -- Xilinx Native Components
   component BUFG  port ( I : in std_logic; O : out std_logic); end component;
   component IBUFG port ( I : in std_logic; O : out std_logic); end component;
   component IBUF  port ( I : in std_logic; O : out std_logic); end component;
   component OBUF  port ( I : in std_logic; O : out std_logic); end component;
   component MMCME2_BASE
      generic( CLKFBOUT_MULT_F : real;
                DIVCLK_DIVIDE :  integer;
                CLKOUT0_DIVIDE_F  :  real
              );
      port ( CLKIN1     : in    std_logic; 
             CLKFBIN    : in    std_logic; 
             RST        : in    std_logic; 
             PWRDWN     : in    std_logic; 
             CLKOUT0    : out   std_logic; 
             CLKOUT0B   : out   std_logic;
             CLKOUT1    : out   std_logic;
             CLKOUT1B   : out   std_logic;
             CLKOUT2    : out   std_logic;
             CLKOUT2B   : out   std_logic;
             CLKOUT3    : out   std_logic;
             CLKOUT3B   : out   std_logic;
             CLKOUT4    : out   std_logic;
             CLKOUT5    : out   std_logic;
             CLKOUT6    : out   std_logic;
             CLKFBOUT   : out   std_logic; 
             CLKFBOUTB  : out   std_logic; 
             LOCKED     : out   std_logic);
   end component;

    -- My Components:

    --  Clock Divider
    component clk_dvd
    port (
          CLK     : in std_logic;
          RST     : in std_logic;
          DIV     : in std_logic_vector(15 downto 0);
          EN      : in std_logic;
          CLK_OUT : out std_logic;
          ONE_SHOT: out std_logic
         );
    end component;

    -- Note decoder
    component note_gen
    port (
          CLK       : in  std_logic;
          RST       : in  std_logic;
          NOTE_IN   : in  std_logic_vector(4 downto 0);
          DIV       : out std_logic_vector(15 downto 0)
         );
    end component;
    
    -- 7-Segment Display for Notes
    component seven_seg
        port ( CLK      : in std_logic;
               RST      : in std_logic;
               NOTE_IN  : in std_logic_vector(4 downto 0);
               SCAN_EN  : in std_logic; 
               DIGIT    : out std_logic_vector(3 downto 0);
               SEG      : out std_logic_vector(7 downto 0) 
             );
   end component;

   -- Signals
   signal CLK         : std_logic;                      -- 50MHz clock after DCM and BUFG
   signal CLK0        : std_logic;                      -- 50MHz clock from pad
   signal CLK_BUF     : std_logic;                      -- 50MHz clock after IBUF
   signal GND         : std_logic;                      
   signal RST         : std_logic;              
   signal PB          : std_logic_vector(3 downto 0);   -- Pushbuttons after ibufs
   signal digit_l     : std_logic_vector(3 downto 0);   -- 7-seg digit MUX before obuf
   signal switch      : std_logic_vector(7 downto 0);   -- Toggle switches after ibufs
   signal led         : std_logic_vector(7 downto 0);   -- LEDs after ibufs
   signal seg_l       : std_logic_vector(7 downto 0);   -- 7-seg segment select before obuf.
  
   signal one_mhz     : std_logic;                      -- 1MHz Clock
   signal one_mhz_1   : std_logic;                      -- pulse with f=1 MHz created by divider
   signal clk_10k_1   : std_logic;                      -- pulse with f=10kHz created by divider
   signal div         : std_logic_vector(15 downto 0);  -- variable clock divider for loadable counter
   signal note_in     : std_logic_vector(4 downto 0);   -- output of user interface. Current Note
   signal note_next   : std_logic_vector(4 downto 0);   -- Buffer holding current Note
   signal note_sel    : std_logic_vector(3 downto 0);   -- Encoding of switches.
   signal div_1       : std_logic;                      -- 1MHz pulse
   signal sound       : std_logic;                      -- Output of Loadable Clock Divider. Sent to Speaker if note is playing.
   signal SPK         : std_logic;                      -- Output for Speaker fed to OBUF
   
begin
    GND    <= '0';     
    RST    <= PB(0);    -- push button one is the reset
    led(1) <= RST;      -- This is just to make sure our design is running.

    -- Combinational logic to turn the sound on and off
    process (div, sound) begin
        if (div = x"0000") then
            SPK <= GND;
        else
            SPK <= sound;
        end if;
    end process;
    
    -- Speaker output
    SPK_OBUF_INST : OBUF port map (I=>SPK, O=>SPK_N);
    SPK_P <= GND; 

    -- Input/Output Buffers
    loop0 : for i in 0 to 3 generate
        pb_ibuf  : IBUF  port map(I => pb_in(i),   O => PB(i));
        dig_obuf : OBUF  port map(I => digit_l(i), O => digit_out(i));
    end generate ;
    loop1 : for i in 0 to 7 generate
        swt_obuf : IBUF  port map(I => switch_in(i), O => switch(i));
        led_obuf : OBUF  port map(I => led(i),   O => led_out(i));
        seg_obuf : OBUF  port map(I => seg_l(i), O => seg_out(i));
    end generate ;

    -- Global Clock Buffers

    -- Pad -> DCM
    CLKIN_IBUFG_INST : IBUFG
      port map (I=>CLK_IN,      
                O=>CLK0);

    -- DCM -> CLK
    CLK0_BUFG_INST : BUFG
      port map (I=>CLK_BUF,      
                O=>CLK);

   
    -- MMCM for Clock deskew and frequency synthesis
    MMCM_INST : MMCME2_BASE
      generic map(
        CLKFBOUT_MULT_F =>10.0,
        DIVCLK_DIVIDE=>1,
        CLKOUT0_DIVIDE_F =>10.0
      )
      port map (CLKIN1=>CLK0,
               CLKFBIN=>CLK, 
               RST=>RST, 
               PWRDWN=>GND, 
               CLKOUT0=>CLK_BUF,
               CLKOUT0B=>open,
               CLKOUT1=>open,
               CLKOUT1B=>open,
               CLKOUT2=>open,
               CLKOUT2B=>open,
               CLKOUT3=>open,
               CLKOUT3B=>open,
               CLKOUT4=>open,
               CLKOUT5=>open,
               CLKOUT6=>open,
               CLKFBOUT=>open, 
               CLKFBOUTB=>open, 
               LOCKED=>led(0)
               );

    -- Divide 100Mhz to 1Mhz clock
    DIV_1M : clk_dvd        
        port map ( CLK      => CLK,
                   RST      => RST,
                   DIV      => x"0032",  -- 50
                   EN       => '1',
                   CLK_OUT  => one_mhz,
                   ONE_SHOT => one_mhz_1
                 );

    -- Divide 1Mhz to Various frequencies for the notes.
    DIV_NOTE : clk_dvd        
        port map ( CLK      => CLK,
                   RST      => RST,
                   DIV      => div,
                   EN       => one_mhz_1,
                   CLK_OUT  => sound,
                   ONE_SHOT => div_1
                 );

    -- Divide 1Mhz to 10k
    DIV_10k : clk_dvd        
        port map ( CLK      => CLK,
                   RST      => RST,
                   DIV      => x"0032", -- 50
                   EN       => one_mhz_1,
                   CLK_OUT  => open,
                   ONE_SHOT => clk_10k_1
                 );

    -- Translate Encoded Note to clock divider for 1MHz clock.
    note_gen_inst : note_gen
        port map ( CLK     => CLK,
                   RST     => RST,
                   NOTE_IN => note_in,
                   DIV     => div
                 );

    -- Wire up seven-seg controller to display current note.
    seven_seg_inst : seven_seg
        port map ( CLK     => CLK,
                   RST     => RST,
                   NOTE_IN => note_in,
                   SCAN_EN => clk_10k_1,
                   DIGIT   => digit_l,
                   SEG     => seg_l
                 );

    -- User Interface
    note_in <= note_next;
    process (CLK,RST) begin
        if (RST = '1') then
            note_next <= (others => '0');
        elsif (CLK'event and CLK = '1') then                        
            case switch is 
                when "10000000" => note_sel <= "0001"; -- C
                when "01000000" => note_sel <= "0011"; -- D
                when "00100000" => note_sel <= "0101"; -- E
                when "00010000" => note_sel <= "0110"; -- F
                when "00001000" => note_sel <= "1000"; -- G
                when "00000100" => note_sel <= "1010"; -- A
                when "00000010" => note_sel <= "1100"; -- B
                when others     => note_sel <= "0000"; 
            end case;

            -- Sharp -- Add one.  PB(3) is the octave key.
            if (PB(2) = '1') then
                note_next <= PB(3) & note_sel + 1;
            -- Flat --  Minus one.
            elsif (PB(1) = '1') then
                note_next <= PB(3) & note_sel - 1;
            else 
                note_next <= PB(3) & note_sel;
            end if;

        end if;
    end process; 
    
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
   
end Behavioral;
