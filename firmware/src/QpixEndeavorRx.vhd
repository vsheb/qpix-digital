----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
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
      scale       : in  std_logic_vector(2 downto 0);

      bitError    : out std_logic;
      gapError    : out std_logic;
      lenError    : out std_logic;
      rxError     : out std_logic;
      rxBusy      : out std_logic; 

      -- Byte data received
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      rxByteAck   : in  std_logic;
      rx          : in  std_logic
   );
end QpixEndeavorRx;

architecture Behavioral of QpixEndeavorRx is

   type StateType is (IDLE_S, DATA_S, BIT_S, GAP_S,  FINISH_S, WAIT_FINISH_S);

   type RegType is record
      state     : StateType;
      byte      : std_logic_vector(NUM_BITS_G-1 downto 0);
      dataOut   : std_logic_vector(NUM_BITS_G-1 downto 0);
      byteValid : std_logic;
      lowCnt    : unsigned(7 downto 0);
      highCnt   : unsigned(7 downto 0);
      byteCount : unsigned(7 downto 0);
      waitCnt   : unsigned(7 downto 0);
      bitError  : std_logic;
      gapError  : std_logic;
      lenError  : std_logic;
      

   end record;
   
   constant REG_INIT_C : RegType := (
      state     => IDLE_S,
      byte      => (others => '0'),
      dataOut   => (others => '0'),
      byteValid => '0',
      lowCnt    => (others => '0'),
      highCnt   => (others => '0'),
      byteCount => (others => '0'),
      waitCnt   => (others => '0'),
      bitError  => '0',
      gapError  => '0',
      lenError  => '0'
   );

   signal zeroMax   : unsigned(7 downto 0) := (others => '0');
   signal zeroMin   : unsigned(7 downto 0) := (others => '0');
   signal oneMax    : unsigned(7 downto 0) := (others => '0');
   signal oneMin    : unsigned(7 downto 0) := (others => '0');
   signal gapMax    : unsigned(7 downto 0) := (others => '0');
   signal gapMin    : unsigned(7 downto 0) := (others => '0');
   signal finMin    : unsigned(7 downto 0) := (others => '0');

   signal scale0    : unsigned(7 downto 0);
   signal scale1    : unsigned(7 downto 0);
   signal scale2    : unsigned(7 downto 0);
   signal scale4    : unsigned(7 downto 0);
   signal scale8    : unsigned(7 downto 0);
   
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

   signal rx_q : std_logic_vector(3 downto 0);
   signal rx_r : std_logic := '0';

   attribute shreg_extract : string;
   attribute shreg_extract of rx_q : signal is "no";

   
begin

   -- Map outputs
   rxByte      <= curReg.dataOut;
   rxByteValid <= curReg.byteValid;

   bitError    <= curReg.bitError;
   gapError    <= curReg.gapError;
   lenError    <= curReg.lenError;

   rxError     <= curReg.bitError or curReg.gapError or curReg.lenError;

   process (clk)
   begin
      if rising_edge(clk) then
         scale0 <= RESIZE(unsigned(scale),scale0'length);
         scale1 <= scale0; 
         scale2 <= unsigned(scale0(scale0'left-1 downto 0)) & '0';
         scale4 <= scale0(scale0'left-2 downto 0) & B"00";
         scale8 <= scale0(scale0'left-3 downto 0) & B"000";

         zeroMin <= to_unsigned(N_ZER_MIN_G,7) + scale1; 
         zeroMax <= to_unsigned(N_ZER_MAX_G,7) + scale2; 
         oneMin  <= to_unsigned(N_ONE_MIN_G,7) + scale2;
         oneMax  <= to_unsigned(N_ONE_MAX_G,7) + scale4; 
         gapMin  <= to_unsigned(N_GAP_MIN_G,7) + scale1;
         gapMax  <= to_unsigned(N_GAP_MAX_G,7) + scale2;
         finMin  <= to_unsigned(N_FIN_MIN_G,7) + scale8;

         
      end if;
   end process;

   process (clk)
   begin
      if rising_edge (clk) then
         rx_q <= rx_q(2 downto 0) & rx;
      end if;
   end process;
   rx_r <= rx_q(3);

   -- Asynchronous state logic
   process(curReg, rx_r, rxByteAck, zeroMin, zeroMax, oneMin, oneMax, gapMin, gapMax, finMin) 
   begin
      -- Set defaults
      nxtReg <= curReg;

      if rxByteAck = '1' then
         nxtReg.byteValid <= '0';
      end if;

      if rx_r = '1' then
         nxtReg.highCnt <= curReg.highCnt + 1;
      elsif rx_r = '0' then 
         nxtReg.lowCnt  <= curReg.lowCnt + 1;
      end if;
      
      case(curReg.state) is
         when IDLE_S  =>
            nxtReg.byteCount <= (others => '0');
            nxtReg.highCnt   <= (others => '0');
            nxtReg.waitCnt   <= (others => '0');
            if rx_r = '1' then
               nxtReg.state   <= DATA_S;
               nxtReg.lowCnt  <= (others => '0');
               nxtReg.lenError  <= '0';
               nxtReg.gapError  <= '0';
               nxtReg.bitError  <= '0';
            end if;


         when DATA_S =>
            if rx_r = '0' then
               nxtReg.state <= BIT_S;
            end if;
            if curReg.highCnt > oneMax then
               nxtReg.bitError <= '1';
               nxtReg.state  <= WAIT_FINISH_S;
            end if;

         when BIT_S  =>
            if curReg.highCnt >= zeroMin and curReg.highCnt <= zeroMax then
               nxtReg.byte(to_integer(curReg.byteCount)) <= '0';
               nxtReg.state  <= GAP_S;
            elsif curReg.highCnt >= oneMin and curReg.highCnt <= oneMax then
               nxtReg.byte(to_integer(curReg.byteCount)) <= '1';
               nxtReg.state  <= GAP_S;
            else 
               -- error
               nxtReg.bitError <= '1';
               nxtReg.state  <= WAIT_FINISH_S;
            end if;

            nxtReg.byteCount <= curReg.byteCount + 1;
            
            nxtReg.highCnt <= (others => '0');


         when GAP_S =>
            if curReg.lowCnt >= finMin then
               nxtReg.state <= FINISH_S;
            end if;

            if rx_r = '1' then
               if curReg.lowCnt >= gapMin then
                  -- more bytes have been received than expected
                  if curReg.byteCount = NUM_BITS_G then
                     nxtReg.lenError <= '1';
                     nxtReg.state    <= IDLE_S;
                  else
                     nxtReg.state <= DATA_S;
                  end if;
               else
                  nxtReg.gapError <= '1';
                  nxtReg.state  <= WAIT_FINISH_S;
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
               nxtReg.lenError  <= '1';
            end if;
            nxtReg.state <= IDLE_S;

         when WAIT_FINISH_S => 
            if rx_r = '0' then
               nxtReg.waitCnt <= curReg.waitCnt + 1;
            else 
               nxtReg.waitCnt <= (others => '0');
            end if;
            if curReg.waitCnt >= finMin then
               nxtReg.state <= IDLE_S;
            end if;
            
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

   rxBusy <= '0' when curReg.state = IDLE_S else '1';


end Behavioral;

