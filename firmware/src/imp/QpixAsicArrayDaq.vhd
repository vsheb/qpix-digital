library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.QpixPkg.all;

entity QpixAsicArrayDaq is
   generic (
      TXRX_TYPE      : string  := "ENDEAVOR";
      X_NUM_G        : natural := 3;
      Y_NUM_G        : natural := 3;
      INDIVIDUAL_CLK_G : boolean := False
   );
   port (
      clk             : in std_logic;
      clkVec          : in std_logic_vector(X_NUM_G*Y_NUM_G - 1 downto 0);
      rst             : in std_logic;

      inPortsArr      : in QpixInPortsArrType(0 to X_NUM_G-1, 0 to Y_NUM_G-1);

      daqTxByte       : in std_logic_vector(G_DATA_BITS-1 downto 0);
      daqTxByteValid  : in std_logic;
      daqTxByteReady  : out std_logic;

      daqRxByte       : out  std_logic_vector(G_DATA_BITS-1 downto 0);
      daqRxByteValid  : out std_logic;
      daqRxFrameErr   : out std_logic;
      daqRxBreakErr   : out std_logic
      
   );
end entity QpixAsicArrayDaq;

architecture behav of QpixAsicArrayDaq is

   
   signal daqTx        : QpixTxRxPortType := QpixTxRxPortZero_C;
   signal daqRx        : QpixTxRxPortType := QpixTxRxPortZero_C;
   
   signal daqRxByte_s  : std_logic_vector(G_DATA_BITS-1 downto 0);
   signal xpos         : std_logic_vector(3 downto 0);
   signal ypos         : std_logic_vector(3 downto 0);

   signal daqTimestamp : unsigned(31 downto 0) := (others => '0');

begin
   ---------------------------------------------------
   -- ASICs array
   ---------------------------------------------------
   QpixAsicArray_U : entity work.QpixAsicArray
      generic map(
         TXRX_TYPE        => TXRX_TYPE,
         X_NUM_G          => X_NUM_G,
         Y_NUM_G          => Y_NUM_G,
         INDIVIDUAL_CLK_G => INDIVIDUAL_CLK_G
      )
      port map (
         clk        => clk,
         clkVec     => clkVec,
         rst        => '0', --rst,

         led        => open,

         daqTx      => daqTx,
         daqRx      => daqRx,
         
         inPortsArr => inPortsArr,
         debug      => open --qpixDebugArr
         
      );
   ---------------------------------------------------

   ENDEAVOR_GEN : if TXRX_TYPE = "ENDEAVOR" generate
      QpixUartTxRx_U : entity work.QpixEndeavorTop
      generic map (
         NUM_BITS_G => G_DATA_BITS
      )
      port map (
         clk         => clk,
         sRst        => rst,

         txByte      => daqTxByte, 
         txByteValid => daqTxByteValid, 
         txByteReady => daqTxByteReady,

         rxByte      => daqRxByte_s,
         rxByteValid => daqRxByteValid,
         rxFrameErr  => daqRxFrameErr,
         rxBreakErr  => daqRxBreakErr,

         Tx          => daqTx,
         Rx          => daqRx

      );
   end generate ENDEAVOR_GEN;

   daqRxByte <= daqRxByte_s;

   xpos <= daqRxByte_s(39 downto 36);
   ypos <= daqRxByte_s(35 downto 32);

   process (clk)
   begin
      if rising_edge(clk) then
         daqTimestamp <= daqTimestamp + 1;
      end if;
   end process;


end behav;
