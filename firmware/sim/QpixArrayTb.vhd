library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use IEEE.std_logic_textio.all;
use std.textio.all;

-- For random number generation
use ieee.math_real.all;

library work;
use work.QpixPkg.all;


entity QpixArrayTb is
end entity QpixArrayTb;


architecture behav of QpixArrayTb is

   constant CLK_PERIOD_NOMINAL_C           : time := 20000.0 ps;
   constant CLK_PERIOD_SPREAD_FRACTIONAL_C : real := 0.05;
   signal   clk                            : std_logic                := '0';
   signal   rst                            : std_logic                := '0';
   

   constant X_NUM_G  : natural := 3;
   constant Y_NUM_G  : natural := 3;

   signal  clkArr                         : Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1);
   signal  clkDelays  : TimeArray2DType(0 to X_NUM_G-1, 0 to Y_NUM_G-1) ;
   signal  clkPeriods : TimeArray2DType(0 to X_NUM_G-1, 0 to Y_NUM_G-1) ;

   ---------------------------------------------------
   -- type defenitions
   ---------------------------------------------------
   type AsicWireArrayType is array(0 to X_NUM_G) of QpixTxRxPortType;
   type AsicWire2DArrayType is array(0 to Y_NUM_G) of AsicWireArrayType;
   type RouteStatesArrType is array(0 to X_NUM_G) of integer;
   type RouteStates2DArrType is array(0 to Y_NUM_G) of RouteStatesArrType;
   ---------------------------------------------------
   
   signal XRxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal YRxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal XTxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));
   signal YTxArr  : AsicWire2DArrayType := (others => (others => QpixTxRxPortZero_C));

   signal daqTxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal daqTxByteValid : std_logic := '0';

   signal daqRxByte      : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal daqRxByteValid : std_logic := '0';

   
   signal StatesArr : RouteStates2DArrType;

   ---------------------------------------------------
   -- from left to right -- XTxArr  
   -- from right to left -- XRxArr  
   --                               
   --   ____   XTxArr(i)  ____      
   --  |  tx|----------->|rx  |      
   --  |  rx|<-----------|tx  |      
   --   ----   XRxArr(i)  ----      
   --
   ---------------------------------------------------
   signal inPorts : QpixInPortsType := QpixInPortsZero_C;
   signal inPortsArr : QpixInPortsArrType(0 to X_NUM_G-1, 0 to Y_NUM_G-1) := (others => (others => QpixInPortsZero_C));

   signal hitMask  : Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1) := (others => (others => '0')) ;

   signal reg     : QpixRegDataType    := QpixRegDataZero_C;

   --
   --      0
   --   3     1
   --      2
   --
   --procedure print_arr ( a: in AsicWire2DArrayType) is
      --variable b    : string (1 to X_NUM_G+1) := (others => NUL);
      --variable stri : integer := 1; 
      --variable jj   : integer := 0;
      --variable x    : QpixTxRxPortType := QpixTxRxPortZero_C;
   --begin
      --report "---------";
      --for j in 0 to Y_NUM_G loop
         --stri := 1;
         --for i in 0 to X_NUM_G loop
            --x := a(i)(j);
            --b(stri) := std_logic'image(x.Valid)(2);
            --stri := stri+1;
         --end loop;
         --jj := j;
         --report "row " & integer'image(jj) & ":" & b;
      --end loop;
      --report "---------";
   --end procedure;

   procedure print_sta ( a: in RouteStates2DArrType) is
      variable b    : string (1 to X_NUM_G+1) := (others => NUL);
      variable stri : integer := 1; 
      variable jj   : integer := 0;
      variable x    : integer := 0;
   begin
      report "---------";
      for j in 0 to Y_NUM_G-1 loop
         stri := 1;
         for i in 0 to X_NUM_G-1 loop
            x := a(i)(j); --RouteStatesType'pos(a(i)(j));
            if x /= 3 then 
               b(stri) := integer'image(x)(1);
            else 
               b(stri) := '*';
            end if;
            stri := stri+1;
         end loop;
         jj := j;
         report "row " & integer'image(jj) & ":" & b;
      end loop;
      report "---------";
   end procedure;

begin
   GEN_X : for i in 0 to X_NUM_G-1 generate
      GEN_Y : for j in 0 to Y_NUM_G-1 generate
         QpixAsicTop_U : entity work.QpixAsicTop
            generic map (
               TXRX_TYPE     => "ENDEAVOR",
               X_POS_G       => i,
               Y_POS_G       => j
            )
            port map(
               clk      => clk,
               rst      => rst,
               inPorts  => inPortsArr(i,j),

               -- TX 
               TxPortsArr(0) => YRxArr(i)(j),   -- up
               TxPortsArr(1) => XTxArr(i+1)(j), -- right
               TxPortsArr(2) => YTxArr(i)(j+1), -- down
               TxPortsArr(3) => XRxArr(i)(j),   -- left

               -- RX
               RxPortsArr(0) => YTxArr(i)(j),   -- up 
               RxPortsArr(1) => XRxArr(i+1)(j), -- right
               RxPortsArr(2) => YRxArr(i)(j+1), -- down
               RxPortsArr(3) => XTxArr(i)(j)   -- left

               --State         => StatesArr(i)(j)


            );
      end generate GEN_Y;
   end generate GEN_X;

   QpixDaqNode_U : entity work.QpixDaqNode
   port map(

      clk      => clk ,
      rst      => rst, 

      txByte      => daqTxByte,
      txByteValid => daqTxByteValid,

      rxByte      => daqRxByte,
      rxByteValid => daqRxByteValid,

      Tx       => YTxArr(0)(0),
      Rx       => YRxArr(0)(0)
   );

   process (clk)
   begin
      if rising_edge (clk) then
         if daqRxByteValid = '1' then
            report "Rceived! " & "X: " & to_string(daqRxByte(39 downto 36)) & 
            " Y: " & to_string(daqRxByte(35 downto 32)) & 
            " WTYPE : " & to_string(daqRxByte(59 downto 56));
         end if;
         
      end if;
   end process;


   QpixHitsGen_U : entity work.QpixHitsGen
      generic map (
         X_NUM_G => X_NUM_G,
         Y_NUM_G => Y_NUM_G
      )
      port map (
         clk      => clk,
         rst      => rst,

         hitMask  => hitMask,
         inPortsArr => inPortsArr
      );


   --QpixAsicArray_U : entity work.QpixAsicArray
   --port map(
      --clk => clk,
      --rst => rst
   --);
       
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

   --X_CLK_GEN : for i in 0 to X_NUM_G-1 generate
      --Y_CLK_GEN : for j in 0 to Y_NUM_G-1 generate
         --CLK_ARR_PRC : process is
         --begin
            --clkArr(i,j) <= '0';
            --wait for 500 ns;
            --report integer'image(i) & " " & to_string(clkDelays(i,j)) & " " & to_string(clkPeriods(i,j));
            --wait for clkDelays(i,j);
            --while true loop
               --clkArr(i,j) <= not clkArr(i,j);
               --wait for clkPeriods(i,j)/2;
            --end loop;
         --end process;
      --end generate;
   --end generate;

   --process(YTxArr)
   --begin
      --if XTxArr'event or YTxArr'event then
      --if YTxArr'event  then
         --report "xtx" & std_logic'image(XTxArr(0)(0).Valid) & std_logic'image(XTxArr(1)(0).Valid) & std_logic'image(XTxArr(2)(0).Valid);
         --report "ytx" & std_logic'image(YTxArr(0)(0).Valid) & std_logic'image(YTxArr(0)(1).Valid) & std_logic'image(YTxArr(0)(2).Valid);
         --report "yrx" & std_logic'image(YRxArr(0)(0).Valid) & std_logic'image(YRxArr(0)(1).Valid) & std_logic'image(YRxArr(0)(2).Valid);
         --print_arr(YTxArr);
      --end if;
   --end process;

   process(statesArr)
   begin
      if statesArr'event then
         print_sta(statesArr);
      end if;
   end process;

   STIM_PRC : process
      variable seed1, seed2 : positive; -- seed values for random generator
      variable rand         : real;     -- random real-number value in range 0 to 1.0  
      variable my_line      : line;     -- type 'line' comes from textio
      variable temp         : real;
   begin

      -------------------------------------------------
      -- Initialize the clock phases and frequencies --
      -------------------------------------------------
      write(my_line, string'("# Clock Phases and Periods by ASIC Position #"));
      writeline(output, my_line);
      write(my_line, string'("# All time values given in ns # "));
      writeline(output, my_line);
      for i in X_NUM_G-1 downto 0 loop
         for j in Y_NUM_G-1 downto 0 loop
            write(my_line, string'("ASIC "));
            write(my_line, i, right, 2);
            write(my_line, string'(" "));
            write(my_line, j, right, 2);
            write(my_line, string'(" : "));
            ------------------
            -- Clock Phases --
            ------------------
            uniform(seed1, seed2, rand); -- generate random number
            temp := rand * real(CLK_PERIOD_NOMINAL_C / 1000.0 ps);
            clkDelays(i,j)  <= temp * 1000.0 ps;
            -- The following line results in Modelsim being rounded to 1 ns.
            -- write(my_line, real(clkDelays(i)(j) / 1000.0 ps), right, 6, 4);
            write(my_line, temp, right, 6, 2);            
            write(my_line, string'(" "));
            ------------------
            -- Clock Periods --
            ------------------
            uniform(seed1, seed2, rand); -- generate random number
            temp := (1.0 - CLK_PERIOD_SPREAD_FRACTIONAL_C/2.0) * real(CLK_PERIOD_NOMINAL_C/1.0 ns) + (CLK_PERIOD_SPREAD_FRACTIONAL_C * real(CLK_PERIOD_NOMINAL_C/1.0 ns) * (rand));
            write(my_line, temp, right, 6, 2);
            writeline(output, my_line);
            clkPeriods(i,j) <= temp * 1000.0 ps;
         end loop;
      end loop;

      report "START!";

      --------------------------
      -- Stimulus begins here --
      --------------------------

      wait for 100 ns;
      rst <= '1';
      wait for 500 ns;
      report "reset!";
      rst <= '0';
      wait for 500 ns;

      report "reset done!";
      wait until clk = '1';

      --report "test reg";
      --reg.Addr <= x"0002";
      --reg.Data <= x"0000";
      --reg.OpWrite <= '0';
      --reg.OpRead  <= '1';
      --wait until clk = '1';
      --daqTxByte <= fQpixRegToByte(reg);
      --daqTxByteValid <= '1';
      --wait until clk = '1';
      --daqTxByteValid <= '0';
      --wait for 500 us;

      report "inject hits";
      reg.Addr <= x"0001";
      reg.Data <= x"0001";
      reg.OpWrite <= '1';
      reg.SrcDaq  <= '1';
      reg.ReqId   <= x"1";

      wait until clk = '1';
      hitMask(1,0) <= '1';
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      wait until clk = '1';
      --wait until clk = '1';
      --wait until clk = '1';
      hitMask(1,0) <= '0';

      wait for 500 ns;
      

      wait until clk = '1';
      daqTxByte <= fQpixRegToByte(reg);
      daqTxByteValid <= '1';
      --XTxArr(0)(0).Valid <= '1';
      --XTxArr(0)(0).Data  <= fQpixRegToByte(reg);

      wait until clk = '1';
      daqTxByteValid <= '0';
      --XTxArr(0)(0).Valid <= '0';

      wait for 1.0 ms;
      report "here!";

      report "next trg";
      reg.Addr <= x"0001";
      reg.Data <= x"0001";
      reg.OpWrite <= '1';
      reg.SrcDaq  <= '1';
      reg.ReqId   <= x"2";

      wait until clk = '1';
      daqTxByte <= fQpixRegToByte(reg);
      daqTxByteValid <= '1';
      wait until clk = '1';
      daqTxByteValid <= '0';

      wait for 0.5 ms;
      report "here!";


   end process;


end behav;
