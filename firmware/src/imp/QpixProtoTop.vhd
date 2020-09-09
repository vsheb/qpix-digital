
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;

library UNISIM;               
use UNISIM.VComponents.all;   

entity QpixProtoTop is
   generic (
      X_NUM_G : natural := 3;
      Y_NUM_G : natural := 3
      
   );
   port (
         
      sysClk    : in std_logic;
      led       : out std_logic_vector(3 downto 0);

      -- PS ports
      DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
      DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
      DDR_cas_n : inout STD_LOGIC;
      DDR_ck_n : inout STD_LOGIC;
      DDR_ck_p : inout STD_LOGIC;
      DDR_cke : inout STD_LOGIC;
      DDR_cs_n : inout STD_LOGIC;
      DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
      DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_odt : inout STD_LOGIC;
      DDR_ras_n : inout STD_LOGIC;
      DDR_reset_n : inout STD_LOGIC;
      DDR_we_n : inout STD_LOGIC;
      FIXED_IO_ddr_vrn : inout STD_LOGIC;
      FIXED_IO_ddr_vrp : inout STD_LOGIC;
      FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
      FIXED_IO_ps_clk : inout STD_LOGIC;
      FIXED_IO_ps_porb : inout STD_LOGIC;
      FIXED_IO_ps_srstb : inout STD_LOGIC
      
   );
end entity QpixProtoTop;


architecture behav of QpixProtoTop is

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';

begin

   ---------------------------------------------------
   -- Processing system
   ---------------------------------------------------
   design_1_U : entity work.design_1_wrapper
      port map (
         DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
         DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
         DDR_cas_n => DDR_cas_n,
         DDR_ck_n => DDR_ck_n,
         DDR_ck_p => DDR_ck_p,
         DDR_cke => DDR_cke,
         DDR_cs_n => DDR_cs_n,
         DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
         DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
         DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
         DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
         DDR_odt => DDR_odt,
         DDR_ras_n => DDR_ras_n,
         DDR_reset_n => DDR_reset_n,
         DDR_we_n => DDR_we_n,
         FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
         FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
         FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
         FIXED_IO_ps_clk => FIXED_IO_ps_clk,
         FIXED_IO_ps_porb => FIXED_IO_ps_porb,
         FIXED_IO_ps_srstb => FIXED_IO_ps_srstb
      );
   ---------------------------------------------------

   ---------------------------------------------------
   -- System clock
   ---------------------------------------------------
   bufg_u : BUFG 
      port map ( I => sysClk, O => clk);
   ---------------------------------------------------

   ---------------------------------------------------
   -- ASICs array
   ---------------------------------------------------
   QpixAsicArray_U : entity work.QpixAsicArray
      generic map(
         X_NUM_G => X_NUM_G,
         Y_NUM_G => Y_NUM_G
      )
      port map (
         clk => clk,
         rst => rst,
         
         led => led
      );
   ---------------------------------------------------


end behav;
