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
      X_POS_G        : natural := 0;
      Y_POS_G        : natural := 0;
      RAM_TYPE       : string  := "Lattice"; -- lattice hardcodes BRAM for lattice, or distributed / block
      TXRX_TYPE      : string  := "ENDEAVOR" -- "DUMMY"/"UART"/"ENDEAVOR"
   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;

      -- external ASIC ports
      TxPortsArr     : out std_logic_vector(3 downto 0);
      RxPortsArr     : in  std_logic_vector(3 downto 0);
      
      -- tx/rx data to QpixRoute
      parseDataRx    : in  QpixDataFormatType; -- Tx from QpixRoute
      parseDataTx    : out QpixDataFormatType; -- Rx to QpixRoute
      parseDataReady : out std_logic;          -- Tx-ready to QpixRoute

      -- Debug
      TxByteValidArr_out : out std_logic_vector(3 downto 0);
      RxByteValidArr_out : out std_logic_vector(3 downto 0);
      RxFifoEmptyArr_out : out std_logic_vector(3 downto 0);
      RxFifoFullArr_out  : out std_logic_vector(3 downto 0);

      -- register from  QpixRegFile
      qpixConf       : in QpixConfigType;

      -- register information to QpixRegFile
      regData        : out QpixRegDataType;
      regResp        : in QpixRegDataType
   );
end entity QpixComm;

architecture behav of QpixComm is

   ------------------------------------------------------------
   -- Type defenitions
   ------------------------------------------------------------
   type QpixDataArrType is array (0 to 3) of QpixDataFormatType;

   ------------------------------------------------------------
   -- Signals
   ------------------------------------------------------------
   signal TxByteArr      : QpixByteArrType              := (others => (others => '0'));
   signal TxByteValidArr : std_logic_vector(3 downto 0) := (others => '0');
   signal TxByteReadyArr : std_logic_vector(3 downto 0) := (others => '0');

   signal RxByteArr        : QpixByteArrType      := (others => (others => '0'));
   signal RxByteValidArr   : std_logic_vector(3 downto 0) := (others => '0');

   signal RxFifoDoutArr    : QpixByteArrType      := (others => (others => '0'));
   signal RxFifoREnArr     : std_logic_vector(3 downto 0) := (others => '0');
   signal RxFifoEmptyArr   : std_logic_vector(3 downto 0) := (others => '0');
   signal RxFifoFullArr    : std_logic_vector(3 downto 0) := (others => '0');

   signal TxReadyOr        : std_logic := '0';

   --signal parseDataTx           : QpixDataFormatType := QpixDataZero_C;

begin

   -- debug
   TxByteValidArr_out <= TxByteValidArr;
   RxByteValidArr_out <= RxByteValidArr;
   RxFifoEmptyArr_out <= RxFifoEmptyArr;
   RxFifoFullArr_out <= RxFifoFullArr;
   
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
               NUM_BITS_G => NUM_BITS_G
            )
            port map (
               clk         => clk,
               sRst        => rst,
               -- Input of TxByte to send to physical
               txByte      => TxByteArr(i),       -- input, slv(63 downto 0)
               txByteValid => TxByteValidArr(i),  -- input
               txByteReady => TxByteReadyArr(i),  -- ouput
               -- Output of Rx to FIFO
               rxFrameErr  => open,               -- output
               rxBreakErr  => open,               -- output
               rxGapErr    => open,               -- output
               rxByte      => RxByteArr(i),       -- output, slv(63 downto 0)
               rxByteValid => RxByteValidArr(i),  -- output
               rxState     => open,               -- output, slv(2 downto 0)
               -- external ports
               Rx          => RxPortsArr(i),      -- input
               Tx          => TxPortsArr(i)       -- output
         );


      end generate ENDEAROV_GEN;

         -- select the correct RAM_TYPE
         gen_qdb_fifo: if (RAM_TYPE = "Lattice") generate
            FIFO_U : entity work.QDBFifo
            generic map(
               DATA_WIDTH => NUM_BITS_G,
               DEPTH      => G_FIFO_MUX_DEPTH,
               RAM_TYPE   => RAM_TYPE
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
         end generate;
         gen_fifo_cc: if (RAM_TYPE /= "Lattice") generate
            FIFO_U : entity work.fifo_cc
            generic map(
               DATA_WIDTH => NUM_BITS_G,
               DEPTH      => 8,
               RAM_TYPE   => "distributed"
            )
            port map(
               clk   => clk,
               rst   => rst,
               din   => RxByteArr(i),      -- rxByte
               wen   => RxByteValidArr(i), -- rxValid
               ren   => RxFifoREnArr(i),   -- inFifoREnArr
               dout  => RxFifoDoutArr(i),  -- inBytesArr
               empty => RxFifoEmptyArr(i), -- inFifoEmptyArr
               full  => RxFifoFullArr(i)   -- debug
            );
         end generate;

   end generate GEN_TXRX;
   ------------------------------------------------------------

   TxReadyOr <= '1' when TxByteReadyArr = "1111" else '0';
   parseDataReady   <= TxReadyOr;

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

      -- FIFO data from the Rx port
      inBytesArr     => RxFifoDoutArr,   -- input bytesArr from fifo
      inFifoEmptyArr => RxFifoEmptyArr,  -- input emptyArr from fifo
      inFifoREnArr   => RxFifoREnArr,    -- output enArr to fifo

      -- Tx Endeavor connections
      outBytesArr      => TxByteArr,       -- output
      outBytesValidArr => TxByteValidArr,  -- output
      txReady          => parseDataReady,  -- input

      -- data to route
      parseDataTx => parseDataTx,           -- output
      parseDataRx => parseDataRx,           -- input

      -- regFile configurations
      qpixConf => qpixConf,             -- input
      regData => regData,               -- output
      regResp => regResp                -- input
   );
   ------------------------------------------------------------

end behav;
