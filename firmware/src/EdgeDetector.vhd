library ieee;
use ieee.std_logic_1164.all;

entity EdgeDetector is
generic(
   N_SYNC_G         : natural := 0;
   REG_OUT_G        : boolean := TRUE
);
port (
   clk    : in  std_logic;
   rst    : in  std_logic;
   input  : in  std_logic;
   output : out std_logic);
end EdgeDetector;

architecture rtl of EdgeDetector is
   signal input_q   : std_logic_vector(N_SYNC_G+1 downto 0) := (others => '0');
   signal output_i  : std_logic := '0';
   signal output_r  : std_logic := '0';
begin

   SYNC_GEN : if N_SYNC_G > 0 generate
      process(clk)
      begin
         if rising_edge(clk) then
            if rst = '1' then
               input_q <= (others => '0');
            else
               input_q <= input_q(input_q'left-1 downto 0) & input;
            end if;
         end if;
      end process;
   end generate;

   NOSYNC_GEN : if N_SYNC_G = 0 generate
      process(clk)
      begin
         if rising_edge(clk) then
            input_q(1) <= input;
         end if;
      end process;
      input_q(0) <= input;
   end generate;


   output_i <= not input_q(input_q'left) and input_q(input_q'left-1);
   
   GEN_OUT_REG : if REG_OUT_G = TRUE generate
      process (clk)
      begin
         if rising_edge (clk) then
            output_r <= output_i;
         end if;
      end process;
   end generate GEN_OUT_REG;   

   GEN_OUT_DIR : if REG_OUT_G = FALSE generate
      output_r <= output_i;
   end generate GEN_OUT_DIR;   

   output <= output_r;

end rtl;
----------------------------------------------


