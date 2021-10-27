library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;
use work.QpixProtoPkg.all;

library UNISIM;               
use UNISIM.VComponents.all;   

entity QpixUtilTest is
   generic (
      X_NUM_G : natural := 1;
      Y_NUM_G : natural := 1
      
   );
   port (
         
      sysClk    : in std_logic;
      led       : out std_logic_vector(3 downto 0);

      daqTx     : in QpixTxRxPortType;
      daqRx     : out  QpixTxRxPortType
      
   );
end entity QpixUtilTest;


architecture behav of QpixUtilTest is

   signal fclk : std_logic;
   signal clk  : std_logic := '0';
   signal rst  : std_logic := '0';


   signal inPortsArr  : QpixInPortsArrType(0 to X_NUM_G-1, 0 to Y_NUM_G-1);

   --signal daqTx       : QpixTxRxPortType := QpixTxRxPortZero_C;
   --signal daqRx       : QpixTxRxPortType := QpixTxRxPortZero_C;

   signal hitMask     : Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1) := (others => (others => '0')) ;

   signal trg         : std_logic := '0';
   --signal hitXY       : std_logic_vector (31 downto 0) := (others => '0');
   signal timestamp    : std_logic_vector (G_TIMESTAMP_BITS-1 downto 0) := (others => '0');
   signal trgTime      : std_logic_vector (31 downto 0) := (others => '0');

   signal evtSize     : std_logic_vector (31 downto 0) := (others => '0');

   signal memAddrRst  : std_logic := '0';
   signal memRdAddr   : std_logic_vector (G_QPIX_PROTO_MEM_DEPTH-1+1 downto 0) := (others => '0');
   signal memDataOut  : std_logic_vector (31 downto 0) := (others => '0');
   signal memRdAck    : std_logic := '0';
   signal memRdReq    : std_logic := '0';
   signal memEvtSize  : std_logic_vector (G_QPIX_PROTO_MEM_DEPTH-1 downto 0) := (others => '0');

   signal qpixDebugArr : QpixDebug2DArrayType(0 to X_NUM_G-1, 0 to Y_NUM_G-1);

   signal extFifoMaxArr : Slv4b2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1);


begin
   ---------------------------------------------------
   -- 125 MHz clock
   ---------------------------------------------------
   bufg_u : BUFG 
      port map ( I => sysClk, O => clk);
   ---------------------------------------------------


   ---------------------------------------------------
   -- ASICs array
   ---------------------------------------------------
   QpixAsicArray_U : entity work.QpixAsicArray
      generic map(
         X_NUM_G => X_NUM_G,
         Y_NUM_G => Y_NUM_G
      )
      port map (
         clk        => clk,
         rst        => rst,

         led        => led,

         daqTx      => daqTx,
         daqRx      => daqRx,
         
         inPortsArr => inPortsArr,
         debug      => qpixDebugArr
         
      );
   ---------------------------------------------------



end behav;

