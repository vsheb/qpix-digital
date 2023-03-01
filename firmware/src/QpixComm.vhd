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
      TXRX_TYPE      : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"
      N_ZER_CLK_G    : natural :=  8;  
      N_ONE_CLK_G    : natural :=  24; 
      N_GAP_CLK_G    : natural :=  16; 
      N_FIN_CLK_G    : natural :=  40; 
                                       
      N_ZER_MIN_G    : natural :=  4;  
      N_ZER_MAX_G    : natural :=  12; 
      N_ONE_MIN_G    : natural :=  16; 
      N_ONE_MAX_G    : natural :=  32; 
      N_GAP_MIN_G    : natural :=  8;  
      N_GAP_MAX_G    : natural :=  32; 
      N_FIN_MIN_G    : natural :=  32  

   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;

      EndeavorScale  : in std_logic_vector(2 downto 0);
      qpixConf       : in QpixConfigType;
      fifoFull       : in std_logic;

      TxRxDisable    : in  std_logic_vector(3 downto 0) := (others => '0');
      outData_i      : in  QpixDataFormatType;
      inData         : out QpixDataFormatType;

      regData        : out QpixRegDataType;
      regResp        : in QpixRegDataType;

      TxReady        : out std_logic;
      -- external ASIC ports
      TxPortsArr     : out QpixTxRxPortsArrType;

      RxPortsArr     : in  QpixTxRxPortsArrType;
      RxBusy         : out std_logic;
      RxError        : out std_logic;
      RxValidDbg     : out std_logic

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
   signal RxBytesAck       : std_logic_vector(3 downto 0);
   signal RxBytesValid     : std_logic_vector(3 downto 0);
   signal RxBusyArr        : std_logic_vector(3 downto 0);
   signal RxErrorArr       : std_logic_vector(3 downto 0);

   signal TxReadyMask        : std_logic;

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
            rxByteValid => RxBytesValid(i),
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
               clk          => clk,
               sRst         => rst,

               scale        => EndeavorScale,
               TxRxDisable  => TxRxDisable(i),
                            
               txByte       => TxByteArr(i), 
               txByteValid  => TxByteValidArr(i), 
               txByteReady  => TxByteReadyArr(i),

               rxByte       => RxByteArr(i),
               rxByteValid  => RxBytesValid(i),
               RxByteAck    => RxBytesAck(i),
               rxBusy       => RxBusyArr(i),
               rxError      => RxErrorArr(i),

               Rx           => RxPortsArr(i),
               Tx           => TxPortsArr(i)
            );
      end generate ENDEAROV_GEN;
   end generate GEN_TXRX;
   ------------------------------------------------------------

   process (clk)
   begin
      if rising_edge(clk) then
         if RxBytesValid /= b"0000" then
            RxValidDbg <= '1';
         else
            RxValidDbg <= '0';
         end if;
      end if;
   end process;

   RxBusy  <= '0' when RxBusyArr  = b"0000" else '1';
   RxError <= '0' when RxErrorArr = b"0000" else '1';

   process (qpixConf.DirMask, TxByteReadyArr)
   begin
         if (qpixConf.DirMask and TxByteReadyArr) = qpixConf.DirMask then
            TxReadyMask <= '1';
         else
            TxReadyMask <= '0';
         end if;
   end process;
   TxReady <= TxReadyMask;

   ------------------------------------------------------------
   -- Parser
   ------------------------------------------------------------
   QpixParser_U : entity work.QpixParser
   port map(
      clk          => clk,
      rst          => rst,

      qpixConf          => qpixConf,
      fifoFull          => fifoFull,

      inBytesArr        => RxByteArr,
      inBytesValid      => RxBytesValid,
      inBytesAck        => RxBytesAck,
      inData            => inData,
                        
      outData           => outData_i,
      outBytesArr       => TxByteArr,
      outBytesValidArr  => TxByteValidArr,
      txReady           => TxReadyMask,

      regData           => regData,
      regResp           => regResp

   );
   ------------------------------------------------------------

  

end behav;



