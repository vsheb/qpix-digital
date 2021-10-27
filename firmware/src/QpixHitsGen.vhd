library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


library work;
use work.QpixPkg.all;

entity QpixHitsGen is
   generic (
      X_NUM_G      : natural := 3;
      Y_NUM_G      : natural := 3
   );
   port (
      clk          : in std_logic;
      rst          : in std_logic;
      
      hitMask      : in Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1);
      timestamp    : in std_logic_vector(G_TIMESTAMP_BITS-1 downto 0) := (others => '0');
      chanMask     : in std_logic_vector(G_N_ANALOG_CHAN-1 downto 0)  := (others => '0');
      inPortsArr   : out QpixInPortsArrType(0 to X_NUM_G-1, 0 to Y_NUM_G-1)
      
   );
end entity QpixHitsGen;

architecture behav of QpixHitsGen is

   

begin

   X_GEN : for i in 0 to X_NUM_G-1 generate
      Y_GEN : for j in 0 to Y_NUM_G-1 generate
         process (clk)
         begin
            if rising_edge (clk) then
               if hitMask(i,j) = '1' then
                  inPortsArr(i,j).Valid <= '1';
                  inPortsArr(i,j).TimeStamp <= timestamp;
                  inPortsArr(i,j).ChanMask  <= chanMask;
               else
                  inPortsArr(i,j).Valid <= '0';
                  inPortsArr(i,j).TimeStamp <= (others => '0');
                  inPortsArr(i,j).ChanMask  <= (others => '0');


               end if;
            end if;
         end process;
      end generate;
   end generate;


end behav;
