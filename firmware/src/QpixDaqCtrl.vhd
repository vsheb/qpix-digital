library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;

entity QpixDaqCtrl is
   generic (
      
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;
      
   );
end entity QpixDaqCtrl;


architecture behav of QpixDaqCtrl is

   

begin

   QpixAxiIfc_U  : entity work.QpixAxiIfc
   port map(
      clk => clk,
      rst => rst,
      
      axi_read => axi_read
      axi_write => axi_write, 

      daqByte   => daqByte,
      daqByteValid => daqByteValid

           );

   QpixDaqNode_U : entity work.QpixDaqNode
   port map(

      clk      => clk ,
      rst      => rst, 

      txByte      => daqByte,
      txByteValid => daqByteValid,

      Tx       => XTxArr(0)(0),
      Rx       => XRxArr(0)(0)
   );

   QpixDaqStorage_U : entity work.QpixDaqStorage_U
   port map(
      clk => clk,
   );

   QpixHitsGen_U : entity work.QpixHitsGen
      generic map (
         X_NUM_G => X_NUM_G,
         Y_NUM_G => Y_NUM_G
      )
      port map (
         clk      => clk,
         rst      => rst,

         hitMask  => hitMask,
         inPortsArr => inPortsArr
      );


end behav;
