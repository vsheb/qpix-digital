library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Custom packages
use work.UtilityPkg.all;
use work.QpixPkg.all;
-- For writing in simulation
use IEEE.std_logic_textio.all;
use std.textio.all;
-- For random number generation
use ieee.math_real.all;

entity AsicArrayTb is
end AsicArrayTb;

architecture Behavioral of AsicArrayTb is

   constant N_ROWS_C : integer := 2;
   constant N_COLS_C : integer := 2;

   -- Create a new type, with indexing scheme:
   --    bitArray2d(row)(col)(dir)
   --    dir decoding: 0 - right
   --                  1 - down
   --                  2 - left
   --                  3 - up
   type slv4Array   is array (N_ROWS_C-1 downto 0) of slv(3 downto 0);
   type slv4Array2d is array (N_COLS_C-1 downto 0) of slv4Array;
   -- Default condition is high so that UART can detect high-to-low transitions
   signal txLines : slv4Array2d := (others => (others => (others => '1')));
   signal rxLines : slv4Array2d := (others => (others => (others => '1')));

   -- Likewise, need some arrays to give variable clock phases and periods
   constant CLK_PERIOD_NOMINAL_C           : time := 20000.0 ps;
   constant CLK_PERIOD_SPREAD_FRACTIONAL_C : real := 0.05;
   type timeArray   is array (N_ROWS_C-1 downto 0) of time;
   type timeArray2d is array (N_COLS_C-1 downto 0) of timeArray;
   signal  clkDelays  : timeArray2d := (others => (others => 0 ns));
   signal  clkPeriods : timeArray2d := (others => (others => CLK_PERIOD_NOMINAL_C));

   -- Connections for the DAQ node
   signal daqClk             : sl;
   signal daqRst             : sl;
   signal daqLeftUartRx      : sl;
   signal daqLeftUartTx      : sl;
   signal daqLeftRxByte      : slv(63 downto 0);
   signal daqLeftRxByteValid : sl;
   signal daqLeftTxByte      : slv(63 downto 0) := (others => '0');
   signal daqLeftTxByteValid : sl := '0';
   signal daqLeftTxByteReady : sl;
   signal daqRightUartRx      : sl;
   signal daqRightUartTx      : sl;
   signal daqRightRxByte      : slv(63 downto 0);
   signal daqRightRxByteValid : sl;
   signal daqRightTxByte      : slv(63 downto 0) := (others => '0');
   signal daqRightTxByteValid : sl := '0';
   signal daqRightTxByteReady : sl;
   
   -- General constants
   constant GATE_DELAY_C : time := 1 ns;

begin

   ---------------------------------------------------
   -- Create the mapping for the ASIC interconnects --
   ---------------------------------------------------
   -- These lines are connected directly to DAQ nodes
   rxLines(0)(0)(LT)          <= daqLeftUartTx;
   daqLeftUartRx              <= txLines(0)(0)(LT);
   rxLines(0)(N_COLS_C-1)(RT) <= daqRightUartTx;
   daqRightUartRx             <= txLines(0)(N_COLS_C-1)(RT);
   -- Iterate along columns and make the up/down connections
   G_TopBottomConnections : for i in N_COLS_C-2 downto 0 generate
      G_Col : for j in N_ROWS_C-1 downto 0 generate 
         rxLines(i)(j)(DN) <= txLines(i+1)(j)(UP);
         rxLines(i+1)(j)(UP) <= txLines(i)(j)(DN);
      end generate;
   end generate;
   -- Iterate along rows and make the left/right connections
   G_LeftRightConnections : for i in N_ROWS_C-2 downto 0 generate
      G_Row : for j in N_COLS_C-1 downto 0 generate 
         rxLines(j)(i)(RT) <= txLines(j)(i+1)(LT);
         rxLines(j)(i+1)(LT) <= txLines(j)(i)(RT);
      end generate;
   end generate;

   ---------------------------
   -- Instantiate the ASICs --
   ---------------------------
   G_Row : for i in N_ROWS_C-1 downto 0 generate
      G_Col : for j in N_COLS_C-1 downto 0 generate
         U_QpixAsicSim : entity work.QpixAsicSim
            generic map (
               GATE_DELAY_G    => GATE_DELAY_C,
               X_POS           => j,
               Y_POS           => i
            )
            port map (
               -- Simulation ports
               clkPeriod     => clkPeriods(i)(j), -- :  in real;
               clkDelay      => clkDelays(i)(j),  -- :  in real;
               -- "Real" physical ports
               txConnections => txLines(i)(j),    -- : out slv(3 downto 0);
               rxConnections => rxLines(i)(j)     -- :  in slv(3 downto 0)
            );
      end generate;
   end generate;

   ------------------
   -- Our DAQ Node --
   ------------------
   U_DaqClkRst : entity work.ClkRst
      generic map (
         RST_HOLD_TIME_G   => 1 us -- : time    := 6 us;  -- Hold reset for this long
      )
      port map (
         CLK_PERIOD_G => CLK_PERIOD_NOMINAL_C, -- : time    := 10 ns;
         CLK_DELAY_G  => 1 ns,   -- : time    := 1 ns;  -- Wait this long into simulation before asserting reset
         clkP         => daqClk, -- : out sl := '0';
         rst          => daqRSt  -- : out sl := '1';
      );
   U_DaqLeftUart : entity work.UartTop
      generic map (
         GATE_DELAY_G => GATE_DELAY_C
      )
      port map (
         clk         => daqClk,             -- : in  std_logic;
         sRst        => daqRst,             -- : in  std_logic;
         rxByte      => daqLeftRxByte,      -- : out std_logic_vector(7 downto 0);
         rxByteValid => daqLeftRxByteValid, -- : out std_logic;
         txByte      => daqLeftTxByte,      -- : in  std_logic_vector(7 downto 0) := (others => '0');
         txByteValid => daqLeftTxByteValid, -- : in  std_logic := '0';
         txByteReady => daqLeftTxByteReady, -- : out std_logic;
         uartRx      => daqLeftUartRx,      -- : in  std_logic;
         uartTx      => daqLeftUartTx       -- : out std_logic
      );
   U_DaqRightUart : entity work.UartTop
      generic map (
         GATE_DELAY_G => GATE_DELAY_C
      )
      port map (
         clk         => daqClk,              -- : in  std_logic;
         sRst        => daqRst,              -- : in  std_logic;
         rxByte      => daqRightRxByte,      -- : out std_logic_vector(7 downto 0);
         rxByteValid => daqRightRxByteValid, -- : out std_logic;
         txByte      => daqRightTxByte,      -- : in  std_logic_vector(7 downto 0) := (others => '0');
         txByteValid => daqRightTxByteValid, -- : in  std_logic := '0';
         txByteReady => daqRightTxByteReady, -- : out std_logic;
         uartRx      => daqRightUartRx,      -- : in  std_logic;
         uartTx      => daqRightUartTx       -- : out std_logic
      );

   ----------------------------
   -- Generate random resets --
   ----------------------------
   stim_proc : process
      variable seed1, seed2 : positive; -- seed values for random generator
      variable rand         : real;     -- random real-number value in range 0 to 1.0  
      variable my_line      : line;     -- type 'line' comes from textio
      variable temp         : real;
   begin
      -- Initialize the clock phases and frequencies
      for i in N_ROWS_C-1 downto 0 loop
         for j in N_COLS_C-1 downto 0 loop
            uniform(seed1, seed2, rand); -- generate random number
            clkDelays(i)(j)  <= rand*CLK_PERIOD_NOMINAL_C;
            uniform(seed1, seed2, rand); -- generate random number
            temp := (1.0 - CLK_PERIOD_SPREAD_FRACTIONAL_C/2.0) * real(CLK_PERIOD_NOMINAL_C/1 ns) + (CLK_PERIOD_SPREAD_FRACTIONAL_C * real(CLK_PERIOD_NOMINAL_C/1 ns) * (rand));
            write(my_line, temp);
            writeline(output, my_line);
            clkPeriods(i)(j) <= temp * 1 ns;--(1.0 - CLK_PERIOD_SPREAD_FRACTIONAL_C) * CLK_PERIOD_NOMINAL_C; -- + (CLK_PERIOD_SPREAD_FRACTIONAL_C * CLK_PERIOD_NOMINAL_C * (rand));
         end loop;
      end loop;
      -- Initialize the clock periods (frequencies) 
      for i in N_ROWS_C-1 downto 0 loop
         for j in N_COLS_C-1 downto 0 loop
         end loop;
      end loop;


      wait for 0.5 us;
      write(my_line, string'("Beginning simulation with the following delays and periods:"));
      writeline(output, my_line);
      for i in N_ROWS_C-1 downto 0 loop
         for j in N_COLS_C-1 downto 0 loop
            write(my_line, string'("ASIC "));
            write(my_line, i, right, 2);
            write(my_line, string'(" "));
            write(my_line, j, right, 2);
            write(my_line, string'(" : "));
            write(my_line, real(clkDelays(i)(j) / 1 ns), right, 6, 4);
            write(my_line, string'(" "));
            write(my_line, real(clkPeriods(i)(j) / 1 ns), right, 6, 4);
            writeline(output, my_line);
         end loop;
      end loop;

      -- Start stimulus here
      wait for 1.5 us;
      daqLeftTxByte      <= x"0123456789ABCDEF";
      daqLeftTxByteValid <= '1';
      wait for CLK_PERIOD_NOMINAL_C;
      daqLeftTxByte      <= (others => '0');
      daqLeftTxByteValid <= '0';

      -- End simulation stimulus by waiting forever
      wait;

   end process;

end Behavioral;

