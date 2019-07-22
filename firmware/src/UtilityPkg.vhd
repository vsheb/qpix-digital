-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : UtilityPkg.vhd
-- Author     : Kurtis Nishimura 
-------------------------------------------------------------------------------
-- Description: A set of common useful definitions.  Some of these ideas
--              originate from Ben Reese @ SLAC and his StdRtlPkg.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package UtilityPkg is
   
   -- Shorthand names for common types
   subtype sl is std_logic;
   subtype slv is std_logic_vector;
   -- Useful array types
   type Word2Array    is array (natural range <>) of slv( 1 downto 0);
   type Word4Array    is array (natural range <>) of slv( 3 downto 0);
   type Word5Array    is array (natural range <>) of slv( 4 downto 0);
   type Word6Array    is array (natural range <>) of slv( 5 downto 0);
   type Word8Array    is array (natural range <>) of slv( 7 downto 0);
   type Word9Array    is array (natural range <>) of slv( 8 downto 0);
   type Word10Array   is array (natural range <>) of slv( 9 downto 0);
   type Word11Array   is array (natural range <>) of slv(10 downto 0);
   type Word12Array   is array (natural range <>) of slv(11 downto 0);
   type Word13Array   is array (natural range <>) of slv(12 downto 0);
   type Word14Array   is array (natural range <>) of slv(13 downto 0);
   type Word16Array   is array (natural range <>) of slv(15 downto 0);
   type Word32Array   is array (natural range <>) of slv(31 downto 0);
   type Word48Array   is array (natural range <>) of slv(47 downto 0);
   type Word64Array   is array (natural range <>) of slv(63 downto 0);
   type Word192Array  is array (natural range <>) of slv(191 downto 0);
   type Word448Array  is array (natural range <>) of slv(447 downto 0);
   type Word1536Array is array (natural range <>) of slv(1535 downto 0);
   type BoolArray is array(natural range <>) of boolean;
   -- The simulator seems to hate this...
   --type IntArray is array(natural range <>) of integer;

   -----------------------
   -- Function prototypes
   -----------------------
   -- Grab 1 byte of an input SLV
   function getByte (byteNum : integer; input : slv) return slv;
   -- Conditional selection of constants
   function sel (conditional : boolean; if_true : natural; if_false : natural) return natural;
   -- Count number of 1's in a std_logic_vector
   function countOnes (input : slv) return integer;
   -- Sum up number of bytes
   function sumBytes (input : Word8Array) return integer;
   -- Sum up an array of 2-byte inputs
   function sum2Bytes (input : Word16Array) return integer;
   -- Endian reverse an input slv
   --function endianReverse (inData : slv) return slv;
   
end UtilityPkg;

package body UtilityPkg is

   function getByte (byteNum : integer; input : slv) return slv is 
      variable retVar : slv(7 downto 0) := (others => '0');
   begin
      -- Make sure that we're not looking out of range of the input
      assert(byteNum*8 <= input'length and byteNum >= 0) report "Byte number is out of range!" severity failure;
      -- Calculate the byte we want
      retVar := input(8*byteNum+7 downto 8*byteNum);
      return retVar;      
   end function;

   function sel (conditional : boolean; if_true : natural; if_false : natural) return natural is
   begin
      if (conditional = true) then 
         return(if_true);
      else 
         return(if_false);
      end if;
   end function;
   
   function countOnes (input : slv) return integer is
      variable retVal : integer := 0;
   begin
     for i in input'range loop
       if 
         input(i) = '1' then retVal := retVal + 1; 
       end if;
     end loop;
     return retVal;
   end function;
   
   function sumBytes (input : Word8Array) return integer is
      variable retVal : integer := 0;
   begin
      for i in input'range loop
         retVal := retVal + conv_integer(input(i));
      end loop;
      return retVal;
   end function;
   
   function sum2Bytes (input : Word16Array) return integer is
      variable retVal : integer := 0;
   begin
      for i in input'range loop
         retVal := retVal + conv_integer(input(i));
      end loop;
      return retVal;
   end function;
   
--This function is not working at the moment...   
--   function endianReverse (inData : slv) return slv is
--      variable reversedVal : slv(inData'left downto 0);
--      variable nBytes : integer := 0;
--   begin
--      assert(inData'left+1 mod 8 = 0) report "Not an even number of bytes in endianReverse!" severity failure;
--      nBytes := inData'left+1 / 8;
--      assert(nBytes > 0) report "Not even a single byte in endianReverse!" severity failure;
--      for i in 0 to nBytes-1 loop
--         reversedVal((i+1)*8-1 downto i*8) := inData(inData'left-(8*i) downto inData'left-(8*(i+1))+1);
--      end loop;
--      return reversedVal;
--   end endianReverse;

end package body UtilityPkg;
