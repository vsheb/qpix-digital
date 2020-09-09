----------------------------------------------------------------------------------
-- Registers file
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;


entity QpixRegFile is
   generic (
      REG_ADDR_BITS_G : natural := 4;
      REG_DATA_BITS_G : natural := 16
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;

      regData  : in QpixRegDataType;
      
      qpixConf : out QpixConfigType;
      qpixReq  : out QpixRequestType
      
   );
end entity QpixRegFile;

architecture behav of QpixRegFile is

   signal qpixConf_r : QpixConfigType  := QpixConfigDef_C;
   signal qpixReq_r  : QpixRequestType := QpixRequestZero_C;

   constant G_REG_INTER  : std_logic_vector(G_REG_ADDR_BITS-1 downto 0) 
      := std_logic_vector(to_unsigned(1,G_REG_ADDR_BITS));
   constant G_REG_RESET  : std_logic_vector(G_REG_ADDR_BITS-1 downto 0) 
      := std_logic_vector(to_unsigned(2,G_REG_ADDR_BITS));
   constant G_REG_SETPOS : std_logic_vector(G_REG_ADDR_BITS-1 downto 0) 
      := std_logic_vector(to_unsigned(3,G_REG_ADDR_BITS));
   constant G_REG_TIMEOUT : std_logic_vector(G_REG_ADDR_BITS-1 downto 0) 
      := std_logic_vector(to_unsigned(5,G_REG_ADDR_BITS));

begin


   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            qpixConf_r <= QpixConfigDef_C;
            qpixReq_r  <= QpixRequestZero_C;
         else
            if regData.Valid = '1' then
               case regData.Addr is
                  when x"0001" => 
                  --when G_REG_INTER => 
                     qpixReq_r.Interrogation <= '1';
                  --when G_REG_RESET   => 
                  --when G_REG_SETPOS  =>
                  when x"0002" =>
                     qpixConf_r.Timeout <= regData.Data;
                  when others =>
                     qpixConf_r <= qpixConf_r;
               end case;
            else
               qpixReq_r <= QpixRequestZero_C;
            end if;
         end if;
      end if;
   end process;

   qpixReq <= qpixReq_r;
   qpixConf <= qpixConf_r;


end behav;
