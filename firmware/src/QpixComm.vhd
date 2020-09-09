----------------------------------------------------------------------------------
-- QPix communication with neighbour ASICs
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library work;
use work.QpixPkg.all;


entity QpixComm is
   generic (
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time    := 1 ns
   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;

      outData_i      : in  QpixDataFormatType;
      inData         : out QpixDataFormatType;
      regData        : out QpixRegDataType;

      TxReady        : out std_logic;
      -- external ASIC ports
      TxPortsArr     : out QpixTxRxPortsArrType;

      RxPortsArr     : in  QpixTxRxPortsArrType
      
   );
end entity QpixComm;

architecture behav of QpixComm is

   ------------------------------------------------------------
   -- Type defenitions
   ------------------------------------------------------------
   type   QpixDataArrType is array (0 to 3) of QpixDataFormatType;

   ------------------------------------------------------------
   -- Signals
   ------------------------------------------------------------
   signal txByteArr        : QpixByteArrType      := (others => (others => '0'));
   signal txByteValidArr   : std_logic_vector(3 downto 0);
   signal txByteReadyArr   : std_logic_vector(3 downto 0);

   signal RxByteArr        : QpixByteArrType      := (others => (others => '0'));
   signal RxByteValidArr   : std_logic_vector(3 downto 0);

   signal RxFifoDoutArr    : QpixByteArrType      := (others => (others => '0'));
   signal RxFifoREnArr     : std_logic_vector(3 downto 0);
   signal RxFifoEmptyArr   : std_logic_vector(3 downto 0);
   signal RxFifoFullArr    : std_logic_vector(3 downto 0);

   --signal InData           : QpixDataFormatType := QpixDataZero_C;

begin
   
   ------------------------------------------------------------
   -- Transcievers
   ------------------------------------------------------------
   GEN_TXRX : for i in 0 to 3 generate
      --QpixDummyTxRx_U : entity work.QpixDummyTxRx
      --generic map (
         --NUM_BITS_G => NUM_BITS_G
      --)
      --port map (
         --clk         => clk,
         --rst         => rst,

         --txPort      => TxPortsArr(i).Data,
         --txValid     => TxPortsArr(i).Valid,
         --txByte      => TxByteArr(i), 
         --txByteValid => TxByteValidArr(i), 
         --txByteReady => TxByteReadyArr(i),

         --rxPort      => RxPortsArr(i).Data, 
         --rxValid     => RxPortsArr(i).Valid,
         --rxByte      => RxByteArr(i),
         --rxByteValid => RxByteValidArr(i)
         
      --);
      QpixDummyTxRx_U : entity work.UartTop
      generic map (
         NUM_BITS_G => NUM_BITS_G
      )
      port map (
         clk         => clk,
         sRst        => rst,

         --txValid     => TxPortsArr(i).Valid,
         txByte      => TxByteArr(i), 
         txByteValid => TxByteValidArr(i), 
         txByteReady => TxByteReadyArr(i),

         --rxValid     => RxPortsArr(i).Valid,
         rxByte      => RxByteArr(i),
         rxByteValid => RxByteValidArr(i),

         uartRx      => RxPortsArr(i),
         uartTx      => TxPortsArr(i)
         
      );
   end generate GEN_TXRX;
   ------------------------------------------------------------

   TxReady <= and TxByteReadyArr;

   ------------------------------------------------------------
   -- FIFOs for input lines
   ------------------------------------------------------------
   RX_FIFO_GEN : for i in 0 to 3 generate
      FIFO_U : entity work.fifo_cc
      generic map(
         DATA_WIDTH => NUM_BITS_G,
         DEPTH      => 4
      )
      port map(
         clk   => clk,
         rst   => rst,
         din   => RxByteArr(i),
         wen   => RxByteValidArr(i),
         ren   => RxFifoREnArr(i),
         dout  => RxFifoDoutArr(i), 
         empty => RxFifoEmptyArr(i),
         full  => RxFifoFullArr(i)
      );
   end generate RX_FIFO_GEN;
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- Parser
   ------------------------------------------------------------
   QpixParser_U : entity work.QpixParser
   port map(
      clk          => clk,
      rst          => rst,

      inBytesArr        => RxFifoDoutArr,
      inFifoEmptyArr    => RxFifoEmptyArr,
      inFifoREnArr      => RxFifoREnArr,
      inData            => inData,
                        
      outData           => outData_i,
      outBytesArr       => TxByteArr,
      outBytesValidArr  => TxByteValidArr,

      regData           =>  regData
   );
   ------------------------------------------------------------

  

end behav;



