library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use std.env.finish;

library work;


entity QpixEndeavorTb is
end entity QpixEndeavorTb;

architecture behav of QpixEndeavorTb is

   constant CLK_PERIOD_TX        : time := 20.00 ns;
   constant CLK_PERIOD_RX        : time := 18.00 ns;
   constant NUM_BITS_G : natural := 64;
   constant GATE_DELAY_G         : time := 1 ns;
   constant PHASE_C              : time := 0 ns;

   signal   clkRx                : std_logic                := '0';
   signal   clkTx                : std_logic                := '0';
   signal   sRst                 : std_logic                := '0';

   signal   rxByte               : std_logic_vector (NUM_BITS_G-1 downto 0) := (others => '0');
   signal   rxByteValid          : std_logic := '0';

   signal   rxFrameErr           : std_logic := '0';
   signal   rxBreakErr           : std_logic := '0';

   signal   txByte               : std_logic_vector(NUM_BITS_G-1 downto 0) := (others => '0');
   signal   txByteValid          : std_logic := '0';
   signal   txByteReady          : std_logic := '0';

   signal   Rx                   : std_logic := '0';
   signal   Tx                   : std_logic := '0';
   

begin



   U_Tx : entity work.QpixEndeavorTx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clkTx,
         sRst        => sRst,
         -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
         txByteReady => txByteReady,
         -- Byte data to send out
         txByte      => txByte,
         txByteValid => txByteValid,
         -- UART serial signal out
         tx      => Tx      
      );
      
   Rx <= Tx after 0 ps;
   
   -- Receive UART RX bytes 
   U_Rx : entity work.QpixEndeavorRx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         -- Clock and reset
         clk         => clkRx,
         sRst        => sRst,

         -- Byte signal out
         rxByte      => rxByte,
         rxByteValid => rxByteValid,

         -- UART serial signal in
         rx      => Rx
      );

   -----------------------------------------------------------
   -- Clocking process TX
   -----------------------------------------------------------
   CLK_TX : process
   begin
      clkTx <= '1';
      wait for CLK_PERIOD_TX/2;
      clkTx <= '0';
      wait for CLK_PERIOD_TX/2;
   end process;
   -----------------------------------------------------------

   -----------------------------------------------------------
   -- Clocking process RX
   -----------------------------------------------------------
   CLK_RX : process
   begin
      clkRx <= '1' after PHASE_C;
      wait for CLK_PERIOD_RX/2;
      clkRx <= '0' after PHASE_C;
      wait for CLK_PERIOD_RX/2;
   end process;
   -----------------------------------------------------------


   STIM : process 
   begin
      wait for 100 ns; 
      sRst <= '1';
      wait for 100 ns;
      sRst <= '0';
      wait for 200 ns;

      for i in 0 to 100 loop
         report "i = " & integer'image(i);
         wait until clkTx = '1';

         --txByte      <=  std_logic_vector(to_unsigned(x"1111_2222_3333_4444",NUM_BITS_G));
         txByte      <=  x"0000_0000_0000_0001";
         --txByte      <=  x"1111_1111_1111_1111";
         txByteValid <= '1';
         wait for 500 ns;
         wait until clkTx = '1';
         txByteValid <= '0';

         --wait for 10 us;
         --finish;
         wait until rxByteValid = '1';
         if rxByte = txByte then
            report "OK";
         else
            report "ERROR";
         end if;
         wait until txByteReady;
      end loop;

   end process STIM;

end behav;

