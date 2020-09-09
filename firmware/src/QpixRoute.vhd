----------------------------------------------------------------------------------
-- QPix routing module
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

entity QpixRoute is
   generic (
      GATE_DELAY_G    : time    := 1 ns;
      X_POS_G         : natural := 0;
      Y_POS_G         : natural := 0
   );
   port (
      clk             : in std_logic;
      rst             : in std_logic;
                      
      qpixReq         : in  QpixRequestType;
      qpixConf        : in  QpixConfigType;
                      
      inData          : in  QpixDataFormatType;
                      
      txReady         : in  std_logic;
      txData          : out QpixDataFormatType;

      rxData          : in  QpixDataFormatType;
                      
      routeStateInt   : out integer
      
   );
end entity QpixRoute;

architecture behav of QpixRoute is

   ---------------------------------------------------
   -- Types defenitions
   ---------------------------------------------------
   
   type RegType is record
      state      :  RouteStatesType;
      cnt        :  std_logic_vector(G_REG_DATA_BITS-1 downto 0);
      txData     :  QpixDataFormatType;
      locFifoRen :  std_logic;
      extFifoRen :  std_logic;
   end record;
   ---------------------------------------------------

   ---------------------------------------------------
   -- Constants
   ---------------------------------------------------
   constant REG_INIT_C : RegType := (
      state      => IDLE_S,
      cnt        => (others => '0'),
      txData     => QpixDataZero_C,
      locFifoRen => '0',
      extFifoRen => '0'
   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Signals
   ---------------------------------------------------
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

   signal locFifoEmpty : std_logic := '0';
   signal locFifoDout  : std_logic_vector (G_TIMESTAMP_BITS-1 downto 0);
   signal locFifoFull  : std_logic := '0';

   signal extFifoEmpty : std_logic := '0';
   signal extFifoREn   : std_logic := '0';
   signal extFifoDout  : std_logic_vector (G_DATA_BITS-1 downto 0);
   signal extFifoFull  : std_logic := '0';

   signal stateInt : integer := 0;
   ---------------------------------------------------

begin

   ---------------------------------------------------
   -- FIFO for local data
   ---------------------------------------------------
   FIFO_LOC_U : entity work.fifo_cc
   generic map(
      DATA_WIDTH => G_TIMESTAMP_BITS,
      DEPTH      => 8
   )
   port map(
      clk   => clk,
      rst   => rst,
      din   => inData.Timestamp,
      wen   => inData.DataValid,
      ren   => curReg.locFifoRen,
      dout  => locFifoDout, 
      empty => locFifoEmpty,
      full  => locFifoFull
   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- FIFO for external data
   ---------------------------------------------------
   FIFO_EXT_U : entity work.fifo_cc
   generic map(
      DATA_WIDTH => G_DATA_BITS,
      DEPTH      => 8
   )
   port map(
      clk   => clk,
      rst   => rst,
      din   => rxData.Data,
      wen   => rxData.DataValid,
      ren   => curReg.extFifoREn,
      dout  => extFifoDout, 
      empty => extFifoEmpty,
      full  => extFifoFull
   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Combinational logic
   ---------------------------------------------------
   process(all) begin
      nxtReg <= curReg;
      nxtReg.txData.DataValid <= '0';
      case (curReg.state) is 
         when IDLE_S       =>
            nxtReg.cnt <= (others => '0');
            if qpixReq.Interrogation = '1' then
               nxtReg.state  <= REP_LOCAL_S;
            end if;
            nxtReg. locFifoRen <= '0';
            --if locFifoEmpty = '1' then 
               --nxtReg.state <= REP_LOCAL_S;
            --elsif extFifoEmpty = '1' then
               --nxtReg.state <= REP_REMOTE_S;
            --end if;
         when REP_LOCAL_S  =>
            if locFifoEmpty = '0' and txReady = '1' then
               if curReg.locFifoRen = '0' then
                  nxtReg.locFifoRen <= '1';
                  nxtReg.txData.DataValid <= '1';
                  nxtReg.txData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                  nxtReg.txData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                  nxtReg.txData.Timestamp <= locFifoDout;
                  nxtReg.txData.DirMask   <= fQpixGetDirectionMask(X_POS_G, Y_POS_G);
               else
                  nxtReg.locFifoRen <= '0';
               end if;
               --report "REP_LOC: " & to_string(locFifoEmpty) & " " & to_string(curReg.locFifoRen);
            else 
               nxtReg.state <= REP_REMOTE_S;
            end if;
            --nxtReg.cnt <= curReg.cnt + 1;
            --nxtReg.locFifoRen    <= '1';
            --if curReg.cnt = std_logic_vector(to_unsigned(5,5)) then
               --nxtReg.state  <= REP_REMOTE_S;
            --end if;
            nxtReg.cnt <= (others => '0');
         when REP_REMOTE_S =>
            if extFifoEmpty = '0' and txReady = '1' then 
               if curReg.extFifoRen = '0' then
                  nxtReg.extFifoRen <= '1';
                  nxtReg.txData <= fQpixByteToRecord(extFifoDout);
                  nxtReg.txData.DataValid <= '1';
                  nxtReg.txData.DirMask   <= fQpixGetDirectionMask(X_POS_G, Y_POS_G);
                  nxtReg.txData.WordType  <= G_WORD_TYPE_DATA;
                  --nxtReg.txData.Timestamp <= extFifoDout(31 downto 0);
                  --nxtReg.txData.XPos      <= std_logic_vector(to_unsigned(X_POS_G,G_POS_BITS));
                  --nxtReg.txData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G,G_POS_BITS));
               else
                  nxtReg.extFifoRen <= '0';
               end if;
            else
               nxtReg.txData <= QpixDataZero_C;
            end if;
            nxtReg.cnt <= curReg.cnt + 1;
            if curReg.cnt = qpixConf.Timeout then
               nxtReg.state  <= IDLE_S;
            end if;
            --nxtReg.state <= IDLE_S;
         when others =>
            nxtReg.state <= IDLE_S;
      end case;
   end process;
   ---------------------------------------------------


   ---------------------------------------------------
   -- Synchronous logic
   ---------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            curReg <= REG_INIT_C after GATE_DELAY_G;
         else
            curReg <= nxtReg after GATE_DELAY_G;
         end if;
      end if;
   end process;
   ---------------------------------------------------

   --routeState <= curReg.state;
   txData     <= curReg.txData;

   stateInt <= RouteStatesType'pos(curReg.state);

   process(all)
   begin
      if stateInt /= 2 then
         routeStateInt <= stateInt;
      else
         if extFifoEmpty = '1' then 
            routeStateInt <= 2;
         else
            routeStateInt <= 3;
         end if;
      end if;
   end process;



end behav;

