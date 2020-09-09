library ieee;
use ieee.STD_LOGIC_1164.all;

entity QpixDummyTxRx is
   generic (
      NUM_BITS_G : natural := 64
   );
   port (
      clk         : in std_logic;
      rst         : in std_logic;
      
      txPort      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      txValid     : out std_logic;
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0);
      txByteValid : in  std_logic;
      txByteReady : out std_logic;

      rxPort      : in std_logic_vector(NUM_BITS_G-1 downto 0);
      rxValid     : in std_logic;
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic

      
   );
end entity QpixDummyTxRx;

architecture behav of QpixDummyTxRx is

begin

   rxByte      <= rxPort;
   rxByteValid <= rxValid;

   txPort      <= txByte;
   txValid     <= txByteValid;

   txByteReady <= '1';

end behav;
