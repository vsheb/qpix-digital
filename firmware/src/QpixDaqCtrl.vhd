library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

-- std rtl things
use work.stdrtlpkg.all;

entity QpixDaqCtrl is
   generic (
      MEM_DEPTH : natural := 9;
      TXRX_TYPE : string  := "UART" -- "DUMMY"/"UART"/"ENDEAVOR"
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;
      
      -- readout ASIC ports
      daqTx    : out QpixTxRxPortType;
      daqRx    : in  QpixTxRxPortType;

      trg          : in std_logic;
      trgTime      : out std_logic_vector(31 downto 0);
      evt_fin      : out std_logic; 
      uartBreakCnt : out std_logic_vector(31 downto 0);
      uartFrameCnt : out std_logic_vector(31 downto 0);

      asicReq     : in std_logic;
      asicOpWrite : in std_logic;
      asicData    : in std_logic_vector(15 downto 0);
      asicAddr    : in std_logic_vector(31 downto 0);
      asic_mask   : in std_logic_vector(15 downto 0) := (others => '1');
      
      --asicX      : in std_logic_vector(G_POS_BITS-1 downto 0);
      --asicY      : in std_logic_vector(G_POS_BITS-1 downto 0);
      --asicAddr   : in std_logic_vector(G_REG_ADDR_BITS-1 downto 0);
      --qpixReq    : QpixRegReqType;
      
      -- event memory ports
      memEvtSize : out std_logic_vector(31 downto 0);
      memAddrRst : in  std_logic;
      memRdAddr  : in  std_logic_vector(MEM_DEPTH-1+2 downto 0);
      memRdReq   : in  std_logic;
      memDataOut : out std_logic_vector(31 downto 0);
      memRdAck   : out std_logic;
      memFullErr : out std_logic   
   );
end entity QpixDaqCtrl;


architecture behav of QpixDaqCtrl is

   signal wrAddr          : std_logic_vector(MEM_DEPTH-1 downto 0) := (others => '0');
   signal rdAddr          : std_logic_vector(MEM_DEPTH-1 downto 0) := (others => '0');

   signal memData         : std_logic_vector(G_DATA_BITS-1 + 64 downto 0);
   signal memRdReq_r      : std_logic := '0';

   signal daqTxByte       : std_logic_vector(G_DATA_BITS-1 downto 0);
   signal daqTxByteValid  : std_logic := '0';
   signal daqTxByteReady  : std_logic := '0';

   signal daqRxByte       : std_logic_vector (G_DATA_BITS-1 downto 0);
   signal daqRxByteValid  : std_logic := '0';

   -- signal regData         : QpixRegDataType := QpixRegDataZero_C;

   signal clkCnt          : std_logic_vector(31 downto 0) := (others => '0');

   signal asicReqID       : std_logic_vector(3 downto 0)  := x"1";

   signal asic_mask_evt   : std_logic_vector(8 downto 0)  := (others => '0');
   signal asic_mask_fin   : std_logic_vector(8 downto 0)  := (others => '0');

   signal ro_finished     : std_logic := '0';

   type   EvtCtrlStatesType is (EVT_CTRL_IDLE, EVT_CTRL_RUNNING);
   signal evt_state : EvtCtrlStatesType := EVT_CTRL_IDLE;

   signal daqRxFrameErr : std_logic := '0';
   signal daqRxBreakErr : std_logic := '0';
   -- signal daqRxGapErr   : std_logic := '0';

   signal daqFrameErrCnt : std_logic_vector (31 downto 0) := (others => '0');
   signal daqBreakErrCnt : std_logic_vector (31 downto 0) := (others => '0');

    -- simulation
    signal r_sig : QpixRegDataType := QpixRegDataZero_C;

begin

   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            trgTime <= (others => '0');
            clkCnt  <= (others => '0');
         else
            clkCnt <= clkCnt + 1;
            if trg = '1' or asicReq = '1' then
               trgTime <= clkCnt;
            end if;
         end if;
      end if;
   end process;

   UART_GEN : if TXRX_TYPE = "UART" generate 
      QpixUartTxRx_U : entity work.UartTop
      generic map (
         NUM_BITS_G => G_DATA_BITS
      )
      port map (
         clk         => clk,
         sRst        => rst,

         txByte      => daqTxByte, 
         txByteValid => daqTxByteValid, 
         txByteReady => daqTxByteReady,

         rxByte      => daqRxByte,
         rxByteValid => daqRxByteValid,
         rxFrameErr  => daqRxFrameErr,
         rxBreakErr  => daqRxBreakErr,

         uartTx      => daqTx,
         uartRx      => daqRx
      );
   end generate UART_GEN;

   ENDEAROV_GEN : if TXRX_TYPE = "ENDEAVOR" generate
      QpixUartTxRx_U : entity work.QpixEndeavorTop
      generic map (
         NUM_BITS_G => G_DATA_BITS
      )
      port map (
         clk         => clk,
         sRst        => rst,
         txByte      => daqTxByte, 
         txByteValid => daqTxByteValid, 
         txByteReady => daqTxByteReady,

         rxByte      => daqRxByte,
         rxByteValid => daqRxByteValid,
         rxFrameErr  => daqRxFrameErr,
         rxBreakErr  => daqRxBreakErr,
         rxGapErr    => open,
         rxState     => open,

         Tx          => daqTx,
         Rx          => daqRx
      );
   end generate ENDEAROV_GEN;

   process (clk)
   begin
      if rising_edge (clk) then
         if daqRxFrameErr = '1' then
            daqFrameErrCnt <= daqFrameErrCnt + 1;
         end if;
         if daqRxBreakErr = '1' then
            daqBreakErrCnt <= daqBreakErrCnt + 1;
         end if;
      end if;
   end process;

   uartFrameCnt <= daqFrameErrCnt;
   uartBreakCnt <= daqBreakErrCnt;

   --QpixDummyTxRx_U : entity work.QpixDummyTxRx
   --generic map (
      --NUM_BITS_G => G_DATA_BITS
   --)
   --port map (
      --clk         => clk,
      --rst         => rst,

      --txPort      => daqTx.Data,
      --txValid     => daqTx.Valid,
      --txByte      => daqTxByte, 
      --txByteValid => daqTxByteValid, 
      --txByteReady => daqTxByteReady,

      --rxPort      => daqRx.Data,
      --rxValid     => daqRx.Valid,
      --rxByte      => daqRxByte,
      --rxByteValid => daqRxByteValid
   --);

   mem_U : entity work.bram_sdp_cc
   generic map (
      DATA     => daqRxByte'length + 64,
      ADDR     => MEM_DEPTH,
      RAM_TYPE => "block" 
   )
   port map (
      clk   => clk,
      wea   => daqRxByteValid,
      addra => wrAddr,
      dina  => x"0000_0000" & clkCnt & daqRxByte,
      addrb => memRdAddr(memRdAddr'length-1 downto 2),
      doutb => memData
   );

   --memDataOut <= memData(31 downto 0) when memRdAddr(0) = '0' else memData(G_DATA_BITS-1 downto 32);
   with memRdAddr(1 downto 0) select memDataOut <=
      memData(31 downto 0)  when b"00",
      memData(63 downto 32) when b"01",
      memData(95 downto 64) when b"10",
      memData(127 downto 96) when b"11",
      x"abadda7a" when others;
   
  
   process (clk)
   begin
      if rising_edge (clk) then
         memRdReq_r <= memRdReq;
         memRdAck <= memRdReq_r;
      end if;
   end process;
   
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' or memAddrRst = '1' then
            wrAddr     <= (others => '0');
         else
            if daqRxByteValid = '1' then
               wrAddr <= wrAddr + 1;
            end if;
         end if;
      end if;
   end process;


   ------------------------------------------------------------
   -- make a flag indicating that all ASICs have been read out
   ------------------------------------------------------------
   process (clk)
      variable qpix_data_v : QpixDataFormatType := QpixDataZero_C;
      variable x : integer := 0;
      variable y : integer := 0;
   begin
      if rising_edge (clk) then
         case evt_state is 
            when EVT_CTRL_IDLE => 
               if trg = '1' then
                  ro_finished <= '0';
                  evt_state <= EVT_CTRL_RUNNING;
                  asic_mask_evt <= (others => '0');
               end if;
            when EVT_CTRL_RUNNING => 
               qpix_data_v := fQpixByteToRecord(daqRxByte); 
               x := to_integer(unsigned(qpix_data_v.XPos));
               y := to_integer(unsigned(qpix_data_v.YPos));
               if daqRxByteValid = '1' then
                  if qpix_data_v.WordType = G_WORD_TYPE_EVTEND then
                     asic_mask_evt(x + y*3) <= '1';
                     if asic_mask_evt(x + y*3) = '1' then
                        -- rise some error flag TODO
                     end if;
                  end if;
               end if;

               if asic_mask_evt = asic_mask_fin then
                  ro_finished <='1';
                  evt_state   <= EVT_CTRL_IDLE;
               end if;

         end case;
         
      end if;
   end process;

   evt_fin <= ro_finished;
   ------------------------------------------------------------

   memEvtSize <= std_logic_vector(resize(unsigned(wrAddr),32));

   -- accept trigger and send interrogation
   process (clk)
      variable r : QpixRegDataType := QpixRegDataZero_C;
   begin
      if rising_edge (clk) then
         r := QpixRegDataZero_C;
         if trg = '1' then
            r.Addr := toslv(1, G_REG_ADDR_BITS); 
            r.Data := x"0001";
            r.OpWrite := '1';
            r.OpRead  := '0';
            r.ReqID   := asicReqID;
            asicReqID <= asicReqID + 1;
            daqTxByte      <= fQpixRegToByte(r);
            daqTxByteValid <= '1';
         elsif asicReq = '1' then
            r.Addr(15 downto 4)   :=  (others => '0');
            r.Addr(2 downto 0)    := asicAddr(2 downto 0); 
            r.Dest    := asicAddr(9);
            r.XDest   := '0' & asicAddr(8 downto 6);
            r.YDest   := '0' & asicAddr(5 downto 3);
            r.Data    := asicData;
            r.OpWrite := asicOpWrite;
            r.OpRead  := not asicOpWrite;
            r.ReqID   := asicReqID;
            r.SrcDaq  := '1';
            daqTxByte      <= fQpixRegToByte(r);
            daqTxByteValid <= '1';
            asicReqID <= asicReqID + 1;
         else
            daqTxByteValid <= '0';
         end if;
         r_sig <= r;
      end if;
   end process;

   --QpixDaqStorage_U : entity work.QpixDaqStorage_U
   --port map(
      --clk => clk,
   --);


end behav;
