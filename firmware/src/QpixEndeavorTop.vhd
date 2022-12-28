library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


--!{ signal : [                                                                                                  
--!  { name: "clk",      wave: "p.............|.............." },
--!  { name: "tx",       wave: "05...0..9.......0.|5...0.....", data : ["zero","one","zero"] },
--!  { name: "tx state", wave: "z5...7..9.......7.|5...3.....",  data: ["zero", "gap", "one","gap","zero","word end"] }
--!]}


entity QpixEndeavorTop is
   generic (
      NUM_BITS_G   : natural := 64;   --! Number of bits in a packet
      GATE_DELAY_G : time    := 1 ns; 

      N_ZER_CLK_G  : natural :=  8;  --! Number of clocks to encode 0
      N_ONE_CLK_G  : natural :=  24; --! Number of clocks to encode 1
      N_GAP_CLK_G  : natural :=  16; --! Number of clocks to encode a gap between bits
      N_FIN_CLK_G  : natural :=  40; --! Number of clocks to encode end of the packet
                                     
      N_ZER_MIN_G  : natural :=  4;  
      N_ZER_MAX_G  : natural :=  12; 
      N_ONE_MIN_G  : natural :=  16; 
      N_ONE_MAX_G  : natural :=  32; 
      N_GAP_MIN_G  : natural :=  8;  
      N_GAP_MAX_G  : natural :=  32; 
      N_FIN_MIN_G  : natural :=  32  

   );
   port (
      clk         : in  std_logic;
      sRst        : in  std_logic;
      scale       : in  std_logic_vector(2 downto 0);
      TxRxDisable : in  std_logic := '0';
      -- RX out
      rxByte      : out std_logic_vector(NUM_BITS_G-1 downto 0);
      rxByteValid : out std_logic;
      rxByteAck   : in  std_logic;   
      -- RX Error statuses out
      rxFrameErr  : out std_logic; -- No valid stop bit found
      rxBreakErr  : out std_logic; -- Line low for longer than a character time
      rxBusy      : out std_logic;
      rxError     : out std_logic;
      -- TX in 
      txByte      : in  std_logic_vector(NUM_BITS_G-1 downto 0) := (others => '0');
      txByteValid : in  std_logic := '0';
      txByteReady : out std_logic;
      -- external ports
      Rx          : in  std_logic;
      Tx          : out std_logic
   );

end QpixEndeavorTop;

architecture Behavioral of QpixEndeavorTop is


begin

   -- Receive UART RX bytes 
   U_Rx : entity work.QpixEndeavorRx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G,
         N_ZER_MIN_G  => N_ZER_MIN_G,
         N_ZER_MAX_G  => N_ZER_MAX_G,
         N_ONE_MIN_G  => N_ONE_MIN_G,
         N_ONE_MAX_G  => N_ONE_MAX_G,
         N_GAP_MIN_G  => N_GAP_MIN_G,
         N_GAP_MAX_G  => N_GAP_MAX_G,
         N_FIN_MIN_G  => N_FIN_MIN_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         scale       => scale,
         disable     => TxRxDisable,
         -- Byte signal out
         rxByte      => rxByte,
         rxByteValid => rxByteValid,
         rxByteAck   => rxByteAck,
         -- Error statuses out
         bitError    => rxFrameErr,
         lenError    => rxBreakErr,
         rxError     => rxError,

         Rx          => Rx,
         rxBusy      => rxBusy
      );
   
   -- Transmit UART TX bytes
   U_Tx : entity work.QpixEndeavorTx
      generic map (
         NUM_BITS_G   => NUM_BITS_G,
         GATE_DELAY_G => GATE_DELAY_G,
         N_ZER_CLK_G  => N_ZER_CLK_G,
         N_ONE_CLK_G  => N_ONE_CLK_G,
         N_GAP_CLK_G  => N_GAP_CLK_G,
         N_FIN_CLK_G  => N_FIN_CLK_G
      )
      port map (
         -- Clock and reset
         clk         => clk,
         sRst        => sRst,
         scale       => scale,
         disable     => TxRxDisable, 
         -- Ready to send new byte (data is sent on txByteValid AND txByteReady)
         txByteReady => txByteReady,
         -- Byte data to send out
         txByte      => txByte,
         txByteValid => txByteValid,
         tx          => Tx      
      );

end Behavioral;

