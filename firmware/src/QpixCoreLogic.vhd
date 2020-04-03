library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.UtilityPkg.all;
use work.QpixPkg.all;

entity QpixCoreLogic is
   generic (
      X_POS          : natural;
      Y_POS          : natural;
      GATE_DELAY_G   : time    := 1 ns
   );
   port (
      clk          : in  std_logic;
      rst          : in  std_logic;
      rxFifoData   : in  Word64Array(3 downto 0);
      rxFifoValid  : in  std_logic_vector(3 downto 0);
      rxFifoReadEn : out std_logic_vector(3 downto 0);
      rxFifoFull   : in  std_logic_vector(3 downto 0);
      rxFifoEmpty  : in  std_logic_vector(3 downto 0);
      rxFifoOflow  : in  std_logic_vector(3 downto 0);
      txData       : out Word64Array(3 downto 0);
      txDataValid  : out std_logic_vector(3 downto 0);
      txDataReady  : in  std_logic_vector(3 downto 0)
   );
end QpixCoreLogic;

architecture Behavioral of QpixCoreLogic is

   type StateType is (IDLE_S, CHECK_TOKEN_S, RESPOND_S, PASS_TOKEN_S, WAIT_FINISH_S, DONE_S);

   type RegType is record
      state           : StateType;
      rrLink          : unsigned(1 downto 0);
      upstreamPartner : integer;
      rxFifoReadEn    : slv(3 downto 0);
      nHops           : unsigned(7 downto 0);
      xPos            : unsigned(3 downto 0);
      yPos            : unsigned(3 downto 0);
      lastTimestamp   : slv(31 downto 0);
   end record;
   
   constant REG_INIT_C : RegType := (
      state           => IDLE_S,
      rrLink          => (others => '0'),
      upstreamPartner => 0,
      rxFifoReadEn    => (others => '0'),
      xPos            => (others => '0'),
      yPos            => (others => '0'),
      nHops           => (others => '0'),
      lastTimestamp   => (others => '0')
   );
   
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

begin

   -- Asynchronous state logic
   process(curReg, rxFifoData, rxFifoValid, rxFifoFull, rxFifoEmpty, rxFifoOflow, txDataReady) begin
      -- Set defaults
      nxtReg <= curReg;
      nxtReg.rxFifoReadEn <= (others => '0');

      -- Actual state definitions
      case(curReg.state) is
         when IDLE_S  =>
            --Constantly rotate the priorty of the link to check
            nxtReg.rrLink <= curReg.rrLink + 1;
            -- If we have a non-empty FIFO, we're definitely moving to next state
            if rxFifoEmpty /= "1111" then
               nxtReg.state <= CHECK_TOKEN_S;
            end if;
            -- Accept from just one source, with priority depending on rrLink
            if rxFifoEmpty(integer(curReg.rrLink)) = '0' then
               nxtReg.upstreamPartner <= integer(curReg.rrLink);
            elsif rxFifoEmpty(integer(curReg.rrLink + 1)) = '0' then
               nxtReg.upstreamPartner <= integer(curReg.rrLink + 1);
            elsif rxFifoEmpty(integer(curReg.rrLink + 2)) = '0' then
               nxtReg.upstreamPartner <= integer(curReg.rrLink + 2);
            elsif rxFifoEmpty(integer(curReg.rrLink + 3)) = '0' then
               nxtReg.upstreamPartner <= integer(curReg.rrLink + 3);
            end if;
         when CHECK_TOKEN_S => 
            -- Assert read enable for the data coming from our upstream partner
            nxtReg.rxFifoReadEn(curReg.upstreamPartner) <= '1';
            -- Check the inbound data
            -- bits 63:60 - 
            -- bits 59:56 - type - x0 - TS broadcast, 
            --                     x1 - TS reply (last word of data packet)
            --                     x2 - standard data word
            --                     x3 - register transaction transmit
            --                     x4 - register response
            --                 others - reserved
            -- bits 55:48 - unsigned number of hops so far
            -- bits 47:40 - unsigned y-position
            -- bits 39:32 - unsigned x-position
            -- bits 31:00 - unsigned timestamp
            if rxFifoData(curReg.upstreamPartner)(63 downto 56) = x"00" then
               nxtReg.lastTimestamp <= rxFifoData(curReg.upstreamPartner)(31 downto 0);
               nxtReg.
            end if;
            nxtReg.xPos  <= rxFifoData(curReg.upstreamPartner)(47 downto 40);
            nxtReg.yPos  <= rxFifoData(curReg.upstreamPartner)(55 downto 48);
            nxtReg.nHops <= rxFifoData(curReg.upstreamPartner)(39 downto 32);
         when RESPOND_S =>
         when PASS_TOKEN_S =>
         when WAIT_FINISH_S => 
         when DONE_S =>
            -- Bleed away data from all other sources
            if curReg.rxFifoEmpty = "1111" then
               nxtReg.IDLE_S;
            else
               nxtReg.rxFifoReadEn <= (others => '1');               
            end if;
         when others  =>
            nxtReg.state <= IDLE_S;
      end case;         
   end process;
   
   -- Synchronous part of state machine, including reset
   process(clk) begin
      if rising_edge(clk) then
         if (rst = '1') then
            curReg <= REG_INIT_C after GATE_DELAY_G;
         else
            curReg <= nxtReg after GATE_DELAY_G;
         end if;
      end if;
   end process;


end Behavioral;


