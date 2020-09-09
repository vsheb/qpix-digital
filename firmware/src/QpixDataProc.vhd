----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;


----------------------------------------------------------------------------------
entity QpixDataProc is
   generic (
      X_POS_G : natural := 0;
      Y_POS_G : natural := 0
   );
   port (
      clk      : in  std_logic;
      rst      : in  std_logic;

      testEna  : in  std_logic; 

      inPorts  : in  QpixInPortsType;
      outData  : out QpixDataFormatType
      
   );
end entity QpixDataProc;
----------------------------------------------------------------------------------


architecture behav of QpixDataProc is

   signal testData : QPixDataFormatType := QpixDataZero_C;
   signal inData   : QPixDataFormatType := QpixDataZero_C;

begin

   ----------------------------------------------------------------------------------
   -- Test pattern generator
   ----------------------------------------------------------------------------------
   QpixTestPatGen_U : entity work.QpixTestPatGen 
   generic map(
      X_POS_G => X_POS_G,
      Y_POS_G => Y_POS_G
   )
   port map (
      clk => clk,
      rst => rst,

      outData => testData
   );
   ----------------------------------------------------------------------------------

   ----------------------------------------------------------------------------------
   -- Format the data
   ----------------------------------------------------------------------------------
   inData.DataValid <= inPorts.Valid;
   inData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
   inData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
   inData.TimeStamp <= inPorts.TimeStamp;
   ----------------------------------------------------------------------------------

   ----------------------------------------------------------------------------------
   -- Mux between input and test pattern data
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         --if testEna = '1' then
         --if X_POS_G = 7 and Y_POS_G = 7 then
            --outData <= testData;
         --else
            --outData <= inData;
         --end if;
         outData <= inData;
         
      end if;
   end process;
   ----------------------------------------------------------------------------------



end behav;
