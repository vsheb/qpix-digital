library ieee;
use ieee.std_logic_1164.all;


library work;
use work.QpixPkg.all;

entity QpixAsicTop is
   generic (
      X_POS_G        : natural := 0;
      Y_POS_G        : natural := 0
   );
   port (
      clk            : in std_logic;
      rst            : in std_logic;
      
      -- timestamp data from QpixAnalog
      inPorts        : in   QpixInPortsType;

      --Status         : out QpixStatusType;
      State          : out integer;

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
      signal inData   : QpixDataFormatType := QpixDataZero_C;
      signal txData   : QpixDataFormatType := QpixDataZero_C;
      signal rxData   : QpixDataFormatType := QpixDataZero_C;

      signal regData  : QpixRegDataType    := QpixRegDataZero_C;

      signal qpixConf : QpixConfigType     := QpixConfigDef_C;
      signal qpixReq  : QpixRequestType    := QpixRequestZero_C;

      signal TxReady  : std_logic          := '0';
   ---------------------------------------------------

begin
   
   ---------------------------------------------------
   -- Process ASIC internal data with defined format
   ---------------------------------------------------
   QpixDataProc_U : entity work.QpixDataProc
   generic map(
      X_POS_G => X_POS_G,
      Y_POS_G => Y_POS_G
   )
   port map(
      clk     => clk,
      rst     => rst,

      testEna => '0',

      inPorts => inPorts,
      outData => inData

   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Q-Pix data tranceiver
   -- data parsing / physical layer
   ---------------------------------------------------
   QpixComm_U : entity work.QpixComm
   port map(
      clk => clk,
      rst => rst,

      outData_i      => txData,
      inData         => rxData,
      regData        => regData,

      TxReady        => TxReady,
      TxPortsArr     => TxPortsArr,
                                     
      RxPortsArr     => RxPortsArr

   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Registers file
   ---------------------------------------------------
   QpixRegFile_U : entity work.QpixRegFile 
   port map(
      clk      => clk,
      rst      => rst,

      regData  => regData,

      QpixConf => QpixConf,
      QpixReq  => QpixReq
   );
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
      rst           => rst,
                    
      qpixReq       => QpixReq,
      qpixConf      => QpixConf,
                    
      inData        => inData,
                    
      txReady       => TxReady,
      txData        => txData,
      rxData        => rxData,

      routeStateInt => State
   );
   ---------------------------------------------------



end behav;
