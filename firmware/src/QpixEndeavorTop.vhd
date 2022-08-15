library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity QpixEndeavorTop is
   generic (
      --CLOCK_RATE_G : integer := 80000000;
      --BAUD_RATE_G  : integer := 115200;
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time    := 1 ns;

      N_ZER_CLK_G  : natural :=  8;  --2;
      N_ONE_CLK_G  : natural :=  24; --5;
      N_GAP_CLK_G  : natural :=  16; --4;
      N_FIN_CLK_G  : natural :=  40; --7;
                                     --  
      N_ZER_MIN_G  : natural :=  4;  --1;
      N_ZER_MAX_G  : natural :=  12; --3;
      N_ONE_MIN_G  : natural :=  16; --4;
      N_ONE_MAX_G  : natural :=  32; --6;
      N_GAP_MIN_G  : natural :=  8;  --3;
      N_GAP_MAX_G  : natural :=  32; --5;
      N_FIN_MIN_G  : natural :=  32  --6 

   );
   port (
      clk         : in  std_logic;
      sRst        : in  std_logic;
      -- RX out
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      -- RX Error statuses out
      rxFrameErr  : out std_logic; -- No valid stop bit found
      rxBreakErr  : out std_logic; -- Line low for longer than a character time
      -- TX in 
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0) := (others => '0');
      txByteValid : in  std_logic := '0';
      txByteReady : out std_logic;
      -- external ports
      Rx          : in  std_logic;
      Tx          : out std_logic
   );

end QpixEndeavorTop;

architecture Behavioral of QpixEndeavorTop is


begin

   -- Receive UART RX bytes 
   U_Rx : entity work.QpixEndeavorRx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G,
         N_ZER_MIN_G  => N_ZER_MIN_G,
         N_ZER_MAX_G  => N_ZER_MAX_G,
         N_ONE_MIN_G  => N_ONE_MIN_G,
         N_ONE_MAX_G  => N_ONE_MAX_G,
         N_GAP_MIN_G  => N_GAP_MIN_G,
         N_GAP_MAX_G  => N_GAP_MAX_G,
         N_FIN_MIN_G  => N_FIN_MIN_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         -- Byte signal out
         rxByte      => rxByte,
         rxByteValid => rxByteValid,
         -- Error statuses out
         bitError    => rxFrameErr,
         lenError    => rxBreakErr,

         Rx          => Rx
      );
   
   -- Transmit UART TX bytes
   U_Tx : entity work.QpixEndeavorTx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G,
         N_ZER_CLK_G  => N_ZER_CLK_G,
         N_ONE_CLK_G  => N_ONE_CLK_G,
         N_GAP_CLK_G  => N_GAP_CLK_G,
         N_FIN_CLK_G  => N_FIN_CLK_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
         txByteReady => txByteReady,
         -- Byte data to send out
         txByte      => txByte,
         txByteValid => txByteValid,
         tx          => Tx      
      );

end Behavioral;

