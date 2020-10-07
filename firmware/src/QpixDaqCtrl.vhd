library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

entity QpixDaqCtrl is
   generic (
      MEM_DEPTH : natural := 9 
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;
      
      -- readout ASIC ports
      daqTx    : out QpixTxRxPortType;
      daqRx    : in  QpixTxRxPortType;

      trg         : in std_logic;
      asicReq     : in std_logic;
      asicOpWrite : in std_logic;
      asicData    : in std_logic_vector(15 downto 0);
      asicAddr    : in std_logic_vector(31 downto 0);
      
      
      --asicX      : in std_logic_vector(G_POS_BITS-1 downto 0);
      --asicY      : in std_logic_vector(G_POS_BITS-1 downto 0);
      --asicAddr   : in std_logic_vector(G_REG_ADDR_BITS-1 downto 0);
      --qpixReq    : QpixRegReqType;
      
      trgTime    : out std_logic_vector(31 downto 0);

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

   signal regData         : QpixRegDataType := QpixRegDataZero_C;

   signal clkCnt          : std_logic_vector(31 downto 0) := (others => '0');

begin

   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            trgTime <= (others => '0');
            clkCnt  <= (others => '0');
         else
            clkCnt <= clkCnt + 1;
            if trg = '1' then
               trgTime <= clkCnt;
            end if;
         end if;
      end if;
   end process;

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

      uartTx      => daqTx,
      uartRx      => daqRx

   );

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
      memData(127 downto 96) when b"11";
   

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
         if rst or memAddrRst then
            wrAddr     <= (others => '0');
         else
            if daqRxByteValid then
               wrAddr <= wrAddr + 1;
            end if;
         end if;
      end if;
   end process;

   memEvtSize <= std_logic_vector(resize(unsigned(wrAddr),32));

   -- accept trigger and send interrogation
   process (clk)
      variable r : QpixRegDataType := QpixRegDataZero_C;
   begin
      if rising_edge (clk) then
         r := QpixRegDataZero_C;
         if trg = '1' then
            r.Addr := x"0001"; 
            r.Data := x"0001";
            r.OpWrite := '1';
            r.OpRead  := '0';
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
            daqTxByte      <= fQpixRegToByte(r);
            daqTxByteValid <= '1';
         else
            daqTxByteValid <= '0';
         end if;
      end if;
   end process;

   --QpixDaqStorage_U : entity work.QpixDaqStorage_U
   --port map(
      --clk => clk,
   --);


end behav;
