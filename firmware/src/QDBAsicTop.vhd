library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- qpix things
library work;
use work.QpixPkg.all;

-- std rtl things
use work.stdrtlpkg.all;

-- ice things
--library ice;
--use ice.all;

entity QDBAsicTop is
   generic (
      X_POS_G      : natural := 0;
      Y_POS_G      : natural := 0;
      pulse_time   : natural :=  1_999_999;
      fake_trg_cnt : natural := 19_999_999;
      RAM_TYPE     : string  := "Lattice"; -- 'Lattice' hardcodes BRAM for lattice, or distributed / block
      TXRX_TYPE    : string  := "ENDEAVOR" -- "DUMMY"/"UART"/"ENDEAVOR"
    );
port (
    -- internal clock
    clk : in STD_LOGIC;
--    rst : in STD_LOGIC;

    -- Tx/Rx IO
    --Tx1 : out STD_LOGIC; -- North
    --Rx1 : in STD_LOGIC;
    --Tx2 : out STD_LOGIC; -- East
    --Rx2 : in STD_LOGIC;
    Tx3 : out STD_LOGIC; -- South
    Rx3 : in STD_LOGIC;
    --Tx4 : out STD_LOGIC; -- West
    --Rx4 : in STD_LOGIC;

    -- extra IO, hardcode IO for now
    --IO : in STD_LOGIC_VECTOR(3 downto 0);

    -- optional ss pins -- south Top
     --ss  : in  std_logic;  -- south 8   /  north 6
    so  : in std_logic;  -- south 6   /  north 4
    si  : out std_logic;  -- south 4   /  north 2
    --sck : in std_logic;   -- south 2   /  north 8

    -- outputs
    red_led : out STD_LOGIC;
    blu_led : out STD_LOGIC;
    gre_led : out STD_LOGIC
    );

end QDBAsicTop;


architecture Behavioral of QDBAsicTop is

  -- timestamp and QDBAsic specifics
  --signal clk          : std_logic;
  signal fast_clk     : std_logic;
  signal pllClk       : std_logic;
  signal fake_trg     : std_logic              := '0';
  signal rst          : std_logic              := '0';
  signal localCnt     : unsigned (31 downto 0) := (others => '0');
  signal slv_localCnt : std_logic_vector(31 downto 0);
  signal pulse_red    : std_logic              := '0';
  signal pulse_blu    : std_logic              := '0';
  signal pulse_gre    : std_logic              := '0';
  signal data_i1      : std_logic              := '0';
  signal data_i2      : std_logic              := '0';
  signal data         : std_logic              := '0';
  signal enabled      : boolean                := false;
  signal rising       : boolean                := false;
  -- fast signals which sample the input of channel data and need to be
  -- synchronized back to 12 MHz
  signal data_fi1 : std_logic := '0';
  signal data_fi2 : std_logic := '0';
  signal data_f   : std_logic := '0';

  signal TxPortsArr         : std_logic_vector(3 downto 0);
  signal RxPortsArr         : std_logic_vector(3 downto 0);
  signal inData             : QpixDataFormatType := QpixDataZero_C;
  signal txData             : QpixDataFormatType := QpixDataZero_C;
  signal rxData             : QpixDataFormatType := QpixDataZero_C;
  signal regData            : QpixRegDataType    := QpixRegDataZero_C;
  signal regResp            : QpixRegDataType    := QpixRegDataZero_C;
  signal qpixConf           : QpixConfigType     := QpixConfigDef_C;
  signal QpixReq            : QpixRequestType    := QpixRequestZero_C;
  signal TxReady            : std_logic          := '0';
  signal debug              : QpixDebugType      := QpixDebugZero_C;
  signal route_state        : std_logic_vector(3 downto 0);
  
  
component qdb_pll is
    port(
        ref_clk_i: in std_logic;
        rst_n_i: in std_logic;
        outcore_o: out std_logic;
        outglobal_o: out std_logic
    );
end component;

component HSOSC
GENERIC( CLKHF_DIV :string :="0b00");
PORT(
       CLKHFEN : IN  STD_LOGIC;
       CLKHFPU : IN  STD_LOGIC;
       CLKHF   : OUT STD_LOGIC);
END COMPONENT;

begin

    -- LEDs, active LOW (on when value is '0')
    red_led <= not '0';
    blu_led <= not pulse_blu;
    gre_led <= not pulse_gre;
    
	-- clock output to physical
	si <= clk;
    --so <= pllClk;

    -- connect Tx/Rx to the signals
    --Tx1 <= TxPortsArr(0);
    --RxPortsArr(0) <= Rx1;
    --Tx2 <= TxPortsArr(1);
    --RxPortsArr(1) <= Rx2;
    Tx3 <= TxPortsArr(2);
    RxPortsArr(2) <= Rx3;
    --Tx4 <= TxPortsArr(3);
    --RxPortsArr(3) <= Rx4;
    --RxPortsArr(3) <= '0';

    
    -- used to buffer readout on timing measurement
    -- si <= clk;
--    rst <= QpixReq.AsicReset;

    -- use the fast clock to read the input of the data
    -- internal oscillator, generate 50 MHz clk
    --u_osc : HSOSC
    --GENERIC MAP(CLKHF_DIV =>"0b00")
    --port map(
        --CLKHFEN  => '1',
        --CLKHFPU  => '1',
        --CLKHF    => fast_clk
    --);

  -- pll to hopefully improve frequency stabilization
  --u_pll : qdb_pll port map(
    --ref_clk_i   =>  fast_clk,
    --rst_n_i     =>  '1', -- active low
    --outcore_o   =>  pllClk,
    --outglobal_o => open
--);

    --process(pllClk) is
      --variable count : integer range 0 to 2 := 0;
    --begin
      --if rising_edge(pllClk) then
        --count := count + 1;
        --if count = 2 then
          --clk <= not clk;
          --count := 0;
        --end if;
      --end if;
    --end process;

--  -- create a 1 second pulse width when either Tx or Rx goes high
 pulse : process (all) is
     variable pulse_count_red : integer range 0 to pulse_time := 0;
     variable start_pulse_red : std_logic := '0';
     variable pulse_count_blu : integer range 0 to pulse_time := 0;
     variable start_pulse_blu : std_logic := '0';
     variable pulse_count_gre : integer range 0 to pulse_time := 0;
     variable start_pulse_gre : std_logic := '0';
 begin
     if rising_edge(clk) then

         -- pulse Red
         -- if QpixReq.Interrogation = '1' then -- goes low after trg / this is a trigger
		 if QpixConf.locEnaReg = '1' then
         -- if regResp.Valid = '1' then
         -- if route_state(0) = '1' then -- (temp!) high when IDLE_S  -- also loops here continually
         -- if route_state(2) = '1' then -- high when REP_FINISH_S -- does NOT go low after trg
             start_pulse_red := '1';
             pulse_count_red := 0;
         end if;
         if start_pulse_red = '1' then
             pulse_count_red := pulse_count_red + 1;
             pulse_red <= '1';
             if pulse_count_red >= pulse_time then
                 pulse_red       <= '0';
                 pulse_count_red := 0;
                 start_pulse_red := '0';
             end if;
         end if;

         -- pulse Blue
         -- if regResp.valid = '1' then
		 if QpixConf.locEnaSnd = '1' then
		 -- if enabled = true then
		 -- if data = '1' then
		 -- if qpixConf.DirMask(2) = '1' then
         -- if route_state(3) = '1' then -- high when REP_REGRSP_S -- does not go low after trg?
         -- if route_state(0) = '1' then -- high when REP_LOCAL_S, does not go low after trg
             start_pulse_blu := '1';
             pulse_count_blu := 0;
         end if;
         if start_pulse_blu = '1' then
             pulse_count_blu := pulse_count_blu + 1;
             pulse_blu <= '1';
             if pulse_count_blu >= pulse_time then
                 pulse_blu       <= '0';
                 pulse_count_blu := 0;
                 start_pulse_blu := '0';
             end if;
         end if;

         -- pulse Green
         -- if route_state(1) = '1' then -- high when REP_REMOTE_S
         -- inData.DataValid = '1' then
		 if QpixConf.locEnaRcv = '1' then
         -- if rising = true then
		 -- if rst = '1' then
         -- if TxPortsArr(2) = '1' then
         -- if qpixConf.ManRoute = '1' then
             start_pulse_gre := '1';
             pulse_count_gre := 0;
         end if;
         if start_pulse_gre = '1' then
             pulse_count_gre := pulse_count_gre + 1;
             pulse_gre <= '1';
             if pulse_count_gre >= pulse_time then
                 pulse_gre <= '0';
                 pulse_count_gre := 0;
                 start_pulse_gre := '0';
             end if;
         end if;

     end if;
 end process pulse;

   ----------------------------------------------------------
   -- syncrhonize ASIC internal data from 50 MHz to 12 MHz --
   ----------------------------------------------------------
   --process(fast_clk_pll,rst)
   --begin
      --if rising_edge(fast_clk_pll) then
         --if rst = '1' then
           --data_fi1 <= '0';
           --data_fi2 <= '0';
           --data_f    <= '0';
         --else
           --data_fi1 <= sck;
           --data_fi2 <= data_fi1;
           --data_f   <= data_fi2;
         --end if;
      --end if;
   --end process;
   -- put sck - data onto the 12 MHz clk
   process(clk,rst)
   begin
      if rising_edge(clk) then
         if rst = '1' then
           data_i1 <= '0';
           data_i2 <= '0';
           data    <= '0';
         else
           data_i1 <= so;
           data_i2 <= data_i1;
           data    <= data_i2;
         end if;
      end if;
   end process;


    -- connect external IO to QpixDataProc
    slv_localCnt <= std_logic_vector(localCnt);
    enabled <= boolean(QpixConf.locEnaSnd = '1' and QpixConf.locEnaRcv = '1' and QpixConf.locEnaReg = '1');
    process (clk)
      variable count : natural range 0 to 16 := 0;
      begin
         if rising_edge(clk) then

           -- keep track of rising edges on data
           if data = '0' then
             count := count + 1;
             if count >= 15 then
               rising <= true;
               count  := 0;
             end if;
           else
               count  := 0;
           end if;

           -- trigger conditions, only read on rising edge
           if data = '1' and enabled and rising then
             inData.DataValid <= '1';
             inData.TimeStamp <= slv_localCnt;
             rising <= false;
           --elsif fake_trg = '1' and not enabled then
             --inData.DataValid <= '1';
             --inData.TimeStamp <= slv_localCnt;
           else
             inData.DataValid <= '0';
             inData.TimeStamp <= (others => '0');
           end if;
         end if;
    end process;
    inData.wordtype  <= "1111"; -- inData word type is NOT used
    inData.ChanMask <=  (others => '1');
	inData.xpos     <= toslv(X_POS_G, 4);
    inData.ypos     <= toslv(Y_POS_G, 4);
    inData.data     <= x"aaaa_bbbb_cccc_dddd"; -- unused by fQpixRecordToByte
    inData.dirMask  <= DirDown;

    counter: process (clk) is
      variable count : integer := 0;
    begin
        if clk'event and clk = '1' then     -- rising clock edge
            count := count + 1;
            localCnt <= localCnt + 1;
          if count >= fake_trg_cnt then
            fake_trg <= '1';
            count := 0;
          else
            fake_trg <= '0';
          end if;
        end if;
    end process counter;
   ---------------------------------------------


   -----------------------------------------------
   -- Q-Pix data tranceiver
   -- data parsing / physical layer
   -----------------------------------------------

   QpixComm_U : entity work.QpixComm
   generic map(
      RAM_TYPE      => RAM_TYPE,
      TXRX_TYPE     => TXRX_TYPE,
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G)
   port map(
      clk            => clk,
      rst            => rst,
      -- route <-> parser
      parseDataRx    => txData,  -- record input to parser from route
      parseDataTx    => rxData,  -- record output from parser to route
      parseDataReady => TxReady, -- sl ready signal to route
      -- physical connections
      TxPortsArr     => TxPortsArr, -- slv output to physical
      RxPortsArr     => RxPortsArr, -- slv input form physical
      TxByteValidArr_out => open,
      RxByteValidArr_out => open,
      RxFifoEmptyArr_out => open,
      RxFifoFullArr_out  => open,
      -- reg file connections
      QpixConf       => QpixConf, -- record input
      regData        => regData,  -- output from parser
      regResp        => regResp); -- input from parser
   -----------------------------------------------

   -- Registers file
   -------------------------------------------------
   QpixRegFile_U : entity work.QpixRegFile
   generic map(
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G)
   port map(
      clk      => clk,
      rst      => rst,

      -- comm connections
      regData  => regData,  -- input record regData type, from parser
      regResp  => regResp,  -- output record regData type, to parser
      -- route connections
      QpixConf => QpixConf, -- record qpixConfigType
      QpixReq  => QpixReq   -- record qpixRequestType
      );
   -----------------------------------------------

   -------------------------------------------------
   -- Data routing between ASICs
   -------------------------------------------------
   QpixRoute_U : entity work.QpixRoute
   generic map(
      RAM_TYPE      => RAM_TYPE,
      X_POS_G       => X_POS_G,
      Y_POS_G       => Y_POS_G)
   port map(
      clk           => clk,
      rst           => rst,
      -- reg file connections
      QpixReq       => QpixReq,  -- input register from reg file
      QpixConf      => QpixConf, -- input register from reg file
      -- analog ASIC trigger connections
      inData        => inData,   -- input Data from Process, NOT inData to comm
      -- Qpixcomm connections
      TxReady       => TxReady, -- input ready signal from comm
      txData        => txData,  -- output record output to parser
      rxData        => rxData,  -- input record input from parser
      -- debug words:
      routeErr      => open,                     
      debug         => debug,
      state         => route_state,
      routeStateInt => open);
   -----------------------------------------------

end Behavioral;