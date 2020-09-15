library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;


entity QpixCommTb is
end entity QpixCommTb;


architecture behav of QpixCommTb is

   constant CLK_PERIOD_NOMINAL_C           : time := 20000.0 ps;
   signal clk                            : std_logic                := '0';
   signal rst                            : std_logic                := '0';

   signal outData : QpixDataFormatType := QpixDataZero_C; 
   signal inData  : QpixDataFormatType := QpixDataZero_C; 
   signal regData : QpixRegDataType    := QpixRegDataZero_C;
   signal TxPortsArr : QpixTxRxPortsArrType := (others => QpixTxRxPortZero_C);
   signal RxPortsArr : QpixTxRxPortsArrType := (others => QpixTxRxPortZero_C);

   signal reg     : QpixRegDataType    := QpixRegDataZero_C;

begin
   
   QpixComm_U : entity work.QpixComm
   port map(
      clk => clk,
      rst => rst,
      outData_i  => outData,
      inData     => inData,
      regData    => regData,

      TxPortsArr => TxPortsArr,
      RxPortsArr => RxPOrtsArr
   );

   -----------------------------------------------------------
   -- Clocking process
   -----------------------------------------------------------
   CLK_PRC : process
   begin
      clk <= '1';
      wait for CLK_PERIOD_NOMINAL_C/2;
      clk <= '0';
      wait for CLK_PERIOD_NOMINAL_C/2;
   end process;
   -----------------------------------------------------------

   STIM_PRC : process
   begin
      wait for 100 ns;
      rst <= '1';
      wait for 500 ns;
      rst <= '0';
      wait for 500 ns;

      report "reset done";
      wait until clk = '1';
      
      RxPortsArr(0).Valid <= '1';
      RxPortsArr(0).Data  <= fQpixRegToByte(reg);

      wait until clk = '1';
      RxPortsArr(0).Valid <= '0';

      wait for 1 ms;


   end process;


end behav;
