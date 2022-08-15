library ieee;
   use   ieee.std_logic_1164.all;
   use   ieee.numeric_std.all;

entity PulseShaper is
   port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      len    : in  std_logic_vector(31 downto 0) := (others => '0');
      dly    : in  std_logic_vector(31 downto 0) := (others => '0');
      din    : in  std_logic;
      dou    : out std_logic
   );
end entity PulseShaper;

architecture behav of PulseShaper is

   type fsm_states is (IDLE_S, DELAY_S, STRETCH_S); 
   signal st    : fsm_states := IDLE_S;

   signal cnt   : unsigned(31 downto 0) := (others => '0');
   signal len_r : unsigned(31 downto 0) := (others => '0');
   signal dly_r : unsigned(31 downto 0) := (others => '0');
   signal sig   : std_logic := '0';

begin
   
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            st <= IDLE_S;
         else
            sig <= '0';
            case st is 
               when IDLE_S => 
                  cnt  <= (others => '0');
                  len_r <= unsigned(len);
                  dly_r <= unsigned(dly);
                  if din = '1' then
                     if dly_r > 1 then 
                        st <= DELAY_S;
                     else
                        if len_r > x"0000" then
                           sig <= '1';
                           st <= STRETCH_S;
                        else
                           st <= IDLE_S;
                        end if;
                     end if;
                  end if;
               when DELAY_S =>
                  cnt <= cnt + 1;
                  if cnt = dly_r-2 then
                     cnt <= (others => '0');
                     if len_r > x"0000" then
                        st  <= STRETCH_S;
                        sig <= '1';
                     else
                        st  <= IDLE_S;
                     end if;
                  end if;
               when STRETCH_S => 
                  cnt <= cnt + 1;
                  sig <= '1';
                  if cnt = len_r-1 then
                     st  <= IDLE_S;
                     sig <= '0';
                  end if;
               when others =>
                  st <= IDLE_S;
            end case;
         end if;
      end if;
   end process;

   dou <= sig;

end behav;
