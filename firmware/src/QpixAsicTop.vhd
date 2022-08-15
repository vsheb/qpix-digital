library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


use work.QpixPkg.all;

entity QpixAsicTop is
   generic (

      X_POS_G        : natural := 0;
      Y_POS_G        : natural := 0;
      TXRX_TYPE      : string  := "ENDEAVOR" -- "DUMMY"/"UART"/"ENDEAVOR"
   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;
      
      -- timestamp data from QpixAnalog
      inPorts        : in   QpixInPortsType;

      -- TX ports to neighbour ASICs
      TxPortsArr     : out  QpixTxRxPortsArrType;

      -- RX ports to neighbour ASICs
      RxPortsArr     : in  QpixTxRxPortsArrType
   );
end entity QpixAsicTop;

architecture behav of QpixAsicTop is
   
   ---------------------------------------------------
   -- Signals
   ---------------------------------------------------
   signal inData       : QpixDataFormatType := QpixDataZero_C;
   signal txData       : QpixDataFormatType := QpixDataZero_C;
   signal rxData       : QpixDataFormatType := QpixDataZero_C;
                      
   signal regData      : QpixRegDataType    := QpixRegDataZero_C;
   signal regResp              : QpixRegDataType  := QpixRegDataZero_C;
                      
   signal qpixConf     : QpixConfigType     := QpixConfigDef_C;
   signal qpixReq      : QpixRequestType    := QpixRequestZero_C;
                      
   signal TxReady      : std_logic          := '0';

   signal localDataEna : std_logic := '0';

   signal asicRst      : std_logic := '0';

   ---------------------------------------------------

begin
   
   ---------------------------------------------------
   -- Process ASIC internal data with defined format
   ---------------------------------------------------
   QpixDataProc_U : entity work.QpixDataProc
   generic map(
      X_POS_G         => X_POS_G,
      Y_POS_G         => Y_POS_G,
      N_ANALOG_CHAN_G => G_N_ANALOG_CHAN
   )
   port map(
      clk     => clk,
      rst     => asicRst,

      ena     => localDataEna,

      testEna => '0',

      qpixRstPulses => inPorts,
      --inPorts => inPorts,
      outData => inData

   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Q-Pix data tranceiver
   -- data parsing / physical layer
   ---------------------------------------------------
   QpixComm_U : entity work.QpixComm
   generic map(
      TXRX_TYPE     => TXRX_TYPE,
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G
   )                
   port map(
      clk => clk,
      rst => asicRst,

      outData_i      => txData,
      inData         => rxData,
      --regData        => regData,

      TxReady        => TxReady,
      TxPortsArr     => TxPortsArr,
                                     
      RxPortsArr     => RxPortsArr,

      regData        => regData,
      regResp        => regResp
      

   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Registers file
   ---------------------------------------------------
   QpixRegFile_U : entity work.QpixRegFile 
   generic map(
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G
   )                
   port map(
      clk      => clk,
      rst      => asicRst,

      regData  => regData,
      regResp  => regResp,

      QpixConf => QpixConf,
      QpixReq  => QpixReq
   );

   asicRst <= QpixReq.AsicReset or rst;
   ---------------------------------------------------


   ---------------------------------------------------
   -- Data routing between ASICs
   ---------------------------------------------------
   QpixRoute_U : entity work.QpixRoute
   generic map(
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G
   )                
   port map(        
      clk           => clk,
      rst           => AsicRst,
                    
      qpixReq       => QpixReq,
      qpixConf      => QpixConf,
                    
      inData        => inData,
      localDataEna  => localDataEna,
                    
      txReady       => TxReady,
      txData        => txData,
      rxData        => rxData,

      debug         => open
   );
   ---------------------------------------------------



end behav;
