library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


library work;
use work.QpixPkg.all;


entity QpixDaqNode is
   generic (
      NumPorts_G : natural := 1 
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;

      txByte      : in std_logic_vector(G_DATA_BITS-1 downto 0);
      txByteValid : in std_logic; 
      
      rxByte      : out std_logic_vector(G_DATA_BITS-1 downto 0);
      rxByteValid : out std_logic;
      
      Tx          : out QpixTxRxPortType;
      Rx          : in  QpixTxRxPortType
      --TxArr    : out QpixTxRxVarArrType(0 to NumPorts_G-1);
      --RxArr    : in  QpixTxRxVarArrType(0 to NumPorts_G-1)
      
   );
end entity QpixDaqNode;


architecture behav of QpixDaqNode is

   signal txByteArr        : QpixByteArrType      := (others => (others => '0'));
   signal txByteValidArr   : std_logic_vector(3 downto 0) := (others => '0');
   signal txByteReadyArr   : std_logic_vector(3 downto 0) := (others => '0');

   signal RxByteArr        : QpixByteArrType      := (others => (others => '0'));
   signal RxByteValidArr   : std_logic_vector(3 downto 0) := (others => '0');

begin

   --QpixDummyTxRx_U : entity work.QpixDummyTxRx
   --generic map (
      --NUM_BITS_G => G_DATA_BITS
   --)
   --port map (
      --clk         => clk,
      --rst         => rst,

      --txPort      => Tx.Data,
      --txValid     => Tx.Valid,
      --txByte      => TxByteArr(0), 
      --txByteValid => TxByteValidArr(0), 
      --txByteReady => TxByteReadyArr(0),

      --rxPort      => Rx.Data,
      --rxValid     => Rx.Valid,
      --rxByte      => RxByteArr(0),
      --rxByteValid => RxByteValidArr(0)
   --);

   --QpixUartTxRx_U : entity work.UartTop
   --generic map (
      --NUM_BITS_G => G_DATA_BITS
   --)
   --port map (
      --clk         => clk,
      --sRst        => rst,

      --txByte      => TxByteArr(0), 
      --txByteValid => TxByteValidArr(0), 
      --txByteReady => TxByteReadyArr(0),

      --rxByte      => RxByteArr(0),
      --rxByteValid => RxByteValidArr(0),

      --uartTx      => Tx,
      --uartRx      => Rx

   --);

   QpixEndeavorTxRx_U : entity work.QpixEndeavorTop
   generic map (
      NUM_BITS_G => G_DATA_BITS
   )
   port map (
      clk         => clk,
      sRst        => rst,

      txByte      => TxByteArr(0), 
      txByteValid => TxByteValidArr(0), 
      txByteReady => TxByteReadyArr(0),

      rxByte      => RxByteArr(0),
      rxByteValid => RxByteValidArr(0),

      Tx          => Tx,
      Rx          => Rx

   );

   TxByteArr(0)      <= txByte;
   txByteValidArr(0) <= txByteValid;
   
   rxByte            <= RxByteArr(0);
   rxByteValid       <= RxByteValidArr(0);


end behav;



