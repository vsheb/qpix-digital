----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:05:43 01/19/2017 
-- Design Name: 
-- Module Name:    UartTx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
--use IEEE.math_real."ceil";
--use IEEE.math_real."log2";

entity UartTx is
   generic (
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time := 1 ns
   );
   port (
      -- Clock and reset
      clk         : in  std_logic;
      sRst        : in  std_logic;
      -- Baud clock, oversampled x8
      baudClkX8   : in  std_logic;
      -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
      txByteReady : out std_logic;
      -- Byte data to send out
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0);
      txByteValid : in  std_logic;
      -- UART serial signal out
      uartTx      : out std_logic
   );
end UartTx;

architecture Behavioral of UartTx is

   type StateType is (IDLE_S, START_S, DATA_S, STOP_S);

   type RegType is record
      state   : StateType;
      byte    : std_logic_vector(NUM_BITS_G-1 downto 0);
      counter : unsigned(integer(ceil(log2(real(NUM_BITS_G))))-1 downto 0);
      phase   : unsigned(2 downto 0);
   end record;
   
   constant REG_INIT_C : RegType := (
      state   => IDLE_S,
      byte    => (others => '0'),
      counter => (others => '0'),
      phase   => (others => '0')
   );
   
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

begin

   -- Asynchronous state logic
   process(curReg, txByte, txByteValid, baudClkX8) begin
      -- Set defaults
      nxtReg      <= curReg;
      txByteReady <= '0';
      -- Actual state definitions
      case(curReg.state) is
         when IDLE_S  =>
            uartTx       <= '1';
            txByteReady  <= '1';
            if (txByteValid = '1') then
               nxtReg.byte  <= txByte;
               nxtReg.phase <= (others => '0');
               nxtReg.state <= START_S;
            end if;
         when START_S =>
            uartTx       <= '0';
--            if baudClkX8 = '1' then
               nxtReg.phase <= curReg.phase + 1;
               if curReg.phase = 7 then
                  nxtReg.state <= DATA_S;
               end if;
--            end if;
         when DATA_S  =>
            uartTx      <= curReg.byte(to_integer(curReg.counter));
--            if baudClkX8 = '1' then
               nxtReg.phase <= curReg.phase + 1;
               if curReg.phase = 7 then
                  nxtReg.counter <= curReg.counter + 1;
                  if curReg.counter = NUM_BITS_G-1 then
                     nxtReg.state <= STOP_S;
                  end if;
               end if;
--            end if;
         when STOP_S  =>
            uartTx      <= '1';
--            if baudClkX8 = '1' then
               nxtReg.phase <= curReg.phase + 1;
               if curReg.phase = 7 then
                  nxtReg.state <= IDLE_S;
               end if;
--            end if;
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

