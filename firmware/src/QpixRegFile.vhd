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
         --if (regData.XDest = std_logic_vector(to_unsigned((X_POS_G),regData.XDest'length)) 
             --and 
            --regData.YDest = std_logic_vector(to_unsigned((Y_POS_G),regData.YDest'length)) )
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
            regResp_r.Valid <= '0';


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
                        regResp_r.Addr <= regData.Addr;
                        regResp_r.Data <= qpixConf_r.Timeout;
                        regResp_r.XDest <= qpixConf_r.XPos;
                        regResp_r.YDest <= qpixConf_r.YPos;
                        regResp_r.Valid <= '1';
                     end if;

                  -- DirMask and Manual routing
                  when x"0003" =>
                     if regData.OpWrite = '1' then
                        qpixConf_r.DirMaskMan <= regData.Data(3 downto 0);
                        qpixConf_r.ManRoute   <= regData.Data(4);
                     end if;
                     if regData.OpRead = '1' then
                        regResp_r.Addr <= regData.Addr;
                        regResp_r.Data <= (others => '0');
                        regResp_r.Data(4 downto 0) <= qpixConf_r.ManRoute & qpixConf_r.DirMask;
                        regResp_r.XDest <= qpixConf_r.XPos;
                        regResp_r.YDest <= qpixConf_r.YPos;
                        regResp_r.Valid <= '1';
                     end if;
                  -- Determine position of the ASIC
                  --when x"0004" => 
                  when others =>
                     qpixConf_r <= qpixConf_r;
               end case;


            else
               qpixReq_r <= QpixRequestZero_C;
            end if;

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

   qpixReq <= qpixReq_r;
   qpixConf <= qpixConf_r;
   regResp  <= regResp_r;


end behav;
