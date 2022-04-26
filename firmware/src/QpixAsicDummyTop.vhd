library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


library work;
use work.QpixPkg.all;

entity QpixAsicDummyTop is
   port (
      clk            : in std_logic;
      rst            : in std_logic;
      
      -- TX ports to neighbour ASICs
      Tx     : out  QpixTxRxPortType;

      -- RX ports to neighbour ASICs
      Rx     : in  QpixTxRxPortType
   );
end entity QpixAsicDummyTop;

architecture behav of QpixAsicDummyTop is

   signal TxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal RxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal RxByteR     : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal TxByteValid : std_logic := '0';
   signal TxByteReady : std_logic := '0';
   signal RxByteValid : std_logic := '0';

   type States is (RX_S, TX_S);
   signal state : States := RX_S;

begin
   
   QpixTXRx_U : entity work.QpixEndeavorTop
   generic map (
      NUM_BITS_G => G_DATA_BITS 
   )
   port map (
      clk         => clk,
      sRst        => rst,

      txByte      => RxByteR, 
      txByteValid => TxByteValid, 
      txByteReady => TxByteReady,

      rxByte      => RxByte,
      rxByteValid => RxByteValid,

      Rx          => Rx,
      Tx          => Tx
   );

   process (clk)
   begin
      if rising_edge(clk) then
      case state is
         when RX_S => 
            TxByteValid <= '0';
            if RxByteValid = '1' then
               RxByteR <= RxByte;
               state <= TX_S;
            end if;
         when TX_S =>
            if TxByteReady = '1' then
               TxByteValid <= '1';
               state <= RX_S;
            end if;
      end case;
         
      end if;
   end process;



end behav;

