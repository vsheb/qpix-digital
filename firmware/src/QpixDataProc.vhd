----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
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
                      
      ena             : in  std_logic;
                      
      testEna         : in  std_logic; 
                      
      qpixRstPulses   : in  std_logic_vector(N_ANALOG_CHAN_G-1 downto 0);

      outData         : out QpixDataFormatType
      
   );
end entity QpixDataProc;
----------------------------------------------------------------------------------


architecture behav of QpixDataProc is

   signal qpixRstPulsesE : std_logic_vector(N_ANALOG_CHAN_G-1 downto 0) := (others => '0');

   signal testData  : QPixDataFormatType := QpixDataZero_C;
   signal inData    : QPixDataFormatType := QpixDataZero_C;

   signal TimeStamp : unsigned(G_TIMESTAMP_BITS-1 downto 0) := (others => '0');

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

   process (clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            Timestamp <= (others => '0');
         else
            TimeStamp <= Timestamp + 1; 
         end if;
      end if;
   end process;  

   ANALOG_IN_GEN : for i in 0 to N_ANALOG_CHAN_G-1 generate
      PulseEdge_U : entity work.EdgeDetector
         port map(
            clk    => clk,
            rst    => rst,
            input  => qpixRstPulses(i),
            output => qpixRstPulsesE(i)
         );
   end generate ANALOG_IN_GEN;

   ----------------------------------------------------------------------------------
   -- Format the data
   ----------------------------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         inData.DataValid <= '0';
         if qpixRstPulsesE /= (qpixRstPulsesE'range => '0') then
            inData.DataValid <= '1';
            inData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
            inData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
            inData.TimeStamp <= std_logic_vector(TimeStamp);
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
         if ena = '1' then
            outData <= inData;
         else
            outData <= QpixDataZero_C;
         end if;
      end if;
   end process;
   ----------------------------------------------------------------------------------



end behav;
