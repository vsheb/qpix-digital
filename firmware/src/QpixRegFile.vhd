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
      clk      : in std_logic;
      rst      : in std_logic;

      regData  : in QpixRegDataType;
      regResp  : out QpixRegDataType;
      txReady  : in std_logic;
      
      qpixConf : out QpixConfigType;
      qpixReq  : out QpixRequestType
      
   );
end entity QpixRegFile;

architecture behav of QpixRegFile is

   signal qpixConf_r   : QpixConfigType  := QpixConfigDef_C;
   signal qpixReq_r    : QpixRequestType := QpixRequestZero_C;
   signal regResp_r    : QpixRegDataType := QpixRegDataZero_C;

   signal clkCnt       : unsigned (31 downto 0) := (others => '0');
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
         if rst = '1' then
            clkCnt <= (others => '0');
         else
            clkCnt <= clkCnt + 1;
         end if;
      end if;
   end process;
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
            regResp_r.OpWrite <= '0';
            regResp_r.OpRead  <= '0';

            if regData.Valid = '1' and thisAsicDest = '1' then
               case regData.Addr is
                  -- CMD reg
                  when x"0001" => 
                     qpixReq_r.Interrogation <= regData.Data(0);
                     qpixReq_r.ResetState    <= regData.Data(1);
                     qpixReq_r.AsicReset     <= regData.Data(2);

                     qpixConf_r.XPos <= regData.XHops;
                     qpixConf_r.YPos <= regData.YHops;

                  -- TIMEOUT reg
                  when x"0002" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.Timeout <= regData.Data;
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data  <= qpixConf_r.Timeout;
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

                  when x"0004" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.chanEna <= regData.Data(G_N_ANALOG_CHAN-1 downto 0);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(G_N_ANALOG_CHAN-1 downto 0) <= qpixConf_r.chanEna;
                     end if;
                  when others =>
                     qpixConf_r <= qpixConf_r;
               end case;

               regResp_r.reqID <= regData.reqID;

               if regData.Addr /= x"0001" and regData.OpRead = '1' then
                  regResp_r.Addr  <= regData.Addr;
                  regResp_r.XDest <= qpixConf_r.XPos;
                  regResp_r.YDest <= qpixConf_r.YPos;
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
