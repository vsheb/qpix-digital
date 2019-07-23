library IEEE;
use IEEE.STD_LOGIC_1164.all;

package QpixPkg is

   -- Create a new type, with indexing scheme:
   --    bitArray2d(row)(col)(dir)
   --    dir decoding: 0 - right
   --                  1 - down
   --                  2 - left
   --                  3 - up
   constant RT : integer := 0;
   constant DN : integer := 1;
   constant LT : integer := 2;
   constant UP : integer := 3;
   
end QpixPkg;

package body QpixPkg is

end package body QpixPkg;
