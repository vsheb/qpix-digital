library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;

--library UNISIM;               
--use UNISIM.VComponents.all;   

entity QpixAsicArray is
   generic (
      TXRX_TYPE      : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"
      X_NUM_G        : natural := 3;
      Y_NUM_G        : natural := 3
      
   );
   port (
      --clk         : in std_logic;
      clkVec      : in std_logic_vector(X_NUM_G*Y_NUM_G - 1 downto 0);
      rst         : in std_logic;

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

   YTxArr(0,0) <= daqTx;
   daqRx <= YRxArr(0,0);



   GEN_X : for i in 0 to X_NUM_G-1 generate
      GEN_Y : for j in 0 to Y_NUM_G-1 generate
         QpixAsicTop_U : entity work.QpixAsicTop
            generic map (
               TXRX_TYPE     => TXRX_TYPE,
               X_POS_G       => i,
               Y_POS_G       => j
            )
            port map(
               --clk      => clk,
               clk      => clkVec(j*X_NUM_G + i),
               rst      => rst,
               inPorts  => inPortsArr(i,j),

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

   --process (clk)
      --variable s  : std_logic := '0';
      --variable st : std_logic := '0';
   --begin
      --if rising_edge(clk) then
         --for i in 0 to X_NUM_G-1 loop
            --for j in 0 to Y_NUM_G-1 loop
               --if StatesArr(i)(j) > 0 then
                  --st := '1';
               --else
                  --st := '0';
               --end if;
               --s := s or st;
            --end loop;
         --end loop;
         --led(0) <= s;
      --end if;
   --end process;
   --led(1) <= '0';
   --led(2) <= '0';
   --led(3) <= '1';


end behav;
