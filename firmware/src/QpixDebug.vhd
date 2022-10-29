library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.QpixPkg.all;

entity QpixDebug is
   port (
      clk            : in  std_logic;
      rst            : in  std_logic;

      disableDbgOut  : in  std_logic;
      
      locFifoFull    : in  std_logic;
      extFifoFull    : in  std_logic;
      routeFsmState  : in  std_logic_vector(2 downto 0);
      RxBusy         : in  std_logic;
      TxReady        : in  std_logic;
      RxDataValid    : in  std_logic;
      RxRegValid     : in  std_logic;
      RxError        : in  std_logic;
      clkDiv         : in  std_logic;
      RxValidDbg     : in  std_logic;
      InterrHard     : in  std_logic;
      InterrSoft     : in  std_logic;

      dbgLocFifoFull : out std_logic;
      dbgExtFifoFull : out std_logic;
      dbgFsmState    : out std_logic_vector(2 downto 0);      
      dbgRxBusy      : out std_logic;     
      dbgTxBusy      : out std_logic;     
      dbgDataValid   : out std_logic;  
      dbgRxError     : out std_logic;    
      dbgClkDiv      : out std_logic;     
      dbgRxValid     : out std_logic;    
      dbgInterr      : out std_logic
   );
end entity QpixDebug;

architecture behav of QpixDebug is
   signal dbgDataValid_s : std_logic := '0';
   signal dbgRxValid_s   : std_logic := '0';
   signal dbgInterr_s    : std_logic := '0';
   
begin

   process (clk)
   begin
      if rising_edge(clk) then
         if disableDbgOut = '1' then
            dbgLocFifoFull <= '0';
            dbgExtFifoFull <= '0';
            dbgFsmState    <= (others => '0');
            dbgRxBusy      <= '0';
            dbgTxBusy      <= '0';
            dbgDataValid_s <= '0';
            dbgRxError     <= '0';
            dbgClkDiv      <= '0';
            dbgRxValid_s   <= '0';
            dbgInterr_s    <= '0';
         else
            dbgLocFifoFull <= locFifoFull;
            dbgExtFifoFull <= extFifoFull;
            dbgFsmState    <= routeFsmState;
            dbgRxBusy      <= RxBusy;
            dbgTxBusy      <= not TxReady;
            dbgDataValid_s <= RxDataValid or RxRegValid;
            dbgRxError     <= RxError;
            dbgClkDiv      <= ClkDiv;
            dbgRxValid_s   <= RxValidDbg;
            dbgInterr_s    <= InterrHard or InterrSoft;
         end if;
      end if;
   end process;

   
   PulseShaper_u0 : entity work.PulseShaper
      port map (
         clk     => clk,
         rst     => rst,
         len     => std_logic_vector(to_unsigned(G_DATA_BITS*2,32)),
         dly     => (others => '0'),
         din     => dbgDataValid_s,
         dou     => dbgDataValid
      );

   PulseShaper_u1 : entity work.PulseShaper
      port map (
         clk     => clk,
         rst     => rst,
         len     => std_logic_vector(to_unsigned(G_DATA_BITS*2,32)),
         dly     => (others => '0'),
         din     => dbgRxValid_s,
         dou     => dbgRxValid
      );

   PulseShaper_u2 : entity work.PulseShaper
      port map (
         clk     => clk,
         rst     => rst,
         len     => std_logic_vector(to_unsigned(G_DATA_BITS*2,32)),
         dly     => (others => '0'),
         din     => dbgInterr_s,
         dou     => dbgInterr
      );


end behav;
