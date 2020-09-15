library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

entity QpixDaqCtrl is
   generic (
      MEM_DEPTH : natural := 8 
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;
      
      -- readout ASIC ports
      daqTx    : out QpixTxRxPortType;
      daqRx    : in  QpixTxRxPortType;

      -- event memory ports
      memAddrRst : in std_logic;
      memRdAddr  : in  std_logic_vector(7 downto 0);
      memDataOut : out std_logic_vector(G_DATA_BITS-1 downto 0);
      memRdAck   : out std_logic;
      memEvtSize : out std_logic_vector(7 downto 0);
      memFullErr : out std_logic
      
   );
end entity QpixDaqCtrl;


architecture behav of QpixDaqCtrl is

   signal wrAddr      : std_logic_vector(MEM_DEPTH-1 downto 0) := (others => '0');
   signal rdAddr      : std_logic_vector(MEM_DEPTH-1 downto 0) := (others => '0');

   

begin

   QpixDummyTxRx_U : entity work.UartTop
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

      uartTx      => Tx,
      uartRx      => Rx

   );

   mem_U : entity work.bram_sdp_cc
   generic map (
      DATA => daqRxByte'length,
      ADDR => MEM_DEPTH
   )
   port map (
      clk   => clk,
      wea   => daqRxByteValid,
      addra => wrAddr,
      dina  => daqRxByte,
      addrb => memRdAddr,
      doutb => memDataOut
   );
   
   process (clk)
   begin
      if rising_edge (clk) then
         if rst or memAddrRst then
            wrAddr     <= (others => '0');
            memEvtSize <= (others => '0');
         else
            if daqRxByteValid then
               wrAddr <= wrAddr + 1;
            end if;
         end if;
      end if;
   end process;

   memEvtSize <= wrAddr;

   --QpixDaqStorage_U : entity work.QpixDaqStorage_U
   --port map(
      --clk => clk,
   --);


end behav;
