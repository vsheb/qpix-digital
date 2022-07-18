library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library iCE40UP;
use iCE40UP.components.all;

entity QpixAsicDummyTop is
   generic (
      G_DATA_BITS : natural := 64
   );
   port (
      --clk            : in std_logic;
      --rst            : in std_logic;

      ledRed   : out std_logic;
      leds     : out std_logic_vector(3 downto 0);
      
      -- TX ports to neighbour ASICs
      Tx     : out  std_logic;

      -- RX ports to neighbour ASICs
      Rx     : in  std_logic 
   );
end entity QpixAsicDummyTop;

architecture behav of QpixAsicDummyTop is

   signal TxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal RxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal RxByteR     : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal TxByteValid : std_logic := '0';
   signal TxByteReady : std_logic := '0';
   signal TxByteReadyR : std_logic := '0';
   signal RxByteValid : std_logic := '0';

   signal ledCnt      : std_logic_vector(31 downto 0) := (others => '0');
   signal ledGreen    : std_logic := '0';

   signal clk         : std_logic := '0';

   signal rx_r        : std_logic := '0';

   type States is (RX_S, TX_S, TX_W_S, TX_W1_S);
   signal state : States := RX_S;

begin
   
   --leds <= (others => '0');

   -- Built-in Oscillator
   U_HSOSC : HSOSC
   --U_HSOSC : SB_HFOSC
      generic map (
         CLKHF_DIV => "0b00"
      )
      port map (
         CLKHFEN => '1',
         CLKHFPU => '1',
         CLKHF   => clk
      );

   process (clk)
   begin
      if rising_edge(clk) then
         ledCnt <= ledCnt + 1;          
      end if;
   end process;
   leds(0) <= ledCnt(26);
   leds(1) <= ledGreen;
   --leds(2) <= '0';
   --leds(3) <= '0';

   PulseShaper_U : entity work.PulseShaper
   port map (
      clk => clk,
      rst => '0',
      len => x"0400_0000",
      dly => (others => '0'),
      din => rx_r,
      dou => leds(2)
   );

   process (clk)
   begin
      if rising_edge(clk) then
         rx_r <= Rx;
      end if;
   end process;

   
   QpixTXRx_U : entity work.QpixEndeavorTop
   generic map (
      NUM_BITS_G => G_DATA_BITS 
   )
   port map (
      clk         => clk,
      sRst        => '0',

      rxByte      => RxByte,
      rxByteValid => RxByteValid,
      rxBreakErr  => leds(3),

      txByte      => RxByteR, 
      txByteValid => TxByteValid, 
      txByteReady => TxByteReady,


      Rx          => Rx,
      Tx          => Tx
   );

   process (clk)
   begin
      if rising_edge(clk) then
         TxByteReadyR <= TxByteReady;
         case state is
            when RX_S => 
               ledGreen <= '1';
               ledRed   <= '0';
               TxByteValid <= '0';
               if RxByteValid = '1' then
                  RxByteR <= RxByte;
                  state <= TX_S;
               end if;
            when TX_S =>
               ledGreen <= '0';
               ledRed   <= '1';
               if TxByteReady = '1' then
                  TxByteValid <= '1';
                  state <= TX_W_S;
               end if;
            when TX_W_S => 
               ledGreen <= '0';
               ledRed   <= '1';
               TxByteValid <= '0';
               if TxByteReady = '0' then
                  state <= TX_W1_S;
               end if;
            when TX_W1_S => 
               ledGreen <= '0';
               ledRed   <= '1';
               if TxByteReady = '1' then
                  state <= RX_S;
               end if;
         end case;
         
      end if;
   end process;



end behav;

