----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
--use IEEE.math_real."ceil";
--use IEEE.math_real."log2";

entity QpixEndeavorRx is
   generic (
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time    := 1 ns;
      N_ZER_MIN_G  : natural := 4;
      N_ZER_MAX_G  : natural := 12;
      N_ONE_MIN_G  : natural := 16;
      N_ONE_MAX_G  : natural := 32;
      N_GAP_MIN_G  : natural := 8;
      N_GAP_MAX_G  : natural := 32;
      N_FIN_MIN_G  : natural := 32
   );
   port (
      -- Clock and reset
      clk         : in  std_logic;
      sRst        : in  std_logic;

      bitError    : out std_logic;
      gapError    : out std_logic;
      lenError    : out std_logic;

      -- Byte data received
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      rxState     : out std_logic_vector(2 downto 0);
      rx          : in  std_logic
   );
end QpixEndeavorRx;

architecture Behavioral of QpixEndeavorRx is

   type StateType is (IDLE_S, DATA_S, BIT_S, GAP_S,  FINISH_S);

   type RegType is record
      state     : StateType;
      byte      : std_logic_vector(NUM_BITS_G-1 downto 0);
      dataOut   : std_logic_vector(NUM_BITS_G-1 downto 0);
      byteValid : std_logic;
      lowCnt    : unsigned(7 downto 0);
      highCnt   : unsigned(7 downto 0);
      byteCount : unsigned(7 downto 0);
      bitError  : std_logic;
      gapError  : std_logic;
      lenError  : std_logic;
   end record;
   
   constant REG_INIT_C : RegType := (
      state     => IDLE_S,
      byte      => (others => '0'),
      dataOut   => (others => '0'),
      byteValid => '0',
      lowCnt  => (others => '0'),
      highCnt  => (others => '0'),
      byteCount => (others => '0'),
      bitError  => '0',
      gapError  => '0',
      lenError  => '0'
   );
   
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

   signal rx_q : std_logic_vector(3 downto 0);
   signal rx_r : std_logic := '0';

   attribute shreg_extract : string;
   attribute shreg_extract of rx_q : signal is "no";

   
begin

   -- Map to outputs
   rxByte      <= curReg.dataOut;
   rxByteValid <= curReg.byteValid;
   bitError    <= curReg.bitError;
   gapError    <= curReg.gapError;
   lenError    <= curReg.lenError;

   with curReg.state select rxState <=
        "000" when IDLE_S,   -- off
        "000" when DATA_S,   -- off (was red, confirmed to be working and only visible one)
        "010" when BIT_S,    -- blue
        "100" when GAP_S,    -- green
        "001" when FINISH_S, -- off
        "000" when others;   -- off

   process (clk)
   begin
      if rising_edge (clk) then
         rx_q <= rx_q(2 downto 0) & rx;
      end if;
   end process;
   rx_r <= rx_q(3);

   -- Asynchronous state logic
   process(curReg, rx_r) 
   begin
      -- Set defaults
      nxtReg <= curReg;

      -- Default strobe signals are '0'
      nxtReg.byteValid <= '0';
      nxtReg.bitError  <= '0';
      --nxtReg.gapError  <= '0';
      --nxtReg.lenError  <= '0';

      if rx_r = '1' then
         nxtReg.highCnt <= curReg.highCnt + 1;
      elsif rx_r = '0' then 
         nxtReg.lowCnt  <= curReg.lowCnt + 1;
      end if;
      
      case(curReg.state) is
         when IDLE_S  =>
            nxtReg.byteCount <= (others => '0');
            nxtReg.highCnt   <= (others => '0');
            if rx_r = '1' then
               nxtReg.state   <= DATA_S;
               nxtReg.lowCnt  <= (others => '0');
            end if;

         when DATA_S =>
            if rx_r = '0' then
               nxtReg.state <= BIT_S;
            end if;

         when BIT_S  =>
            if curReg.highCnt >= N_ZER_MIN_G and curReg.highCnt <= N_ZER_MAX_G then
               nxtReg.byte(to_integer(curReg.byteCount)) <= '0';
               nxtReg.state  <= GAP_S;
            elsif curReg.highCnt >= N_ONE_MIN_G and curReg.highCnt <= N_ONE_MAX_G then
               nxtReg.byte(to_integer(curReg.byteCount)) <= '1';
               nxtReg.state  <= GAP_S;
            else -- error
               nxtReg.bitError <= '1';
               nxtReg.state  <= IDLE_S;
            end if;
            nxtReg.byteCount <= curReg.byteCount + 1;           
            nxtReg.highCnt <= (others => '0');

         when GAP_S =>

            if curReg.lowCnt >= N_FIN_MIN_G then
               nxtReg.state <= FINISH_S;
            end if;

            if rx_r = '1' then
               if curReg.lowCnt >= N_GAP_MIN_G then
                  nxtReg.state <= DATA_S;
               else
                  nxtReg.gapError <= '1';
                  nxtReg.state  <= IDLE_S;
               end if;
               nxtReg.lowCnt <= (others => '0');
            end if;

         when FINISH_S  =>
            if to_integer(curReg.byteCount) = NUM_BITS_G then
               nxtReg.dataOut   <= curReg.byte;
               nxtReg.byteValid <= '1';
               nxtReg.lenError  <= '0';
               nxtReg.gapError  <= '0';
            else 
               -- temporarily send a bad byte just to see what we're reading if we've made it this far
               --nxtReg.byteValid <= '1';
               nxtReg.lenError  <= '1';
            end if;
            nxtReg.state <= IDLE_S;
         when others  =>
            nxtReg.state <= IDLE_S;

      end case;         
   end process;
   
   -- Synchronous part of state machine, including reset
   process(clk) begin
      if rising_edge(clk) then
         if (sRst = '1') then
            curReg <= REG_INIT_C after GATE_DELAY_G;
         else
            curReg <= nxtReg after GATE_DELAY_G;
         end if;
      end if;
   end process;


end Behavioral;

