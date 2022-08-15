----------------------------------------------------------------------------------
-- Registers file
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;

-- std rtl things
use work.stdrtlpkg.all;

entity QpixRegFile is
   generic (
      REG_ADDR_BITS_G : natural := 4;
      REG_DATA_BITS_G : natural := 16;
      X_POS_G         : natural := 0;
      Y_POS_G         : natural := 0
   );
   port (
      clk      : in std_logic;
      rst      : in std_logic;

      -- Register information from Qpixcomm
      regData  : in QpixRegDataType;
      regResp  : out QpixRegDataType;
      
      -- Register information to QpixRoute
      qpixConf : out QpixConfigType;
      qpixReq  : out QpixRequestType 
   );
end entity QpixRegFile;

architecture behav of QpixRegFile is

   signal qpixConf_r   : QpixConfigType  := QpixConfigDef_C;
   signal qpixReq_r    : QpixRequestType := QpixRequestZero_C;
   signal regResp_r    : QpixRegDataType := QpixRegDataZero_C;

   signal clkCnt       : std_logic_vector (31 downto 0) := (others => '0');
   signal thisAsicDest : std_logic := '0';

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
   process (regData, thisAsicDest)
   begin
      if regData.Dest = '1' then 
		 if (regData.XDest = toslv(X_POS_G, 4) and regData.YDest = toslv(Y_POS_G, 4))
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
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then
            qpixConf_r <= QpixConfigDef_C;
            qpixReq_r  <= QpixRequestZero_C;
            regResp_r  <= QpixRegDataZero_C;
         else
            qpixReq_r         <= QpixRequestZero_C;
            regResp_r.OpWrite <= '0';
            regResp_r.OpRead  <= '0';
            regResp_r.Valid   <= '0';

            if regData.Valid = '1' and thisAsicDest = '1' then
               case regData.Addr is
                  -- CMD reg
                  when toslv(1, G_REG_ADDR_BITS) => 
                     qpixReq_r.Interrogation <= regData.Data(0);
                     qpixReq_r.ResetState    <= regData.Data(1);
                     qpixReq_r.AsicReset     <= regData.Data(2);

                  --when G_REG_SETPOS  =>

                  -- TIMEOUT reg
                  when toslv(2, G_REG_ADDR_BITS) =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.Timeout <= regData.Data;
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Addr <= regData.Addr;
                        regResp_r.Data <= qpixConf_r.Timeout;
                        regResp_r.XDest <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                        regResp_r.YDest <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                        regResp_r.Valid <= '1';
                     end if;

                  -- DirMask and Manual routing
                  when toslv(3, G_REG_ADDR_BITS) =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.DirMask    <= regData.Data(3 downto 0);
                        qpixConf_r.ManRoute   <= regData.Data(4);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Addr <= regData.Addr;
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(4 downto 0) <= qpixConf_r.ManRoute & qpixConf_r.DirMask;
                        regResp_r.XDest <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                        regResp_r.YDest <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                        regResp_r.Valid <= '1';
                     end if;

                  -- Time register - used for calibration signals
                  when toslv(4, G_REG_ADDR_BITS) =>
                     if regData.OpRead = '1' then
                        regResp_r.Addr <= clkCnt(31 downto 16);
                        regResp_r.Data <= clkCnt(15 downto 0);
                        regResp_r.XDest <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                        regResp_r.YDest <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                        regResp_r.Valid <= '1';
                     end if;

                  -- Enable register - used to turn on taking real data
                  when toslv(5, G_REG_ADDR_BITS) =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.locEnaSnd <= regData.Data(0);
                        qpixConf_r.locEnaRcv <= regData.Data(1);
                        qpixConf_r.locEnaReg <= regData.Data(2);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Addr <= regData.Addr;
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(2 downto 0) <= qpixConf_r.locEnaReg & qpixConf_r.locEnaRcv & qpixConf_r.locEnaSnd;
                        regResp_r.XDest <= std_logic_vector(to_unsigned(X_POS_G, G_POS_BITS));
                        regResp_r.YDest <= std_logic_vector(to_unsigned(Y_POS_G, G_POS_BITS));
                        regResp_r.Valid <= '1';
                     end if;

                  -- defaults
                  when others =>
                     qpixConf_r <= qpixConf_r;
               end case;
            else
               qpixReq_r <= QpixRequestZero_C;
            end if;
         end if;
      end if;
   end process;
   --------------------------------------------------
   
   qpixReq <= qpixReq_r;
   qpixConf <= qpixConf_r;
   regResp  <= regResp_r;

end behav;
