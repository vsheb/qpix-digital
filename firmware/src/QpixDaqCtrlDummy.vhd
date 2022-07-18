library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.QpixPkg.all;

entity QpixDaqCtrlDummy is
   generic (
      TXRX_TYPE : string := "ENDEAVOR"
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;

      trg      : in  std_logic; 
      sndWord  : in  std_logic_vector(G_DATA_BITS-1 downto 0);
      recWord  : out std_logic_vector(G_DATA_BITS-1 downto 0);
      busy     : out std_logic;
      
      -- readout ASIC ports
      daqTx    : out QpixTxRxPortType;
      daqRx    : in  QpixTxRxPortType
   );
end entity QpixDaqCtrlDummy;


architecture behav of QpixDaqCtrlDummy is


   signal daqTxByte       : std_logic_vector(G_DATA_BITS-1 downto 0);
   signal daqTxByteValid  : std_logic := '0';
   signal daqTxByteReady  : std_logic := '0';

   signal daqRxByte       : std_logic_vector (G_DATA_BITS-1 downto 0);
   signal daqRxByteValid  : std_logic := '0';


   type   EvtCtrlStatesType is (IDLE_S, SEND_S, RECEIVE_S);
   signal evt_state : EvtCtrlStatesType := IDLE_S;

   signal daqRxFrameErr : std_logic := '0';
   signal daqRxBreakErr : std_logic := '0';

   signal daqFrameErrCnt : std_logic_vector (31 downto 0) := (others => '0');
   signal daqBreakErrCnt : std_logic_vector (31 downto 0) := (others => '0');


begin

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

   process (clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then 
            daqTxByteValid <= '0';
            evt_state <= IDLE_S;
         else
            daqTxByteValid <= '0';
            case evt_state is
               when IDLE_S => 
                  daqTxByte <= sndWord;
                  busy <= '0';
                  if trg = '1' then
                     evt_state <= SEND_S;
                     busy <= '1';
                  end if;
               when SEND_S => 
                  if daqTxByteReady = '1' then
                     daqTxByteValid <= '1';
                     evt_state <= RECEIVE_S;
                  end if;
               when RECEIVE_S => 
                  if daqRxByteValid = '1' then
                     recWord   <= daqRxByte;
                     evt_state <= IDLE_S;
                  end if;
            end case;
         end if;
      end if;
   end process;
   



end behav;
