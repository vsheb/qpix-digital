library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;

--library UNISIM;               
--use UNISIM.VComponents.all;   

entity QpixAsicArray is
   generic (
      TXRX_TYPE        : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"
      X_NUM_G          : natural := 3;
      Y_NUM_G          : natural := 3;

      X_DAQ_G          : natural := 0;
      Y_DAQ_G          : natural := 0;
      M_DAQ_G          : natural := 0;

      INDIVIDUAL_CLK_G : boolean := False;
      -- Endeavour protocol parameters
      N_ZER_CLK_G      : natural :=  8;  
      N_ONE_CLK_G      : natural :=  24; 
      N_GAP_CLK_G      : natural :=  16; 
      N_FIN_CLK_G      : natural :=  40; 
                                         
      N_ZER_MIN_G      : natural :=  4;  
      N_ZER_MAX_G      : natural :=  12; 
      N_ONE_MIN_G      : natural :=  16; 
      N_ONE_MAX_G      : natural :=  32; 
      N_GAP_MIN_G      : natural :=  8;  
      N_GAP_MAX_G      : natural :=  32; 
      N_FIN_MIN_G      : natural :=  32  
      
   );
   port (
      clk         : in std_logic;
      clkVec      : in std_logic_vector(X_NUM_G*Y_NUM_G - 1 downto 0);
      rst         : in std_logic;

      EndeavorScale : std_logic_vector(2 downto 0);

      led         : out std_logic_vector(3 downto 0); -- temporary

      daqTx       : in  QpixTxRxPortType;
      daqRx       : out QpixTxRxPortType;
      
      inPortsArr  : in  QpixInPortsArrType(0 to X_NUM_G-1, 0 to Y_NUM_G-1);
      debug       : out QpixDebug2DArrayType(0 to X_NUM_G-1, 0 to Y_NUM_G-1)
   );
end entity QpixAsicArray;


architecture behav of QpixAsicArray is

   ---------------------------------------------------
   -- type defenitions
   ---------------------------------------------------
   type AsicWireArrayType is array(0 to Y_NUM_G) of QpixTxRxPortType;
   --type AsicWire2DArrayType is array(0 to X_NUM_G) of AsicWireArrayType;
   type AsicWire2DArrayType is array(0 to X_NUM_G, 0 to Y_NUM_G) of QpixTxRxPortType;
   type RouteStatesArrType is array(0 to Y_NUM_G) of integer;
   type RouteStates2DArrType is array(0 to X_NUM_G) of RouteStatesArrType;
   ---------------------------------------------------

   signal XRxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal YRxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal XTxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal YTxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));

   signal inPorts : QpixInPortsType := QpixInPortsZero_C;

   signal StatesArr : RouteStates2DArrType;
   signal clkVec_s  : std_logic_vector(X_NUM_G*Y_NUM_G - 1 downto 0) := (others => '0');
   
   ---------------------------------------------------
   -- from left to right -- XTxArr  
   -- from right to left -- XRxArr  
   --                               
   --   ____   XTxArr(i)  ____      
   --  |  tx|----------->|rx  |      
   --  |  rx|<-----------|tx  |      
   --   ----   XRxArr(i)  ----      
   --
   ---------------------------------------------------

begin

   DAQ_NORTH : if M_DAQ_G = 0 generate
      daqRx <= YRxArr(X_DAQ_G, Y_DAQ_G);   -- up
      YTxArr(X_DAQ_G,Y_DAQ_G)   <= daqTx;   -- up 
   end generate;

   DAQ_EAST : if M_DAQ_G = 1 generate
      daqRx <= XTxArr(X_DAQ_G+1, Y_DAQ_G); -- right
      XRxArr(X_DAQ_G+1,Y_DAQ_G) <= daqTx; -- right
   end generate;

   DAQ_SOUTH : if M_DAQ_G = 2 generate
      daqRx <= YTxArr(X_DAQ_G, Y_DAQ_G+1); -- down
      YRxArr(X_DAQ_G,Y_DAQ_G+1) <= daqTx; -- down
   end generate;

   DAQ_WEST : if M_DAQ_G = 3 generate
      daqRx <= XRxArr(X_DAQ_G, Y_DAQ_G);   -- left
      XTxArr(X_DAQ_G,Y_DAQ_G)   <= daqTx;-- left
   end generate;

      --YTxArr(0,0) <= daqTx;
      --daqRx <= YRxArr(0,0);


   CLK_GEN_IND : if INDIVIDUAL_CLK_G = True generate 
      clkVec_s <= clkVec;
   end generate;

   CLK_GEN_SAME : if INDIVIDUAL_CLK_G = False generate
      clkVec_s <= (others => clk);
   end generate;


   GEN_X : for i in 0 to X_NUM_G-1 generate
      GEN_Y : for j in 0 to Y_NUM_G-1 generate
         QpixAsicTop_U : entity work.QpixAsicTop
            generic map (
               TXRX_TYPE     => TXRX_TYPE,
               X_POS_G       => i,
               Y_POS_G       => j,
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
               clk      => clkVec_s(j*X_NUM_G + i),
               rst      => rst,
               inPorts  => inPortsArr(i,j),

               EndeavorScale => EndeavorScale,

               -- TX 
               TxPortsArr(0) => YRxArr(i,j),   -- up
               TxPortsArr(1) => XTxArr(i+1,j), -- right
               TxPortsArr(2) => YTxArr(i,j+1), -- down
               TxPortsArr(3) => XRxArr(i,j),   -- left

               -- RX
               RxPortsArr(0) => YTxArr(i,j),   -- up 
               RxPortsArr(1) => XRxArr(i+1,j), -- right
               RxPortsArr(2) => YRxArr(i,j+1), -- down
               RxPortsArr(3) => XTxArr(i,j)   -- left

               --State         => StatesArr(i)(j),
               --debug         => debug(i,j)
            );
      end generate GEN_Y;
   end generate GEN_X;


end behav;
