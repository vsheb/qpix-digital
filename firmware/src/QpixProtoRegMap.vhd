library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;


entity QpixProtoRegMap is
   generic (
      X_NUM_G : natural := 3;
      Y_NUM_G : natural := 3
   );
   port (
      clk         : in std_logic;
      rst         : in std_logic;
      
      -- interface to AXI slave module
      addr        : in  std_logic_vector(31 downto 0);
      rdata       : out std_logic_vector(31 downto 0);
      wdata       : in  std_logic_vector(31 downto 0);
      req         : in  std_logic;
      wen         : in  std_logic;
      ack         : out std_logic;
      
      -- local interfaces
      hit_mask    : out Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1);
      trg         : out std_logic;
      
      memData     : in  std_logic_vector(31 downto 0);
      memAddr     : out std_logic_vector(31 downto 0)

   );
end entity QpixProtoRegMap;

architecture behav of QpixProtoRegMap is
   type reg_arr_t is array(0 to 15) of std_logic_vector(31 downto 0);

   signal s_addr       : std_logic_vector(31 downto 0) := (others => '0');
   alias  a_reg_addr   : std_logic_vector(3 downto 0) is s_addr(5 downto 2);
   
   signal s_reg_arr    : reg_arr_t := (others => (others => '0'));

begin

   s_addr <= addr;

   process (clk)
      variable v_reg_ind : natural := 0;
      variable iX        : natural := 0;
      variable iY        : natural := 0;
   begin
      if rising_edge (clk) then
         -- defaults
         ack     <= req;
         trg     <= '0';
         --hitXY  <= (others => '0');
         hitMask <= (others => (others => '0'));
         rdata   <= (others => '0');


         -- reg mapping
         
         if s_addr(31 downto 28) = x"0" then
            v_reg_ind := to_integer(unsigned(a_reg_addr));
            case v_reg_ind is 
               
               when REGMAP_CMD     =>
                  if wen = '1' and req = '1' and ack = '0' then
                     trg <= wdata(0);
                  end if;
               
               when REGMAP_TEST    =>
                  if wen = '1' then
                     s_reg_arr(0) <= wdata;
                  else 
                     rdata <= s_reg_arr(0);
                  end if;

               when REGMAP_HITMASK =>
                  if wen = '1' and req = '1' and ack = '0' then
                     iX := to_integer(unsigned(rdata(31 downto 16)));
                     iY := to_integer(unsigned(rdata(15 downto 0)));
                     hitMask(iX, iY) <= '1';  
                  end if;

               when others => 
                  rdata <= x"0BAD_ADD0";

            end case;
         -- event memory
         elsif s_addr(31 downto 28) = x"1" then

         end if;
         
         --if req = '1' then
            --if wen = '1' then
               --s_reg_arr(v_reg_ind) <= wdata;
            --else
               --rdata <= s_reg_arr(v_reg_ind);
            --end if;
            --ack <= '1';
         --else
            --rdata <= (others => '0');
         --end if;
      end if;
   end process;


end behav;
