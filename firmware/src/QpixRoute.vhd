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
      RAM_TYPE        : string  := "block"; -- lattice hardcodes BRAM for lattice, or distributed / block
      X_POS_G         : natural := 0;
      Y_POS_G         : natural := 0
   );
   port (
      clk             : in std_logic;
      rst             : in std_logic;
      
      -- Register information from QpixRegFile                
      qpixReq         : in  QpixRequestType;
      qpixConf        : in  QpixConfigType;
      
      -- Tx/Rx data to QpixComm -> QPixParser
      txReady         : in  std_logic;
      txData          : out QpixDataFormatType;
      rxData          : in  QpixDataFormatType;

      -- QpixDataProc data and enable
      inData          : in  QpixDataFormatType;

      -- debug information
      debug           : out QpixDebugType;
      state           : out std_logic_vector(3 downto 0);
      routeErr        : out routeErrType;                     
      routeStateInt   : out integer    
   );
end entity QpixRoute;

architecture behav of QpixRoute is

   type RouteStatesType is (IDLE_S, REP_LOCAL_S, REP_REMOTE_S, REP_FINISH_S, ROUTE_REGRSP_S); 

   ---------------------------------------------------
   -- Types defenitions
   ---------------------------------------------------
    type RegType is record
      state      :  RouteStatesType;
      stateCnt   :  std_logic_vector(G_REG_DATA_BITS-1 downto 0);
      clkCnt     :  std_logic_vector(31 downto 0);
      timeout    :  std_logic_vector(qpixConf.Timeout'range);

      txData     :  QpixDataFormatType;
      respDir    :  std_logic_vector(3 downto 0);
      manRoute   :  std_logic;
      locFifoRen :  std_logic;
      extFifoRen :  std_logic;
      debug      :  QpixDebugType;
   end record;
   ---------------------------------------------------

   ---------------------------------------------------
   -- Constants
   ---------------------------------------------------
   constant REG_INIT_C : RegType := (
      state      => IDLE_S,
      stateCnt   => (others => '0'),
      clkCnt     => (others => '0'),
      timeout    => (others => '0'),
      txData     => QpixDataZero_C,
      respDir    => (others => '0'),
      manRoute   => '0',
      locFifoRen => '0',
      extFifoRen => '0',
      debug      => QpixDebugZero_C
   );
   ---------------------------------------------------

   ---------------------------------------------------
   -- Signals
   ---------------------------------------------------
   signal curReg : RegType := REG_INIT_C;
   signal nxtReg : RegType := REG_INIT_C;

   signal locFifoEmpty   : std_logic := '0';
   signal locFifoDin     : std_logic_vector (G_N_ANALOG_CHAN+G_TIMESTAMP_BITS-1 downto 0);
   signal locFifoDout    : std_logic_vector (G_N_ANALOG_CHAN+G_TIMESTAMP_BITS-1 downto 0);
   signal locFifoFull    : std_logic := '0';
   signal locFifoFull_e  : std_logic := '0';


   signal extFifoEmpty   : std_logic := '0';
   -- signal extFifoRen     : std_logic := '0';
   signal extFifoDout    : std_logic_vector (G_DATA_BITS-1 downto 0);
   signal extFifoFull    : std_logic := '0';
   signal extFifoFull_e  : std_logic := '0';


   --signal respDir      : std_logic_vector(3 downto 0) := (others => '0');

   signal routeErr_i     : routeErrType := routeErrZero_C;
   ---------------------------------------------------

   constant timeoutZero_C : std_logic_vector(curReg.timeout'range) := (others => '0');

begin

   with curReg.state select state <=
      "0000" when IDLE_S,
      "0001" when REP_LOCAL_S,
      "0010" when REP_REMOTE_S,
      "0100" when REP_FINISH_S,
      "1000" when ROUTE_REGRSP_S,
      "0000" when others;

   ---------------------------------------------------
   -- FIFO for local data
   ---------------------------------------------------
   gen_qdb_fifo_loc: if (RAM_TYPE = "Lattice") generate
      FIFO_LOC_U : entity work.QDBFifo
      generic map(
         DATA_WIDTH => G_N_ANALOG_CHAN + G_TIMESTAMP_BITS, -- 16 + 32 = 48
         DEPTH      => 9,
         RAM_TYPE   => "Lattice_loc"
      )
      port map(
         clk   => clk,
         rst   => rst,
         din   => locFifoDin,
         wen   => inData.DataValid,
         ren   => curReg.locFifoRen,
         dout  => locFifoDout,
         empty => locFifoEmpty,
         full  => locFifoFull
      );
   end generate;
   gen_fifo_loc: if (RAM_TYPE /= "Lattice") generate
      FIFO_LOC_U : entity work.fifo_cc
      generic map(
         DATA_WIDTH => G_N_ANALOG_CHAN + G_TIMESTAMP_BITS,
         DEPTH      => G_FIFO_LOC_DEPTH,
         RAM_TYPE   => "block"
      )
      port map(
         clk   => clk,
         rst   => rst,
         din   => locFifoDin,
         wen   => inData.DataValid,
         ren   => curReg.locFifoRen,
         dout  => locFifoDout,
         empty => locFifoEmpty,
         full  => locFifoFull
      );
   end generate;
   locFifoDin <= inData.ChanMask & inData.Timestamp;
   ---------------------------------------------------

   locFifoFullEdgeDet_U : entity work.EdgeDetector 
      port map ( 
         clk    => clk,
         rst    => rst, 
         input  => locFifoFull,
         output => locFifoFull_e
      );

   ---------------------------------------------------
   -- FIFO for external data
   ---------------------------------------------------
   gen_qdb_fifo_ext: if (RAM_TYPE = "Lattice") generate
      FIFO_EXT_U : entity work.QDBFifo
      generic map(
         DATA_WIDTH => G_DATA_BITS, -- 64
         DEPTH      => 9,
         RAM_TYPE   => "Lattice_ext"
      )
      port map(
         clk   => clk,
         rst   => rst,
         din   => rxData.Data,
         wen   => rxData.DataValid,
         ren   => curReg.extFifoRen,
         dout  => extFifoDout,
         empty => extFifoEmpty,
         full  => extFifoFull
      );
   end generate;
   gen_fifo_ext: if (RAM_TYPE /= "Lattice") generate
   FIFO_EXT_U : entity work.fifo_cc
   generic map(
      DATA_WIDTH => G_DATA_BITS,
      DEPTH      => G_FIFO_EXT_DEPTH,
      RAM_TYPE   => "distributed"
   )
   port map(
      clk   => clk,
      rst   => rst,
      din   => rxData.Data,
      wen   => rxData.DataValid,
      ren   => curReg.extFifoRen,
      dout  => extFifoDout, 
      empty => extFifoEmpty,
      full  => extFifoFull
   );
   end generate;
   ---------------------------------------------------

   extFifoFullEdgeDet_U : entity work.EdgeDetector 
      port map ( 
         clk    => clk,
         rst    => rst, 
         input  => extFifoFull,
         output => extFifoFull_e
      );
      
   ---------------------------------------------------
   -- Count errors
   ---------------------------------------------------
      process (clk)
         constant locFifoCntMax : std_logic_vector(routeErr_i.locFifoFullCnt'range) := (others => '1');
         constant extFifoCntMax : std_logic_vector(routeErr_i.extFifoFullCnt'range) := (others => '1');
      begin
         if rising_edge (clk) then
            if rst = '1' then
               routeErr_i <= routeErrZero_C;
            else
               if locFifoFull_e = '1' then
                  if routeErr_i.locFifoFullCnt /= locFifoCntMax then
                     routeErr_i.locFifoFullCnt <= routeErr_i.locFifoFullCnt + 1;
                  end if;
               end if;
               if extFifoFull_e = '1' then
                  if routeErr_i.extFifoFullCnt /= extFifoCntMax then
                     routeErr_i.extFifoFullCnt <= routeErr_i.extFifoFullCnt + 1;
                  end if;
               end if;

            end if;
            
         end if;
      end process;
   routeErr <= routeErr_i;
   ---------------------------------------------------


   ---------------------------------------------------
   -- Combinational logic
   ---------------------------------------------------
   process(curReg, nxtReg, inData, rxData, qpixReq, extFifoEmpty, extFifoDout,
           txReady, locFifoEmpty, qpixConf, locFifoDout) begin
      nxtReg <= curReg;
      nxtReg.txData.DataValid <= '0';
      nxtReg.clkCnt <= curReg.clkCnt + 1;

      -- keep track of FIFO counts for debuggin -----
      if inData.DataValid = '1' then
         nxtReg.debug.locFifoCnt <= curReg.debug.locFifoCnt + 1;
      end if;
      if curReg.locFifoRen = '1' then
         nxtReg.debug.locFifoCnt <= curReg.debug.locFifoCnt - 1;
      end if;
      if rxData.DataValid = '1' and curReg.extFifoRen = '0' then
         nxtReg.debug.extFifoCnt <= curReg.debug.extFifoCnt + 1;
      end if;
      if rxData.DataValid = '0' and curReg.extFifoRen = '1' then
         nxtReg.debug.extFifoCnt <= curReg.debug.extFifoCnt - 1;
      end if;
      -----------------------------------------------

      case (curReg.state) is 

         -- waiting for interrogation
         when IDLE_S       =>

            nxtReg.stateCnt   <= (others => '0');
            nxtReg.txData     <= QpixDataZero_C;
            nxtReg.locFifoRen <= '0';
            nxtReg.extFifoRen <= '0';
            nxtReg.manRoute   <= qpixConf.ManRoute;
            nxtReg.timeout    <= qpixConf.Timeout;

            if qpixReq.Interrogation = '1' then
               nxtReg.state  <= REP_LOCAL_S;
            end if;

            if curReg.manRoute = '1' then
               nxtReg.respDir  <= qpixConf.DirMask;
            else
               nxtReg.respDir <= fQpixGetDirectionMask(X_POS_G, Y_POS_G);
            end if;

            -- NOTE / TODO -- possible place where fifo is empty but higher
            -- level word is the register response we want
            if extFifoEmpty = '0' and fQpixGetWordType(extFifoDout) = REGRSP_W then
               nxtReg.state <= ROUTE_REGRSP_S;
            end if;

         when ROUTE_REGRSP_S => 
            nxtReg.extFifoRen <= '0';
            nxtReg.stateCnt <= curReg.stateCnt + 1;
            if extFifoEmpty = '0' then 
               if txReady = '1' then
                  if curReg.extFifoRen = '0' and curReg.stateCnt(1) = '1' then
                     nxtReg.txData.DataValid <= '1';
                     nxtReg.txData.WordType <= G_WORD_TYPE_REGRSP;
                     nxtReg.txData.Data <= extFifoDout;
                     nxtReg.txData.DirMask   <= curReg.respDir;
                     nxtReg.extFifoRen <= '1';
                  end if;
               end if;
            else 
               nxtReg.state <= IDLE_S;
            end if;

         -- report local hits
         when REP_LOCAL_S  =>
            nxtReg.stateCnt <= curReg.stateCnt + 1;
            if locFifoEmpty = '0' then 
               if txReady = '1' then
                  if curReg.locFifoRen = '0' and curReg.stateCnt(1) = '1' then
                     nxtReg.locFifoRen <= '1';
                     nxtReg.txData.DataValid <= '1';
                     nxtReg.txData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                     nxtReg.txData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                     nxtReg.txData.Timestamp <= locFifoDout(G_TIMESTAMP_BITS - 1 downto 0);
                     nxtReg.txData.ChanMask  <= locFifoDout(G_N_ANALOG_CHAN + G_TIMESTAMP_BITS - 1 downto G_TIMESTAMP_BITS);
                     nxtReg.txData.DirMask   <= curReg.respDir;
                     nxtReg.txData.WordType  <= G_WORD_TYPE_DATA;
                  else
                     nxtReg.locFifoRen <= '0';
                  end if;
               end if;
            else
               nxtReg.locFifoRen <= '0';
               nxtReg.state            <= REP_FINISH_S;
               nxtReg.stateCnt         <= (others => '0');
            end if;

         when REP_FINISH_S => 
            -- all hits are done, send the packet which indicates that
            nxtReg.stateCnt <= curReg.stateCnt + 1;
            if txReady = '1' then
               if curReg.stateCnt(1) = '1' then
                  nxtReg.txData.DataValid <= '1';
                  nxtReg.txData.XPos      <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                  nxtReg.txData.YPos      <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                  nxtReg.txData.Timestamp <= curReg.clkCnt(15 downto 0) & curReg.clkCnt(15 downto 0); -- FIXME
                  nxtReg.txData.DirMask   <= curReg.respDir;
                  nxtReg.txData.WordType  <= G_WORD_TYPE_EVTEND;
                  nxtReg.state            <= REP_REMOTE_S;
                  nxtReg.stateCnt         <= (others => '0');
               end if;
            end if;

         --report external hits being received from neighbour ASICs
         when REP_REMOTE_S =>

            nxtReg.stateCnt <= curReg.stateCnt + 1;
            nxtReg.extFifoRen <= '0';
            if extFifoEmpty = '0' and txReady = '1' then 
               if curReg.extFifoRen = '0' and curReg.stateCnt(1) = '1' then
                  nxtReg.extFifoRen       <= '1';
                  --nxtReg.txData.Data <= extFifoDout;
                  nxtReg.txData           <= fQpixByteToRecord(extFifoDout);
                  nxtReg.txData.DataValid <= '1';
                  nxtReg.txData.DirMask   <= curReg.respDir;
                  -- replace some data FIXME : temporary
                  if extFifoDout(59 downto 56) = G_WORD_TYPE_EVTEND then
                     nxtReg.txData.Timestamp <= curReg.clkCnt(15 downto 0) & extFifoDout(15 downto 0);
                  end if;
               else
                  nxtReg.extFifoRen <= '0';
               end if;
            else
               nxtReg.extFifoRen <= '0';
               nxtReg.txData.DataValid <= '0';
               --nxtReg.txData <= QpixDataZero_C;
            end if;

            -- TODO / NOTE: where is timeout counting?
            -- simulate this
            if curReg.timeout /= timeoutZero_C then 
               if curReg.stateCnt(curReg.timeout'range) = curReg.timeout then
                  nxtReg.state <= IDLE_S;
               end if;
            else
               if qpixReq.ResetState = '1' then
                  nxtReg.state <= IDLE_S;
               end if;
            end if;

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


   -- register to ports at top level
   txData     <= curReg.txData;
   debug      <= curReg.debug;


   --process(stateInt, extFifoEmpty)
   --begin
      --if stateInt /= 2 then
         --routeStateInt <= stateInt;
      --else
         --if extFifoEmpty = '1' then 
            --routeStateInt <= 2;
         --else
            --routeStateInt <= 3;
         --end if;
      --end if;
   --end process;


end behav;
