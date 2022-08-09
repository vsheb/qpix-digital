library ieee;
use ieee.std_logic_1164.all;

entity EdgeDetector is
generic(
   N_INPUT_PIPELINE : natural := 0;
   REG_OUT          : boolean := TRUE
);
port (
   clk    : in  std_logic;
   rst    : in  std_logic;
   input  : in  std_logic;
   output : out std_logic);
end EdgeDetector;

architecture rtl of EdgeDetector is
   signal input_q   : std_logic_vector(N_INPUT_PIPELINE downto 0) := (others => '0');
   signal input_r1  : std_logic := '0';
   signal input_r2  : std_logic := '0';
   signal output_i  : std_logic := '0';
   signal output_r  : std_logic := '0';
begin

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

   process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
           input_r1 <= '0';
           input_r2 <= '0';
         else 
           input_r1 <= input_q(input_q'left);
           input_r2 <= input_r1;
         end if;
      end if;
   end process;

   output_i <= not input_r2 and input_r1;
   
   GEN_OUT_REG : if REG_OUT = TRUE generate
      process (clk)
      begin
         if rising_edge (clk) then
            output_r <= output_i;
         end if;
      end process;
   end generate GEN_OUT_REG;   

   GEN_OUT_DIR : if REG_OUT = FALSE generate
      output_r <= output_i;
   end generate GEN_OUT_DIR;   

   output <= output_r;

end rtl;
----------------------------------------------


