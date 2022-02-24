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
      NUM_BITS_G     : natural := 64;
      GATE_DELAY_G   : time    := 1 ns;
      X_POS_G        : natural := 0;
      Y_POS_G        : natural := 0;
      TXRX_TYPE      : string  := "UART" -- "DUMMY"/"UART"/"ENDEAVOR"
   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;

      outData_i      : in  QpixDataFormatType;
      inData         : out QpixDataFormatType;

      regData             : out QpixRegDataType;
      regResp             : in QpixRegDataType;

      TxReady        : out std_logic;
      -- external ASIC ports
      TxPortsArr     : out QpixTxRxPortsArrType;

      RxPortsArr     : in  QpixTxRxPortsArrType;

      qpixConf       : out QpixConfigType;
      qpixReq        : out QpixRequestType
      
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

   signal TxReadyOr        : std_logic;

   --signal InData           : QpixDataFormatType := QpixDataZero_C;

begin
   
   ------------------------------------------------------------
   -- Transcievers
   ------------------------------------------------------------
   GEN_TXRX : for i in 0 to 3 generate
      --DUMMY_GEN : if TXRX_TYPE = "DUMMY" generate
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
      --end generate DUMMY_GEN;

      --UART_GEN : if TXRX_TYPE = "UART" generate 
         --QpixTxRx_U : entity work.UartTop
         --generic map (
            --NUM_BITS_G => NUM_BITS_G
         --)
         --port map (
            --clk         => clk,
            --sRst        => rst,

            ----txValid     => TxPortsArr(i).Valid,
            --txByte      => TxByteArr(i), 
            --txByteValid => TxByteValidArr(i), 
            --txByteReady => TxByteReadyArr(i),

            ----rxValid     => RxPortsArr(i).Valid,
            --rxByte      => RxByteArr(i),
            --rxByteValid => RxByteValidArr(i),
            --rxFrameErr  => open,
            --rxBreakErr  => open,

            --uartRx      => RxPortsArr(i),
            --uartTx      => TxPortsArr(i)
            
         --);
      --end generate UART_GEN;

      --ENDEAROV_GEN : if TXRX_TYPE = "ENDEAVOR" generate
         --GEN_POS : if (X_POS_G = 0 and i = 3) or (Y_POS_G = 2 and i = 2) or (X_POS_G = 2 and i = 1) generate
            --RxByteArr(i) <= (others => '0');
            --RxByteValidArr(i) <= '0';
            --TxPortsArr(i)  <= QpixTxRxPortZero_C;
         --else generate
--         GEN_POS : if (X_POS_G = 0 and i = 3) or (Y_POS_G = 2 and i = 2) or 
--            (Y_POS_G = 0 and i = 0 and X_POS_G /= 0) or (X_POS_G = 2 and i = 1) generate
--         --GEN_POS : if X_POS_G = 2 and Y_POS_G = 2 and i = 2 generate
--            RxByteArr(i) <= (others => '0');
--            RxByteValidArr(i) <= '0';
--            TxByteReadyArr(i)    <= '1';
--            TxPortsArr(i)  <= QpixTxRxPortZero_C;
--            RxFifoDoutArr(i) <= (others => '0');
--            RxFifoEmptyArr(i) <= '1';
--            RxFifoFullArr(i)  <= '0';

--         else generate
            QpixTXRx_U : entity work.QpixEndeavorTop
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

               Rx          => RxPortsArr(i),
               Tx          => TxPortsArr(i)
            );

            FIFO_U : entity work.fifo_cc
            generic map(
               DATA_WIDTH => NUM_BITS_G,
               DEPTH      => G_FIFO_MUX_DEPTH,
               RAM_TYPE   => "distributed"
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
--         end generate;
      --end generate ENDEAROV_GEN;

   end generate GEN_TXRX;
   ------------------------------------------------------------

   TxReadyOr <= and TxByteReadyArr;
   TxReady   <= TxReadyOr;

   ------------------------------------------------------------
   -- FIFOs for input lines
   ------------------------------------------------------------
   --RX_FIFO_GEN : for i in 0 to 3 generate
   --end generate RX_FIFO_GEN;
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- Parser
   ------------------------------------------------------------
   QpixParser_U : entity work.QpixParser
   generic map(
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G
   )                
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
      txReady           => TxReady,

      qpixConf          => qpixConf,
      qpixReq           => qpixReq,

      regData           => regData,
      regResp           => regResp

   );
   ------------------------------------------------------------

  

end behav;



