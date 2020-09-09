----------------------------------------------------------------------------------
-- QPix data parser
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.QpixPkg.all;


entity QpixParser is
   generic (
      NUM_BITS_G   : natural := 64;
      GATE_DELAY_G : time    := 1 ns
   );
   port (
      clk           : in std_logic;
      rst           : in std_logic;
      
      -- input to ASIC 
      inBytesArr       : in QpixByteArrType;
      inFifoEmptyArr   : in std_logic_vector(3 downto 0); 
      inFifoREnArr     : out std_logic_vector(3 downto 0);
      inData           : out QpixDataFormatType;
      
      -- output from ASIC
      outData             : in  QpixDataFormatType;
      outBytesArr         : out QpixByteArrType;
      outBytesValidArr    : out std_logic_vector(3 downto 0);

      regData             : out QpixRegDataType
      
   );
end entity QpixParser;


architecture behav of QpixParser is

   signal regDataR         : QpixRegDataType  := QpixRegDataZero_C;
   signal inDataR          : QpixDataFormatType := QpixDataZero_C;

   signal inBytesMux       : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   signal inBytesValid     : std_logic_vector(3 downto 0) := (others => '0');

   signal regReady         : std_logic_vector(3 downto 0) := (others => '0');
   signal regDir           : std_logic_vector(3 downto 0) := (others => '0');
   signal fifoRen          : std_logic_vector(3 downto 0) := (others => '0');
   

begin
   
   ------------------------------------------------------------
   -- mux for input channels
   ------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         inBytesValid <= (others => '0');
         for i in 0 to 3 loop
            fifoRen(i)   <= '0';
            if inFifoEmptyArr(i) = '0' and fifoRen(i) = '0' then
               inBytesMux          <= inBytesArr(i);
               inBytesValid(i)      <= '1';
               --inDataR           <= fQpixByteToRecord(inBytesArr(i));
               --inDataR.DataValid <= '1';
               fifoRen(i)   <= '1';
            end if;
         end loop;
         
      end if;
   end process;
   ------------------------------------------------------------

   inFifoREnArr <= fifoRen;


   ------------------------------------------------------------
   -- RX parsing
   ------------------------------------------------------------
   process (clk)
   begin
      if rising_edge (clk) then
         if rst = '1' then 
            inDataR  <= QpixDataZero_C;
            regDataR <= QpixRegDataZero_C;
         else
            inDataR.DataValid <= '0';
            if regDataR.Valid = '1' and regReady = b"1111" then
               regDataR.Valid <= '0';
            end if;
            if inBytesValid /= b"0000" then
               if fQpixGetWordType(inBytesMux) = REGREQ_W then
                  regDataR.Valid <= '1';
                  regDataR.Addr  <= inBytesMux(31 downto 16);
                  regDataR.Data  <= inBytesMux(15 downto  0);
                  regDir <= not inBytesValid;
               else
                  inDataR           <= fQpixByteToRecord(inBytesMux);
                  inDataR.Data      <= inBytesMux;
                  inDataR.DataValid <= '1';
               end if;
            end if;
         end if;
      end if;
   end process;

   regData <= regDataR;
   inData  <= inDataR;
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- TX
   ------------------------------------------------------------
   TX_GEN : for i in 0 to 3 generate
      process (clk)
      begin
         if rising_edge (clk) then
            outBytesValidArr(i)  <= '0';
            regReady(i)          <= '0';
            if outData.DataValid = '1' then
               if outData.DirMask(i) = '1' then
                  outBytesArr(i) <= fQpixRecordToByte(outData);
                  outBytesValidArr(i)  <= '1';
               end if;
            elsif regDataR.Valid = '1' then
               regReady(i) <= '1';
               if regReady(i) = '1' then
                  outBytesValidArr(i) <= regDir(i);
                  outBytesArr(i)      <= fQpixRegToByte(regDataR);
               end if;
            end if;
         end if;
      end process;
   end generate;
   ------------------------------------------------------------



end behav;

