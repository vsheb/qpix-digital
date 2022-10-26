----------------------------------------------------------------------------------
-- DCompany: 

-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity QpixEndeavorTx is
   generic (
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time := 1 ns;
      N_ZER_CLK_G  : natural := 8;
      N_ONE_CLK_G  : natural := 24;
      N_GAP_CLK_G  : natural := 16;
      N_FIN_CLK_G  : natural := 40
   );
   port (
      -- Clock and reset
      clk         : in  std_logic;
      sRst        : in  std_logic;
      scale       : in  std_logic_vector(2 downto 0);
      disable     : in  std_logic;

      -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
      txByteReady : out std_logic;
      -- Byte data to send out
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0);
      txByteValid : in  std_logic;
      -- UART serial signal out
      tx          : out std_logic
   );
end QpixEndeavorTx;

architecture Behavioral of QpixEndeavorTx is

   signal zeroNum   : unsigned(7 downto 0) := (others => '0');
   signal oneNum    : unsigned(7 downto 0) := (others => '0');
   signal gapNum    : unsigned(7 downto 0) := (others => '0');
   signal finNum    : unsigned(7 downto 0) := (others => '0');

   signal scale0    : unsigned(7 downto 0);
   signal scale1    : unsigned(7 downto 0);
   signal scale15   : unsigned(7 downto 0);
   signal scale2    : unsigned(7 downto 0);
   signal scale3    : unsigned(7 downto 0);
   signal scale4    : unsigned(7 downto 0);
   signal scale8    : unsigned(7 downto 0);


   type StateType is (IDLE_S, DATA_S, GAP_S, FINISH_S);

   type RegType is record
      state     : StateType;
      byte      : std_logic_vector(NUM_BITS_G-1 downto 0);
      counter   : unsigned(integer(ceil(log2(real(NUM_BITS_G))))-1 downto 0);
      phase     : unsigned(7 downto 0);
      phase_max : unsigned(7 downto 0);
      tx        : std_logic;
      ready     : std_logic;
      Disable   : std_logic;
   end record;
   
   constant REG_INIT_C : RegType := (
      state      => IDLE_S,
      byte       => (others => '0'),
      counter    => (others => '0'),
      phase      => (others => '0'),
      phase_max  => (others => '0'),
      tx         => '0', 
      ready      => '0',
      Disable     => '0'
   );
   
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

begin

   process (clk)
   begin
      if rising_edge(clk) then
         scale0  <= RESIZE(unsigned(scale),scale0'length);
         scale1  <= scale0; 
         scale2  <= unsigned(scale0(scale0'left-1 downto 0)) & '0';
         scale3  <= scale1 + scale2;
         scale15 <= '0' & scale3(scale3'left downto 1);
         scale4  <= scale0(scale0'left-2 downto 0) & B"00";
         scale8  <= scale0(scale0'left-3 downto 0) & B"000";

         zeroNum <= to_unsigned(N_ZER_CLK_G-1, 7) + scale15; 
         oneNum  <= to_unsigned(N_ONE_CLK_G-1, 7) + scale3;
         gapNum  <= to_unsigned(N_GAP_CLK_G-1, 7) + scale15;
         finNum  <= to_unsigned(N_FIN_CLK_G-1, 7) + scale8;

         
      end if;
   end process;

   -- Asynchronous state logic
   process(curReg, txByteValid, txByte, zeroNum, oneNum, gapNum, finNum, disable) begin
      -- Set defaults
      nxtReg         <= curReg;
      nxtReg.ready   <= '0';
      nxtReg.phase   <= curReg.phase + 1;
      nxtReg.tx      <= '0';
      nxtReg.Disable <= disable;
      -- Actual state definitions
      case(curReg.state) is
         when IDLE_S  =>
            nxtReg.ready <= '1';
            nxtReg.counter      <= (others => '0');
            nxtReg.phase        <= (others => '0');
            if txByteValid = '1' and curReg.Disable = '0' then
               nxtReg.ready     <= '0';
               nxtReg.byte      <= txByte;
               nxtReg.state     <= DATA_S;
               if txByte(to_integer(curReg.counter)) = '1' then 
                  nxtReg.phase_max <= oneNum;
               else
                  nxtReg.phase_max <= zeroNum;
               end if;
            end if;

         when DATA_S  => 
            nxtReg.tx <= '1';

            if curReg.phase = curReg.phase_max then
               nxtReg.phase   <= (others => '0');
               if to_integer(curReg.counter) = NUM_BITS_G-1 then
                  nxtReg.state <= FINISH_S;
               else
                  nxtReg.state   <= GAP_S;
                  nxtReg.counter <= curReg.counter + 1;
               end if;
            end if;

         when GAP_S => 
            nxtReg.tx <= '0';
            if to_integer(curReg.phase) = gapNum then
               if txByte(to_integer(curReg.counter)) = '1' then 
                  nxtReg.phase_max <= oneNum;
               else
                  nxtReg.phase_max <= zeroNum;
               end if;
               nxtReg.state      <= DATA_S;
               nxtReg.phase      <= (others => '0');
            end if;

         when FINISH_S  =>
            nxtReg.tx <= '0';
            if to_integer(curReg.phase) = finNum then
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

   process (clk)
   begin
      if rising_edge (clk) then
         tx <= curReg.tx;
      end if;
   end process;

   txByteReady <= curReg.ready;


end Behavioral;

