library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

package QpixProtoPkg is
   
   constant G_QPIXPROTO_ADDR_BITS : natural := 8;
   subtype QpixProtoAddr_t is std_logic_vector(G_QPIXPROTO_ADDR_BITS-1 downto 0);

   constant REGMAP_CMD     : QpixProtoAddr_t := int2slv(0, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TEST    : QpixProtoAddr_t := int2slv(1, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_HITMASK : QpixProtoAddr_t := int2slv(2, G_QPIXPROTO_ADDR_BITS);

end package;

package body QpixProtoPkg is 
end package body QpixProtoPkg;
