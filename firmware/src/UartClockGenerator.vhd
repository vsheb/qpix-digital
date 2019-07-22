----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:48:59 01/19/2017 
-- Design Name: 
-- Module Name:    UartClockGenerator - Behavioral 
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

entity UartClockGenerator is
   generic (
      CLOCK_RATE_G : integer := 80000000;
      BAUD_RATE_G  : integer := 115200;
      GATE_DELAY_G : time    := 1 ns
   );
   port (
      clk       : in  std_logic;
      sRst      : in  std_logic;
      baudClkX8 : out std_logic
   );
end UartClockGenerator;

architecture Behavioral of UartClockGenerator is
   signal   iBaudClkX8    : std_logic := '0';
   signal   baudCounter   : unsigned(15 downto 0) := (others => '0');
   constant BAUD_RELOAD_C : unsigned(15 downto 0) := to_unsigned(CLOCK_RATE_G/(BAUD_RATE_G*8), baudCounter'length);
begin

   baudClkX8 <= iBaudClkX8;

   process(clk) begin
      if rising_edge(clk) then
         if sRst = '1' then
            iBaudClkX8  <= '0';
            baudCounter <= BAUD_RELOAD_C;
         else
            iBaudClkX8 <= '0';
            if baudCounter = 0 then
               baudCounter <= BAUD_RELOAD_C;
               iBaudClkX8  <= '1';
            else
               baudCounter <= baudCounter - 1;
            end if;
         end if;
      end if;
   end process;

end Behavioral;

