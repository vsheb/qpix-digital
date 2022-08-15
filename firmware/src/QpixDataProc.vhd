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
      -- true "analog" data in
      inPorts  : in  QpixInPortsType;     
      -- QpixDataRoute
      ena      : in  std_logic;
      testEna  : in  std_logic; 
      outData  : out QpixDataFormatType      
   );
end entity QpixDataProc;
----------------------------------------------------------------------------------

architecture behav of QpixDataProc is

   signal testData  : QPixDataFormatType := QpixDataZero_C;
   signal inData_r  : QPixDataFormatType := QpixDataZero_C;
   signal inData_2r : QPixDataFormatType := QpixDataZero_C;

   attribute shreg_extract : string;
   attribute shreg_extract of inData_r : signal is "no";
   attribute shreg_extract of inData_2r : signal is "no";

begin

--   ----------------------------------------------------------------------------------
--   -- Test pattern generator
--   ----------------------------------------------------------------------------------
--   QpixTestPatGen_U : entity work.QpixTestPatGen 
--   generic map(
--      X_POS_G => X_POS_G,
--      Y_POS_G => Y_POS_G
--   )
--   port map (
--      clk => clk,
--      rst => rst,

--      outData => testData
--   );  --- NOT USED FOR NOW
--   ----------------------------------------------------------------------------------

   ----------------------------------------------------------------------------------
   -- Format the data
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         inData_r.DataValid <= inPorts.Valid;
         inData_r.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
         inData_r.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
         inData_r.TimeStamp <= inPorts.TimeStamp;
         inData_r.ChanMask  <= inPorts.ChanMask;
         inData_2r <= inData_r;
      end if;
   end process;
   ----------------------------------------------------------------------------------

   ----------------------------------------------------------------------------------
   -- Mux between input and test pattern data
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if ena = '1' then
            outData <= inData_2r;
         else
            outData <= QpixDataZero_C;
         end if;        
      end if;
   end process;
   ----------------------------------------------------------------------------------

end behav;