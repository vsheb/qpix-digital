library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

package QpixProtoPkg is
   
   constant G_QPIXPROTO_ADDR_BITS : natural := 8;
   subtype QpixProtoAddr_t is std_logic_vector(G_QPIXPROTO_ADDR_BITS-1 downto 0);

   constant G_QPIX_PROTO_MEM_DEPTH : natural := 12;

   constant REGMAP_CMD       : QpixProtoAddr_t := int2slv(10, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_STATUS    : QpixProtoAddr_t := int2slv(1, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_HITMASK   : QpixProtoAddr_t := int2slv(2, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TIMESTAMP : QpixProtoAddr_t := int2slv(3, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_EVTSIZE   : QpixProtoAddr_t := int2slv(4, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TRGTIME   : QpixProtoAddr_t := int2slv(5, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_CHANMASK  : QpixProtoAddr_t := int2slv(6, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_ASICMASK  : QpixProtoAddr_t := int2slv(7, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_FRAMEERR  : QpixProtoAddr_t := int2slv(8, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_BREAKERR  : QpixProtoAddr_t := int2slv(9, G_QPIXPROTO_ADDR_BITS);

   type SUBADDR_RANGE is range 21 downto 18;


end package;

package body QpixProtoPkg is 
end package body QpixProtoPkg;
