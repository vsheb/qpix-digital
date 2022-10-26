----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.QpixPkg.all;


----------------------------------------------------------------------------------
entity QpixDataProc is
   generic (
      X_POS_G         : natural := 0;
      Y_POS_G         : natural := 0;
      N_ANALOG_CHAN_G : natural := 16
   );
   port (
      clk             : in  std_logic;
      rst             : in  std_logic;
                      
      disIfRouteBusy  : in  std_logic;
      routeBusy       : in  std_logic;

      testEna         : in  std_logic; 
      clkCnt          : in  std_logic_vector(31 downto 0);
      fifoFull        : in  std_logic;
                      
      chanEna         : in  std_logic_vector(N_ANALOG_CHAN_G-1 downto 0);
      qpixRstPulses   : in  std_logic_vector(N_ANALOG_CHAN_G-1 downto 0);

      outData         : out QpixDataFormatType
      
   );
end entity QpixDataProc;
----------------------------------------------------------------------------------


architecture behav of QpixDataProc is

   signal qpixRstPulsesE : std_logic_vector(N_ANALOG_CHAN_G-1 downto 0) := (others => '0');
   signal qpixRstPulsesM : std_logic_vector(N_ANALOG_CHAN_G-1 downto 0) := (others => '0');

   signal testData  : QPixDataFormatType := QpixDataZero_C;
   signal inData    : QPixDataFormatType := QpixDataZero_C;

   signal TimeStamp : std_logic_vector(G_TIMESTAMP_BITS-1 downto 0) := (others => '0');

begin

   ----------------------------------------------------------------------------------
   -- Test pattern generator
   ----------------------------------------------------------------------------------
   --QpixTestPatGen_U : entity work.QpixTestPatGen 
   --generic map(
      --X_POS_G => X_POS_G,
      --Y_POS_G => Y_POS_G
   --)
   --port map (
      --clk => clk,
      --rst => rst,

      --outData => testData
   --);  --- NOT USED FOR NOW
   ----------------------------------------------------------------------------------
   TimeStamp <= clkCnt(G_TIMESTAMP_BITS-1 downto 0);

   ANALOG_IN_GEN : for i in 0 to N_ANALOG_CHAN_G-1 generate
      PulseEdge_U : entity work.EdgeDetector
         generic map(
            N_SYNC_G => 2
         )
         port map(
            clk    => clk,
            rst    => rst,
            input  => qpixRstPulses(i),
            output => qpixRstPulsesE(i)
         );
   end generate ANALOG_IN_GEN;

   qpixRstPulsesM <= qpixRstPulsesE and chanEna;

   ----------------------------------------------------------------------------------
   -- Format the data
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         inData.DataValid <= '0';
         if qpixRstPulsesM /= (qpixRstPulsesM'range => '0') and fifoFull /= '1' then
            inData.DataValid <= '1';
            inData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
            inData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
            inData.TimeStamp <= TimeStamp;
            inData.ChanMask  <= qpixRstPulsesE;
         end if;
      end if;
   end process;
   ----------------------------------------------------------------------------------

   ----------------------------------------------------------------------------------
   -- Mux between input and test pattern data / TODO
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if routeBusy = '1' and disIfRouteBusy = '1' then
            outData <= QpixDataZero_C;
         else
            outData <= inData;
         end if;
      end if;
   end process;
   ----------------------------------------------------------------------------------



end behav;
