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

entity UartRx is
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
      -- Byte data received
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      -- Error statuses out
      rxFrameErr  : out std_logic; -- No valid stop bit found
      rxBreakErr  : out std_logic; -- Line low for longer than a character time
      -- UART serial signal in
      uartRx      : in  std_logic
   );
end UartRx;

architecture Behavioral of UartRx is

   type StateType is (IDLE_S, START_S, DATA_S, STOP_S);

   type RegType is record
      state     : StateType;
      byte      : std_logic_vector(NUM_BITS_G-1 downto 0);
      byteValid : std_logic;
      counter   : unsigned(2 downto 0);
      lowCount  : unsigned(7 downto 0);
      byteCount : unsigned(integer(ceil(log2(real(NUM_BITS_G))))-1 downto 0);
      frameErr  : std_logic;
      breakErr  : std_logic;
      lastRx    : std_logic;
   end record;
   
   constant REG_INIT_C : RegType := (
      state     => IDLE_S,
      byte      => (others => '0'),
      byteValid => '0',
      counter   => (others => '0'),
      lowCount  => (others => '0'),
      byteCount => (others => '0'),
      frameErr  => '0',
      breakErr  => '0',
      lastRx    => '0'
   );
   
   signal rx_q : std_logic_vector(1 downto 0);
   signal rx_r : std_logic := '0';

   attribute shreg_extract : string;
   attribute shreg_extract of rx_q : signal is "no";

   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;
   
begin

   process (clk)
   begin
      if rising_edge (clk) then
         rx_q <= rx_q(0 downto 0) & uartRx;
      end if;
   end process;
   rx_r <= rx_q(1);

   -- Map to outputs
   rxByte      <= curReg.byte;
   rxByteValid <= curReg.byteValid;
   rxFrameErr  <= curReg.frameErr;
   rxBreakErr  <= curReg.breakErr;

   -- Asynchronous state logic
   process(curReg, rx_r, baudClkX8) begin
      -- Set defaults
      nxtReg <= curReg;
      -- Default strobe signals are '0'
      nxtReg.byteValid <= '0';
      nxtReg.frameErr  <= '0';
      nxtReg.breakErr  <= '0';      
      
      -- Count consecutive low level
      if rx_r = '1' or curReg.state = IDLE_S then
         nxtReg.lowCount <= (others => '0');
--      elsif baudClkX8 = '1' and curReg.lowCount(curReg.lowCount'high) /= '1' then
      elsif curReg.lowCount(curReg.lowCount'high) /= '1' then
         nxtReg.lowCount <= curReg.lowCount + 1;
      end if;
      
      -- One bit pipe for last Rx state
--      if baudClkX8 = '1' then
         nxtReg.lastRx <= rx_r;
--      end if;
      
      -- Actual state definitions
      case(curReg.state) is
         -- Watch for high to low transition of serial line
         when IDLE_S  =>
            nxtReg.counter   <= (others => '0');
            nxtReg.byteCount <= (others => '0');
            if rx_r = '0' and curReg.lastRx = '1' then
               nxtReg.state   <= START_S;
            end if;
         -- Look for at least half a bit wide low count.
         -- If it's shorter, consider this a failed start.
         when START_S =>
            if curReg.lowCount >= 3 then
               nxtReg.state <= DATA_S;
            elsif rx_r = '1' then
               nxtReg.state <= IDLE_S;
            end if;
         -- Wait a full bit time before accepting bits
         when DATA_S =>
--            if baudClkX8 = '1' then
               nxtReg.counter <= curReg.counter + 1;
               if curReg.counter = 7 then
                  nxtReg.byte(to_integer(curReg.byteCount)) <= rx_r;
                  nxtReg.byteCount <= curReg.byteCount + 1;
                  if curReg.byteCount = NUM_BITS_G-1 then
                     nxtReg.state <= STOP_S;
                  end if;
               end if;
--            end if;
         -- Check for errors while the stop bit is being received
         when STOP_S  =>
--            if baudClkX8 = '1' then
               nxtReg.counter <= curReg.counter + 1;
               if curReg.counter = 7 then
                  nxtReg.state <= IDLE_S;
                  -- Present data no matter what
                  nxtReg.byteValid <= '1';
                  -- Also present errors if applicable
                  if rx_r /= '1' then
                     nxtReg.frameErr <= '1';
                  end if;
                  if curReg.lowCount >= 72 then
                     nxtReg.breakErr <= '1';
                  end if;
               end if;
--            end if;
         -- Catch all state
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

