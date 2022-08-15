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
      GATE_DELAY_G : time    := 1 ns
   );
   port (
      clk         : in  std_logic;
      sRst        : in  std_logic;
      -- RX out
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      rxState     : out std_logic_vector(2 downto 0);
      -- RX Error statuses out
      rxFrameErr  : out std_logic; -- No valid stop bit found
      rxBreakErr  : out std_logic; -- Line low for longer than a character time
      rxGapErr    : out std_logic; -- ??
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
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         
		 -- Byte signal out
         rxByte      => rxByte,      -- output
         rxByteValid => rxByteValid, -- output
         rxState     => rxState,     -- output
         
		 -- Error statuses out
         bitError    => rxFrameErr, -- output
         lenError    => rxBreakErr, -- output
         gapError    => rxGapErr,   -- output

         Rx          => Rx -- input
      );
   
   -- Transmit UART TX bytes
   U_Tx : entity work.QpixEndeavorTx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         
		 -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
         txByte      => txByte,      -- input
         txByteValid => txByteValid, -- input
         txByteReady => txByteReady, -- output
		 
         tx          => Tx  -- output    
      );

end Behavioral;
