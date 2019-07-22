library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UtilityPkg.all;
use work.QpixPkg.all;

entity QpixAsicSim is
   generic (
      GATE_DELAY_G : time := 1 ns;
      X_POS        : natural;
      Y_POS        : natural
   );
   port (
      -- Simulation ports
      clkDelay      : in time;
      clkPeriod     : in time;
      -- Physical ports
      txConnections : out slv(3 downto 0);
      rxConnections :  in slv(3 downto 0)
   );
end QpixAsicSim;

architecture Behavioral of QpixAsicSim is

   signal coreClk : sl;
   signal coreRst : sl;

   signal rxByte           : Word64Array(3 downto 0);
   signal rxByteValid      : slv(3 downto 0);
   signal txByte           : Word64Array(3 downto 0);
   signal txByteValid      : slv(3 downto 0);
   signal txByteReady      : slv(3 downto 0);

   signal rxFifoReadEn     : slv(3 downto 0);
   signal rxFifoData       : Word64Array(3 downto 0);
   signal rxFifoValid      : slv(3 downto 0);
   signal rxFifoOflow      : slv(3 downto 0);
   signal rxFifoFull       : slv(3 downto 0);
   signal rxFifoEmpty      : slv(3 downto 0);

begin

   --------------------------------
   -- Simulation only constructs --
   --------------------------------
   U_ClkRst : entity work.ClkRst
      generic map (
         RST_HOLD_TIME_G   => 1 us -- : time    := 6 us;  -- Hold reset for this long
      )
      port map (
         CLK_PERIOD_G => clkPeriod, -- : time    := 10 ns;
         CLK_DELAY_G  => clkDelay,  -- : time    := 1 ns;  -- Wait this long into simulation before asserting reset
         clkP => coreClk, -- : out sl := '0';
         clkN => open,    -- : out sl := '1';                        -- Inverted clock
         rst  => coreRSt, -- : out sl := '1';
         rstL => open     -- : out sl := '0'
      );

   ------------------------------
   -- Synthesizable Constructs --
   ------------------------------
   G_UartInterfaces : for i in 3 downto 0 generate
      U_Uart : entity work.UartTop
         generic map (
            NUM_BITS_G   => 64,
            GATE_DELAY_G => GATE_DELAY_G
         )
         port map (
            clk         => coreClk,          -- : in  std_logic;
            sRst        => coreRst,          -- : in  std_logic;
            rxByte      => rxByte(i),        -- : out std_logic_vector(7 downto 0);
            rxByteValid => rxByteValid(i),   -- : out std_logic;
            txByte      => txByte(i),        -- : in  std_logic_vector(7 downto 0) := (others => '0');
            txByteValid => txByteValid(i),   -- : in  std_logic := '0';
            txByteReady => txByteReady(i),   -- : out std_logic;
            uartRx      => rxConnections(i), -- : in  std_logic;
            uartTx      => txConnections(i)  -- : out std_logic
         );
      U_RxFifo : entity work.FifoSync
         generic map (
            TPD_G          => GATE_DELAY_G, 
            --RST_POLARITY_G : sl                         := '1';  -- '1' for active high rst, '0' for active low
            --RST_ASYNC_G    : boolean                    := false;
            --BRAM_EN_G      : boolean                    := true;
            --BYP_RAM_G      : boolean                    := false;
            FWFT_EN_G      => true, --: boolean                    := false;
            --USE_DSP48_G    : string                     := "no";
            --ALTERA_SYN_G   : boolean                    := false;
            --ALTERA_RAM_G   : string                     := "M9K";
            --PIPE_STAGES_G  : natural range 0 to 16      := 0;
            DATA_WIDTH_G   => 64, --: integer range 1 to (2**24) := 16;
            ADDR_WIDTH_G   => 8,  --: integer range 4 to 48      := 4;
            --INIT_G         : slv                        := "0";
            FULL_THRES_G   => 255, --: integer range 1 to (2**24) := 1;
            EMPTY_THRES_G  => 1    --: integer range 1 to (2**24) := 1
         )
         port map (
            rst          => coreRst,         --: in  sl := not RST_POLARITY_G;
            clk          => coreClk,         --: in  sl;
            wr_en        => rxByteValid(i),  --: in  sl;
            rd_en        => rxFifoReadEn(i), --: in  sl;
            din          => rxByte(i),       --: in  slv(DATA_WIDTH_G-1 downto 0);
            dout         => rxFifoData(i),   --: out slv(DATA_WIDTH_G-1 downto 0);
            data_count   => open,            --: out slv(ADDR_WIDTH_G-1 downto 0);
            wr_ack       => open,            --: out sl;
            valid        => rxFifoValid(i),  --: out sl;
            overflow     => rxFifoOflow(i),  --: out sl;
            underflow    => open,            --: out sl;
            prog_full    => open,            --: out sl;
            prog_empty   => open,            --: out sl;
            almost_full  => open,            --: out sl;
            almost_empty => open,            --: out sl;
            full         => rxFifoFull(i),   --: out sl;
            not_full     => open,            --: out sl;
            empty        => rxFifoEmpty(i)   --: out sl);
         );


   end generate;
   U_QpixDaqHub : entity work.QpixDaqHub
      generic map (
         PASS_THROUGH_G => true,  -- : 
         X_POS          => X_POS, -- : natural,
         Y_POS          => Y_POS  -- : natural
      )
      port map (
         clk          => coreClk,      -- : in  std_logic;
         rst          => coreRst,      -- : in  std_logic;
         rxFifoData   => rxFifoData,   -- : in  Word64Array(3 downto 0);
         rxFifoValid  => rxFifoValid,  -- : in  std_logic_vector(3 downto 0);
         rxFifoReadEn => rxFifoReadEn, -- : out std_logic_vector(3 downto 0);
         rxFifoFull   => rxFifoFull,   -- : in  std_logic_vector(3 downto 0);
         rxFifoEmpty  => rxFifoEmpty,  -- : in  std_logic_vector(3 downto 0);
         rxFifoOflow  => rxFifoOflow,  -- : in  std_logic_vector(3 downto 0);
         txData       => txByte,       -- : out Word64Array(3 downto 0);
         txDataValid  => txByteValid,  -- : out std_logic_vector(3 downto 0);
         txDataReady  => txByteReady   -- : in  std_logic_vector(3 downto 0)
      );

end Behavioral;

