library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


use work.QpixPkg.all;

entity QpixAsicTop is
   generic (

      X_POS_G        : natural := 0;
      Y_POS_G        : natural := 0;
      TXRX_TYPE      : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"

      N_ZER_CLK_G   : natural :=  2;
      N_ONE_CLK_G   : natural :=  5;
      N_GAP_CLK_G   : natural :=  4;
      N_FIN_CLK_G   : natural :=  7;
                                    
      N_ZER_MIN_G   : natural :=  1;
      N_ZER_MAX_G   : natural :=  3;
      N_ONE_MIN_G   : natural :=  5;
      N_ONE_MAX_G   : natural :=  7;
      N_GAP_MIN_G   : natural :=  3;
      N_GAP_MAX_G   : natural :=  5;
      N_FIN_MIN_G   : natural :=  8 

   );
   port (
      clk            : in  std_logic;
      rst            : in  std_logic;

      extInterSoft   : in  std_logic := '0';
      extInterHard   : in  std_logic := '0';
      EndeavorScale  : in  std_logic_vector(2 downto 0);
      disableDbgOut  : in  std_logic := '0';
      
      -- qpix reset pulses from QpixAnalog
      inPorts        : in  QpixInPortsType;

      -- TX ports to neighbour ASICs
      TxPortsArr     : out QpixTxRxPortsArrType;

      -- RX ports to neighbour ASICs
      RxPortsArr     : in  QpixTxRxPortsArrType; 

      -- debug outputs
      dbgRxBusy      : out std_logic;
      dbgTxBusy      : out std_logic;
      dbgRxError     : out std_logic;
      dbgLocFifoFull : out std_logic;
      dbgExtFifoFull : out std_logic;
      dbgFsmState    : out std_logic_vector(2 downto 0);
      dbgDataValid   : out std_logic
      
   );
end entity QpixAsicTop;

architecture behav of QpixAsicTop is
   
   ---------------------------------------------------
   -- Signals
   ---------------------------------------------------
   signal inData        : QpixDataFormatType := QpixDataZero_C;
   signal txData        : QpixDataFormatType := QpixDataZero_C;
   signal rxData        : QpixDataFormatType := QpixDataZero_C;
                       
   signal regData       : QpixRegDataType    := QpixRegDataZero_C;
   signal regResp       : QpixRegDataType  := QpixRegDataZero_C;
                       
   signal qpixConf      : QpixConfigType     := QpixConfigDef_C;
   signal qpixReq       : QpixRequestType    := QpixRequestZero_C;
                       
   signal TxReady       : std_logic := '0';
   signal RxBusy        : std_logic := '0';
   signal RxError       : std_logic := '0';
                        
   signal localDataEna  : std_logic := '0';
                        
   signal asicRst       : std_logic := '0';
   signal syncRst       : std_logic := '0';
                        
   signal clkCnt        : std_logic_vector(31 downto 0);
                        
   signal extFifoFull   : std_logic := '0';
   signal locFifoFull   : std_logic := '0';
   signal routeFsmState : std_logic_vector(2 downto 0);

   ---------------------------------------------------

begin
   ---------------------------------------------------
   -- Generate synchronous reset signal
   ---------------------------------------------------
   SyncReset_U : entity work.EdgeDetector
   generic map(
      N_SYNC_G => 2
   )
   port map (
      clk    => clk,
      rst    => '0',
      input  => rst,
      output => syncRst
   );

   process (clk)
   begin
      if rising_edge(clk) then
         asicRst <= QpixReq.AsicReset or SyncRst;
      end if;
   end process;
   ---------------------------------------------------

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
      clk           => clk,
      rst           => asicRst,
                    
      ena           => localDataEna,
      chanEna       => qpixConf.chanEna, 
      clkCnt        => clkCnt,
      fifoFull      => locFifoFull,

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

      -- Endeavor protocol parameters
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
   port map(
      clk            => clk,
      rst            => asicRst,

      EndeavorScale  => EndeavorScale,
      qpixConf       => qpixConf,
      fifoFull       => extFifoFull,

      outData_i      => txData,
      inData         => rxData,

      TxReady        => TxReady,
      TxPortsArr     => TxPortsArr,
                                     
      RxPortsArr     => RxPortsArr,
      RxBusy         => RxBusy,
      RxError        => RxError,

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
      clk       => clk,
      rst       => asicRst,
                
      extInterS  => extInterSoft,
      extInterH  => extInterHard,
      regData   => regData,
      regResp   => regResp,
      txReady   => TxReady,
                
      clkCnt    => clkCnt,
      QpixConf  => QpixConf,
      QpixReq   => QpixReq
   );

   ---------------------------------------------------


   ---------------------------------------------------
   -- Data routing between ASICs
   ---------------------------------------------------
   QpixRoute_U : entity work.QpixRoute
   port map(        
      clk           => clk,
      rst           => AsicRst,
                    
      clkCnt        => clkCnt,
      qpixReq       => QpixReq,
      qpixConf      => QpixConf,
                    
      inData        => inData,
      localDataEna  => localDataEna,
                    
      txReady       => TxReady,
      txData        => txData,
      rxData        => rxData,

      fsmState      => routeFsmState,
      extFifoFull   => extFifoFull,
      locFifoFull   => locFifoFull
   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- debug outputs
   ---------------------------------------------------
   process (clk)
   begin
      if rising_edge(clk) then
         if disableDbgOut = '1' then
            dbgLocFifoFull <= '0';
            dbgExtFifoFull <= '0';
            dbgFsmState    <= (others => '0');
            dbgRxBusy      <= '0';
            dbgTxBusy      <= '0';
            dbgDataValid   <= '0';
            dbgRxError     <= '0';
         else
            dbgLocFifoFull <= locFifoFull;
            dbgExtFifoFull <= extFifoFull;
            dbgFsmState    <= routeFsmState;
            dbgRxBusy      <= RxBusy;
            dbgTxBusy      <= not TxReady;
            dbgDataValid   <= rxData.DataValid or regData.Valid;
            dbgRxError     <= RxError;
         end if;
      end if;
   end process;
   ---------------------------------------------------




end behav;
