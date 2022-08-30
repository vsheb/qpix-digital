----------------------------------------------------------------------------------
-- QPix communication with neighbour ASICs
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.QpixPkg.all;


entity QpixComm is
   generic (
      NUM_BITS_G     : natural := 64;
      GATE_DELAY_G   : time    := 1 ns;
      TXRX_TYPE      : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"
      N_ZER_CLK_G    : natural :=  8;  --2;
      N_ONE_CLK_G    : natural :=  24; --5;
      N_GAP_CLK_G    : natural :=  16; --4;
      N_FIN_CLK_G    : natural :=  40; --7;
                                       --  
      N_ZER_MIN_G    : natural :=  4;  --1;
      N_ZER_MAX_G    : natural :=  12; --3;
      N_ONE_MIN_G    : natural :=  16; --4;
      N_ONE_MAX_G    : natural :=  32; --6;
      N_GAP_MIN_G    : natural :=  8;  --3;
      N_GAP_MAX_G    : natural :=  32; --5;
      N_FIN_MIN_G    : natural :=  32  --6 

   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;

      qpixConf       : in QpixConfigType;

      outData_i      : in  QpixDataFormatType;
      inData         : out QpixDataFormatType;

      regData        : out QpixRegDataType;
      regResp        : in QpixRegDataType;

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

   signal TxReadyOr        : std_logic;

   --signal InData           : QpixDataFormatType := QpixDataZero_C;

begin
   
   ------------------------------------------------------------
   -- Transcievers
   ------------------------------------------------------------
   GEN_TXRX : for i in 0 to 3 generate

      UART_GEN : if TXRX_TYPE = "UART" generate 
         QpixTxRx_U : entity work.UartTop
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
            rxFrameErr  => open,
            rxBreakErr  => open,

            uartRx      => RxPortsArr(i),
            uartTx      => TxPortsArr(i)
            
         );
      end generate UART_GEN;

      ENDEAROV_GEN : if TXRX_TYPE = "ENDEAVOR" generate
            QpixTXRx_U : entity work.QpixEndeavorTop
            generic map (
               NUM_BITS_G    => NUM_BITS_G,
               N_ZER_CLK_G   => N_ZER_CLK_G,
               N_ONE_CLK_G   => N_ONE_CLK_G,
               N_GAP_CLK_G   => N_GAP_CLK_G,
               N_FIN_CLK_G   => N_FIN_CLK_G,
                                         
               N_ZER_MIN_G   => N_ZER_MIN_G,
               N_ZER_MAX_G   => N_ZER_MAX_G,
               N_ONE_MIN_G   => N_ONE_MIN_G,
               N_ONE_MAX_G   => N_ONE_MAX_G,
               N_GAP_MIN_G   => N_GAP_MIN_G,
               N_GAP_MAX_G   => N_GAP_MAX_G,
               N_FIN_MIN_G   => N_FIN_MIN_G
            )
            port map (
               clk         => clk,
               sRst        => rst,

               txByte      => TxByteArr(i), 
               txByteValid => TxByteValidArr(i), 
               txByteReady => TxByteReadyArr(i),

               rxByte      => RxByteArr(i),
               rxByteValid => RxByteValidArr(i),

               Rx          => RxPortsArr(i),
               Tx          => TxPortsArr(i)
            );
      end generate ENDEAROV_GEN;
   end generate GEN_TXRX;
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- FIFOs for input lines
   ------------------------------------------------------------
   RX_GEN_FIFO : for i in 0 to 3 generate
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

   end generate RX_GEN_FIFO;
   ------------------------------------------------------------

   TxReadyOr <= AND_REDUCE(TxByteReadyArr);
   TxReady   <= TxReadyOr;

   ------------------------------------------------------------
   -- Parser
   ------------------------------------------------------------
   QpixParser_U : entity work.QpixParser
   port map(
      clk          => clk,
      rst          => rst,

      qpixConf          => qpixConf,

      inBytesArr        => RxFifoDoutArr,
      inFifoEmptyArr    => RxFifoEmptyArr,
      inFifoREnArr      => RxFifoREnArr,
      inData            => inData,
                        
      outData           => outData_i,
      outBytesArr       => TxByteArr,
      outBytesValidArr  => TxByteValidArr,
      txReady           => TxReadyor,

      regData           => regData,
      regResp           => regResp

   );
   ------------------------------------------------------------

  

end behav;



