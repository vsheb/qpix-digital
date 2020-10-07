library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

package QpixProtoPkg is
   
   constant G_QPIXPROTO_ADDR_BITS : natural := 8;
   subtype QpixProtoAddr_t is std_logic_vector(G_QPIXPROTO_ADDR_BITS-1 downto 0);

   constant G_QPIX_PROTO_MEM_DEPTH : natural := 7;

   constant REGMAP_CMD       : QpixProtoAddr_t := int2slv(10, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TEST      : QpixProtoAddr_t := int2slv(1, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_HITMASK   : QpixProtoAddr_t := int2slv(2, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TIMESTAMP : QpixProtoAddr_t := int2slv(3, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_EVTSIZE   : QpixProtoAddr_t := int2slv(4, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TRGTIME   : QpixProtoAddr_t := int2slv(5, G_QPIXPROTO_ADDR_BITS);


end package;

package body QpixProtoPkg is 
end package body QpixProtoPkg;
