library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;
use work.QpixProtoPkg.all;

entity QpixTxRxTestTop is
   generic (
      BOARD_G : string  := "ZYBO"; -- ZYBO, MINIZED, PYNQ
      TXRX_TYPE : string  := "ENDEAVOR"; -- "DUMMY"/"UART"/"ENDEAVOR"
      X_NUM_G : natural := 3;
      Y_NUM_G : natural := 3 
      
   );
   port (
      sysClk    : in std_logic;
      led       : out std_logic_vector(3 downto 0);
      daqtx        : out std_logic;
      daqrx        : in  std_logic;

      -- PS ports
      DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
      DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
      DDR_cas_n : inout STD_LOGIC;
      DDR_ck_n : inout STD_LOGIC;
      DDR_ck_p : inout STD_LOGIC;
      DDR_cke : inout STD_LOGIC;
      DDR_cs_n : inout STD_LOGIC;
      DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
      DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
      DDR_odt : inout STD_LOGIC;
      DDR_ras_n : inout STD_LOGIC;
      DDR_reset_n : inout STD_LOGIC;
      DDR_we_n : inout STD_LOGIC;
      FIXED_IO_ddr_vrn : inout STD_LOGIC;
      FIXED_IO_ddr_vrp : inout STD_LOGIC;
      FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
      FIXED_IO_ps_clk : inout STD_LOGIC;
      FIXED_IO_ps_porb : inout STD_LOGIC;
      FIXED_IO_ps_srstb : inout STD_LOGIC
      
   );
end entity QpixTxRxTestTop;

architecture behav of QpixTxRxTestTop is

   signal fclk : std_logic;
   signal clk  : std_logic := '0';
   signal rst  : std_logic := '0';

    -- ps-pl axi
   signal axi_resetn  : std_logic_vector(0 downto 0) := (others => '1');
   signal axi_awaddr  : std_logic_vector ( 31 downto 0 );
   signal axi_awprot  : std_logic_vector ( 2 downto 0 );
   signal axi_awvalid : std_logic;
   signal axi_awready : std_logic;
   signal axi_wdata   : std_logic_vector ( 31 downto 0 );
   signal axi_wstrb   : std_logic_vector ( 3 downto 0 );
   signal axi_wvalid  : std_logic;
   signal axi_wready  : std_logic;
   signal axi_bresp   : std_logic_vector ( 1 downto 0 );
   signal axi_bvalid  : std_logic;
   signal axi_bready  : std_logic;
   signal axi_araddr  : std_logic_vector ( 31 downto 0 );
   signal axi_arprot  : std_logic_vector ( 2 downto 0 );
   signal axi_arvalid : std_logic;
   signal axi_arready : std_logic;
   signal axi_rdata   : std_logic_vector ( 31 downto 0 );
   signal axi_rresp   : std_logic_vector ( 1 downto 0 );
   signal axi_rvalid  : std_logic;
   signal axi_rready  : std_logic;

   signal reg_addr    : std_logic_vector (31 downto 0);
   signal reg_rdata   : std_logic_vector (31 downto 0);
   signal reg_wdata   : std_logic_vector (31 downto 0);
   signal reg_req     : std_logic := '0';
   signal reg_wen     : std_logic := '0';
   signal reg_ack     : std_logic := '0';

   --signal daqTx       : QpixTxRxPortType := QpixTxRxPortZero_C;
   --signal daqRx       : QpixTxRxPortType := QpixTxRxPortZero_C;

   signal TxPortsArr  : QpixTxRxPortsArrType;
   signal RxPortsArr  : QpixTxRxPortsArrType;

   signal hitMask     : Sl2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1) := (others => (others => '0')) ;

   signal swRst       : std_logic := '0';
   signal trg         : std_logic := '0';
   signal asicAddr    : std_logic_vector(31 downto 0) := (others => '0');
   signal asicOpWrite : std_logic := '0';
   signal asicData    : std_logic_vector(15 downto 0);
   signal asicReq     : std_logic := '0';
   --signal hitXY       : std_logic_vector (31 downto 0) := (others => '0');
   signal timestamp    : std_logic_vector (G_TIMESTAMP_BITS-1 downto 0) := (others => '0');
   signal chanMask     : std_logic_vector (G_N_ANALOG_CHAN-1 downto 0)  := (others => '0');
   signal trgTime      : std_logic_vector (31 downto 0) := (others => '0');

   signal evtSize     : std_logic_vector (31 downto 0) := (others => '0');

   signal memAddrRst  : std_logic := '0';
   signal memRdAddr   : std_logic_vector (G_QPIX_PROTO_MEM_DEPTH-1+2 downto 0) := (others => '0');
   signal memDataOut  : std_logic_vector (31 downto 0) := (others => '0');
   signal memRdAck    : std_logic := '0';
   signal memRdReq    : std_logic := '0';
   signal memEvtSize  : std_logic_vector (G_QPIX_PROTO_MEM_DEPTH-1 downto 0) := (others => '0');

   signal leds        : std_logic_vector(3 downto 0) := (others => '0');

   signal qpixDebugArr : QpixDebug2DArrayType(0 to X_NUM_G-1, 0 to Y_NUM_G-1);

   signal extFifoMaxArr : Slv4b2DArray(0 to X_NUM_G-1, 0 to Y_NUM_G-1);

   signal status      : std_logic_vector(31 downto 0) := (others => '0');

   signal asic_mask   : std_logic_vector (15 downto 0) ;

   signal qClk        : std_logic := '0';

   signal daqFrameErrCnt : std_logic_vector (31 downto 0) := (others => '0');
   signal daqBreakErrCnt : std_logic_vector (31 downto 0) := (others => '0');

   signal daqTestWordOut : std_logic_vector(G_DATA_BITS-1 downto 0);
   signal daqTestWordIn  : std_logic_vector(G_DATA_BITS-1 downto 0);

   signal ledCnt         : std_logic_vector(31 downto 0) := (others => '0');

begin

   process (fclk)
   begin
      if rising_edge(fclk) then
         ledCnt <= ledCnt + 1;
         if ledCnt >= x"1DCD_6500" then
            ledCnt <= (others => '0');
            leds(0) <= not leds(0);
         end if;
      end if;
   end process;
   leds(2) <= '1';
   led <= leds;


   ---------------------------------------------------
   -- Processing system
   ---------------------------------------------------
      design_1_U : entity work.design_1_wrapper
         port map (
            -- PS ports
            DDR_addr(14 downto 0)     => DDR_addr(14 downto 0),
            DDR_ba(2 downto 0)        => DDR_ba(2 downto 0),
            DDR_cas_n                 => DDR_cas_n,
            DDR_ck_n                  => DDR_ck_n,
            DDR_ck_p                  => DDR_ck_p,
            DDR_cke                   => DDR_cke,
            DDR_cs_n                  => DDR_cs_n,
            DDR_dm(3 downto 0)        => DDR_dm(3 downto 0),
            DDR_dq(31 downto 0)       => DDR_dq(31 downto 0),
            DDR_dqs_n(3 downto 0)     => DDR_dqs_n(3 downto 0),
            DDR_dqs_p(3 downto 0)     => DDR_dqs_p(3 downto 0),
            DDR_odt                   => DDR_odt,
            DDR_ras_n                 => DDR_ras_n,
            DDR_reset_n               => DDR_reset_n,
            DDR_we_n                  => DDR_we_n,
            FIXED_IO_ddr_vrn          => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp          => FIXED_IO_ddr_vrp,
            FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
            FIXED_IO_ps_clk           => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb          => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb         => FIXED_IO_ps_srstb,

            reset_rtl                 => '0',
            -- axi interface to PL
            M_AXI_0_awaddr            => axi_awaddr,
            M_AXI_0_awprot            => axi_awprot, 
            M_AXI_0_awvalid           => axi_awvalid,
            M_AXI_0_awready           => axi_awready,
            M_AXI_0_wdata             => axi_wdata,  
            M_AXI_0_wstrb             => axi_wstrb,  
            M_AXI_0_wvalid            => axi_wvalid, 
            M_AXI_0_wready            => axi_wready, 
            M_AXI_0_bresp             => axi_bresp,  
            M_AXI_0_bvalid            => axi_bvalid, 
            M_AXI_0_bready            => axi_bready, 
            M_AXI_0_araddr            => axi_araddr, 
            M_AXI_0_arprot            => axi_arprot, 
            M_AXI_0_arvalid           => axi_arvalid,
            M_AXI_0_arready           => axi_arready,
            M_AXI_0_rdata             => axi_rdata,  
            M_AXI_0_rresp             => axi_rresp,  
            M_AXI_0_rvalid            => axi_rvalid, 
            M_AXI_0_rready            => axi_rready, 
            --aresetn                   => axi_resetn,
            fclk                      => fclk

            -- CLK Wizard
            --reset_rtl_0               => '0',
            --sys_clock                 => sysClk,
            --clk_out1_0                => clk,
            --locked_0                  => open
         );

   ---------------------------------------------------
   -- AXI Lite interface
   ---------------------------------------------------
   AxiLiteSlaveSimple_U : entity work.AxiLiteSlaveSimple
      port map(
         axi_aclk              => fclk,
         axi_aresetn           => axi_resetn(0),

         axi_awaddr            => axi_awaddr,
         axi_awprot            => axi_awprot, 
         axi_awvalid           => axi_awvalid,
         axi_awready           => axi_awready,
         axi_wdata             => axi_wdata,  
         axi_wstrb             => axi_wstrb,  
         axi_wvalid            => axi_wvalid, 
         axi_wready            => axi_wready, 
         axi_bresp             => axi_bresp,  
         axi_bvalid            => axi_bvalid, 
         axi_bready            => axi_bready, 
         axi_araddr            => axi_araddr, 
         axi_arprot            => axi_arprot, 
         axi_arvalid           => axi_arvalid,
         axi_arready           => axi_arready,
         axi_rdata             => axi_rdata,  
         axi_rresp             => axi_rresp,  
         axi_rvalid            => axi_rvalid, 
         axi_rready            => axi_rready, 

         addr                  => reg_addr, 
         rdata                 => reg_rdata,
         wdata                 => reg_wdata,
         req                   => reg_req,
         wen                   => reg_wen,
         ack                   => reg_ack
      );
   ---------------------------------------------------

   ---------------------------------------------------
   ---------------------------------------------------
   QpixProtoRegMap_U : entity work.QpixProtoRegMap
   generic map (
      X_NUM_G => X_NUM_G,
      Y_NUM_G => Y_NUM_G
   )
   port map(
      clk          => fclk,
      rst          => rst,
                   
      addr         => reg_addr,
      rdata        => reg_rdata,
      wdata        => reg_wdata,
      req          => reg_req,
      wen          => reg_wen,
      ack          => reg_ack,

      asic_mask    => asic_mask,

      evtSize      => evtSize,
      status       => status,
      extFifoMax   => extFifoMaxArr,

      daqFrameErrCnt => daqFrameErrCnt,
      daqBreakErrCnt => daqBreakErrCnt,

      trgTime      => trgTime,
      timestamp    => timestamp,
      hitMask      => hitMask,
      chanMask     => chanMask,
      swRst        => swRst,
                  
      trg          => trg,
      asicAddr     => asicAddr,
      asicOpWrite  => asicOpWrite,
      asicData     => asicData,
      asicReq      => asicReq,

      memRdReq     => memRdReq,
      memRdAck     => memRdAck,
      memData      => memDataOut,
      memAddr      => memRdAddr,

      daqTestWordOut => daqTestWordOut,
      daqTestWordIn  => daqTestWordIn
   );
   ---------------------------------------------------

   -----------------------------------------------------
   ---- DAQ node
   -----------------------------------------------------
   QpixDaqCtrl_U : entity work.QpixDaqCtrlDummy
   port map(
      clk         => fclk,
      rst         => swRst,
                  
      daqTx       => daqTx,
      daqRx       => daqRx,

      sndWord     => daqTestWordOut,
      recWord     => daqTestWordIn,

      trg         => trg,
      busy        => status(0)
   );
   memAddrRst <= trg or asicReq;
   ---------------------------------------------------

   --RxPortsArr(0) <= daqTx;
   --daqRx <= TxPortsArr(0);

   --QpixAsicDummyTop_u1 : entity work.QpixAsicDummyTop
   --port map (
      --clk             => fclk,
      --rst             => '0',
      ---- TX ports to neighbour ASICs
      --Tx      => TxPortsArr(0),
      ---- RX ports to neighbour ASICs
      --Rx      => RxPortsArr(0)
   --);
   
end behav;
