library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity UartTop is
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
      -- RX Error statuses out
      rxFrameErr  : out std_logic; -- No valid stop bit found
      rxBreakErr  : out std_logic; -- Line low for longer than a character time
      -- TX in 
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0) := (others => '0');
      txByteValid : in  std_logic := '0';
      txByteReady : out std_logic;
      -- external ports
      uartRx      : in  std_logic;
      uartTx      : out std_logic
   );

end UartTop;

architecture Behavioral of UartTop is

   signal baudClkX8   : std_logic;

begin

   ---- Generate a clock at 8x the UART rate
   --U_UartClockGenerator : entity work.UartClockGenerator
   --   generic map (
   --      CLOCK_RATE_G => CLOCK_RATE_G,
   --      BAUD_RATE_G  => BAUD_RATE_G
   --   )
   --   port map (
   --      clk       => clk,
   --      sRst      => sRst,
   --      baudClkX8 => baudClkX8
   --   );
   baudClkX8 <= clk;

   -- Receive UART RX bytes 
   U_UartRx : entity work.UartRx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         -- Baud clock, oversampled x8
         baudClkX8   => baudClkX8,
         -- Byte signal out
         rxByte      => rxByte,
         rxByteValid => rxByteValid,
         -- Error statuses out
         rxFrameErr  => rxFrameErr,
         rxBreakErr  => rxBreakErr,

         -- UART serial signal in
         uartRx      => uartRx
      );
   
   -- Transmit UART TX bytes
   U_UartTx : entity work.UartTx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         -- Baud clock, oversampled x8
         baudClkX8   => baudClkX8,
         -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
         txByteReady => txByteReady,
         -- Byte data to send out
         txByte      => txByte,
         txByteValid => txByteValid,
         -- UART serial signal out
         uartTx      => uartTx      
      );

end Behavioral;

