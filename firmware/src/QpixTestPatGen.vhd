----------------------------------------------------------------------------------
-- Test pattern generator
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.QpixPkg.all;

entity QpixTestPatGen is
   generic (
      X_POS_G : natural := 0;
      Y_POS_G : natural := 0
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;

      outData  : out QpixDataFormatType
      
   );
end entity QpixTestPatGen;


architecture behav of QpixTestPatGen is

   signal data : QPixDataFormatType := QpixDataZero_C;
   signal cnt  : std_logic_vector(15 downto 0) := (others => '0');

begin

   process (clk)
   begin
      if rising_edge (clk) then
         --cnt <= cnt + '1';
         --data.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
         --data.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
         if rst = '1' then
            data <= QpixDataZero_C;
            cnt  <= (others => '0');
         else
            cnt <= cnt + '1';
            if cnt = std_logic_vector(to_unsigned(20,16)) then
               cnt <= (others => '0');
               data.DataValid <= '1';
               data.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
               data.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
               data.TimeStamp <= (others => '0');
            else
               data <= QpixDataZero_C;
            end if;

         end if;
         
      end if;
   end process;

   outData <= data;

end behav;
