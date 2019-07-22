library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UtilityPkg.all;
use work.QpixPkg.all;

entity QpixDaqHub is
   generic (
      PASS_THROUGH_G : boolean := false;
      X_POS          : natural;
      Y_POS          : natural;
      GATE_DELAY_G   : time    := 1 ns
   );
   port (
      clk          : in  std_logic;
      rst          : in  std_logic;
      rxFifoData   : in  Word64Array(3 downto 0);
      rxFifoValid  : in  std_logic_vector(3 downto 0);
      rxFifoReadEn : out std_logic_vector(3 downto 0);
      rxFifoFull   : in  std_logic_vector(3 downto 0);
      rxFifoEmpty  : in  std_logic_vector(3 downto 0);
      rxFifoOflow  : in  std_logic_vector(3 downto 0);
      txData       : out Word64Array(3 downto 0);
      txDataValid  : out std_logic_vector(3 downto 0);
      txDataReady  : in  std_logic_vector(3 downto 0)
   );
end QpixDaqHub;

architecture Behavioral of QpixDaqHub is

begin

   G_PassThroughMode : if PASS_THROUGH_G generate
      txData(LT)       <= rxFifoData(RT);
      txDataValid(LT)  <= rxFifoValid(RT) and txDataReady(LT);
      rxFifoReadEn(RT) <= rxFifoValid(RT) and txDataReady(LT);
      txData(RT)       <= rxFifoData(LT);
      txDataValid(RT)  <= rxFifoValid(LT) and txDataReady(RT);
      rxFifoReadEn(LT) <= rxFifoValid(LT) and txDataReady(RT);
      txData(UP)       <= rxFifoData(DN);
      txDataValid(UP)  <= rxFifoValid(DN) and txDataReady(UP);
      rxFifoReadEn(DN) <= rxFifoValid(DN) and txDataReady(UP);
      txData(DN)       <= rxFifoData(UP);
      txDataValid(DN)  <= rxFifoValid(UP) and txDataReady(DN);
      rxFifoReadEn(UP) <= rxFifoValid(UP) and txDataReady(DN);
   end generate;

   --G_PassThroughMode : if not(PASS_THROUGH_G) generate
   --   U_QpixCoreLogic : entity work.U_QpixCoreLogic
   --      generic map (
   --         X_POS          => X_POS, 
   --         Y_POS          => Y_POS,
   --         GATE_DELAY_G   => GATE_DELAY_G
   --      )
   --      port map (
   --         clk          => clk,         --: in  std_logic;
   --         rst          => rst,         --: in  std_logic;
   --         rxFifoData   => rxFifoData,  --: in  Word64Array(3 downto 0);
   --         rxFifoValid  => rxFifoValid, --: in  std_logic_vector(3 downto 0);
   --         rxFifoReadEn => rxFifoReadE, --: out std_logic_vector(3 downto 0);
   --         rxFifoFull   => rxFifoFull,  --: in  std_logic_vector(3 downto 0);
   --         rxFifoEmpty  => rxFifoEmpty, --: in  std_logic_vector(3 downto 0);
   --         rxFifoOflow  => rxFifoOflow, --: in  std_logic_vector(3 downto 0);
   --         txData       => txData,      --: out Word64Array(3 downto 0);
   --         txDataValid  => txDataValid, --: out std_logic_vector(3 downto 0);
   --         txDataReady  => txDataReady  --: in  std_logic_vector(3 downto 0)
   --      );
   --end generate;

end Behavioral;


