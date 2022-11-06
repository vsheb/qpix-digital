----------------------------------------------------------------------------------
-- Registers file
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.QpixPkg.all;


entity QpixRegFile is
   generic (
      REG_ADDR_BITS_G : natural := 4;
      REG_DATA_BITS_G : natural := 16;
      X_POS_G         : natural := 0;
      Y_POS_G         : natural := 0;
      MAN_POS_G       : boolean := false
   );
   port (
      clk       : in std_logic;
      rst       : in std_logic;

      clkCntRst : in std_logic;

      txReady   : in std_logic;
      extInterS : in std_logic;
      extInterH : in std_logic;
      regData   : in QpixRegDataType;
      regResp   : out QpixRegDataType;
      intrNum   : in std_logic_vector(15 downto 0);
      
      clkCnt    : out std_logic_vector(31 downto 0);
      qpixConf  : out QpixConfigType;
      qpixReq   : out QpixRequestType
      
   );
end entity QpixRegFile;

architecture behav of QpixRegFile is

   signal qpixConf_r   : QpixConfigType  := QpixConfigDef_C;
   signal qpixReq_r    : QpixRequestType := QpixRequestZero_C;
   signal regResp_r    : QpixRegDataType := QpixRegDataZero_C;

   signal extInterS_r   : std_logic := '0';
   signal extInterH_r   : std_logic := '0';
   signal clkCntRst_r   : std_logic := '0';

   signal cnt       : unsigned (31 downto 0) := (others => '0');
   signal thisAsicDest : std_logic := '0';

   type RegFileState is (IDLE_S, WRITE_S, READ_S);
   signal state : RegFileState := IDLE_S;


begin

   --------------------------------------------------
   -- local time
   --------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' or clkCntRst_r = '1' then
            cnt <= (others => '0');
         else
            cnt <= cnt + 1;
         end if;
      end if;
   end process;
   clkCnt <= std_logic_vector(cnt);
   --------------------------------------------------

   --------------------------------------------------
   -- check if the register data should be accepted by this specific ASIC
   --------------------------------------------------
   process (regData, qpixConf_r)
   begin
      if regData.Dest = '1' then 
         if regData.XDest = qpixConf_r.XPos and regData.YDest = qpixConf_r.YPos
         then
            thisAsicDest <= '1';
         else
            thisAsicDest <= '0';
         end if;
      else
         thisAsicDest <= '1';
      end if;
   end process;
   --------------------------------------------------
   
   extInterS_U : entity work.EdgeDetector
      generic map(
         N_SYNC_G => 2
      )
      port map(
         clk    => clk,
         rst    => rst,
         input  => extInterS,
         output => extInterS_r
      );

   extInterH_U : entity work.EdgeDetector
      generic map(
         N_SYNC_G => 2
      )
      port map(
         clk    => clk,
         rst    => rst,
         input  => extInterH,
         output => extInterH_r
      );

   clkCntRst_U : entity work.EdgeDetector
      generic map(
         N_SYNC_G => 2
      )
      port map( 
         clk    => clk, 
         rst    => '0', 
         input  => clkCntRst,
         output => clkCntRst_r
      );

   --------------------------------------------------
   --------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            qpixConf_r <= QpixConfigDef_C;
            qpixReq_r  <= QpixRequestZero_C;
            regResp_r  <= QpixRegDataZero_C;
         else
            qpixReq_r       <= QpixRequestZero_C;

            qpixReq_r.InterrogationHard <= extInterS_r;
            qpixReq_r.InterrogationSoft <= extInterH_r;

            regResp_r.OpWrite <= '0';
            regResp_r.OpRead  <= '0';
            regResp_r.Addr    <= regData.Addr;
            regResp_r.XDest   <= qpixConf_r.XPos;
            regResp_r.YDest   <= qpixConf_r.YPos;

            if regData.Valid = '1' and thisAsicDest = '1' then
               case regData.Addr is
                  -- CMD reg
                  when x"0001" => 
                     qpixReq_r.InterrogationHard <= regData.Data(0);
                     qpixReq_r.InterrogationSoft <= regData.Data(1);
                     qpixReq_r.AsicReset         <= regData.Data(2);
                     qpixReq_r.ResetState        <= regData.Data(3);
                     qpixReq_r.ReqID             <= regData.ReqID;

                     qpixConf_r.XPos <= regData.XHops;
                     qpixConf_r.YPos <= regData.YHops;

                  -- Get current time
                  when x"0002" =>
                     if regData.OpRead = '1' then
                        regResp_r.Addr  <= std_logic_vector(cnt(31 downto 16));
                        regResp_r.Data  <= std_logic_vector(cnt(15 downto 0));
                     end if;

                  -- DirMask and Manual routing
                  when x"0003" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.DirMaskMan <= regData.Data(3 downto 0);
                        qpixConf_r.ManRoute   <= regData.Data(4);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(4 downto 0) <= qpixConf_r.ManRoute & qpixConf_r.DirMask;
                     end if;

                  -- analog channel masking
                  when x"0004" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.chanEna <= regData.Data(G_N_ANALOG_CHAN-1 downto 0);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(G_N_ANALOG_CHAN-1 downto 0) <= qpixConf_r.chanEna;
                     end if;

                  -- set the chip coordinates
                  when x"0005" =>
                     qpixConf_r.XPos <= regData.XHops;
                     qpixConf_r.YPos <= regData.YHops;
                     regResp_r.XDest <= qpixConf_r.XPos;
                     regResp_r.YDest <= qpixConf_r.YPos;
                     --if regData.OpWrite = '1' then
                     --end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                     end if;

                  -- Disable specific receivers
                  when x"0006" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.RxDisable <= regData.Data(3 downto 0);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(3 downto 0) <= qpixConf_r.RxDisable;
                     end if;

                  -- Disable local data when transferring data
                  when x"0007" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.disIfBusy <= regData.Data(0);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(0) <= qpixConf_r.disIfBusy;
                     end if;

                  -- Read interrogation number
                  when x"0008" =>
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data <= intrNum;
                     end if;

                  when others =>
                     qpixConf_r <= qpixConf_r;
               end case;

               regResp_r.reqID <= regData.reqID;

               if regData.Addr /= x"0001" and regData.OpRead = '1' then
                  regResp_r.Valid <= '1';
               end if;

               if regResp_r.Valid = '1' and txReady = '1' then
                  regResp_r.Valid <= '0';
               end if;

            else
               qpixReq_r <= QpixRequestZero_C;
            end if;

            case state is
               when IDLE_S => 
                  regResp_r.Valid <= '0';
                  if regData.Valid = '1' and thisAsicDest = '1' then
                     if regData.OpWrite = '1'  then
                        state <= WRITE_S;
                     elsif regData.OpRead = '1' then
                        state <= READ_S;
                     end if;
                  end if;
               when READ_S => 
                  regResp_r.Valid <= '1';
                  if txReady = '1' and regResp_r.Valid = '1'  then
                     state <= IDLE_S;
                  end if;
               when WRITE_S => 
                  regResp_r <= QpixRegDataZero_C;
                  state <= IDLE_S;
            end case;

            if MAN_POS_G = True then
               qpixConf_r.XPos <= std_logic_vector(to_unsigned(X_POS_G,G_POS_BITS));
               qpixConf_r.YPos <= std_logic_vector(to_unsigned(Y_POS_G,G_POS_BITS));
            end if;

            if qpixConf_r.ManRoute = '1' then
               qpixConf_r.DirMask <= qpixConf_r.DirMaskMan;
            else
               qpixConf_r.DirMask <= fQpixGetDirectionMask(to_integer(unsigned(qpixConf_r.XPos)), 
                                                           to_integer(unsigned(qpixConf_r.YPos)) );
            end if;
         end if;
      end if;
   end process;
   --------------------------------------------------

   qpixReq  <= qpixReq_r;
   qpixConf <= qpixConf_r;
   regResp  <= regResp_r;


end behav;
