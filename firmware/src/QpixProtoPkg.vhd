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

   constant REGMAP_CMD       : QpixProtoAddr_t := x"0A"; -- int2slv(10, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_STATUS    : QpixProtoAddr_t := x"01"; --int2slv(1, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_HITMASK   : QpixProtoAddr_t := x"02"; --int2slv(2, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TIMESTAMP : QpixProtoAddr_t := x"03"; --int2slv(3, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_EVTSIZE   : QpixProtoAddr_t := x"04"; --int2slv(4, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_TRGTIME   : QpixProtoAddr_t := x"05"; --int2slv(5, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_CHANMASK  : QpixProtoAddr_t := x"06"; --int2slv(6, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_ASICMASK  : QpixProtoAddr_t := x"07"; --int2slv(7, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_FRAMEERR  : QpixProtoAddr_t := x"08"; --int2slv(8, G_QPIXPROTO_ADDR_BITS);
   constant REGMAP_BREAKERR  : QpixProtoAddr_t := x"09"; --int2slv(9, G_QPIXPROTO_ADDR_BITS);

   constant REGMAP_TESTOUT_H : QpixProtoAddr_t := x"0b";
   constant REGMAP_TESTOUT_L : QpixProtoAddr_t := x"0c";
   constant REGMAP_TESTIN_H  : QpixProtoAddr_t := x"0d";
   constant REGMAP_TESTIN_L  : QpixProtoAddr_t := x"0e";

   subtype SUBADDR_RANGE is natural range 21 downto 18;


end package;

package body QpixProtoPkg is 
end package body QpixProtoPkg;
