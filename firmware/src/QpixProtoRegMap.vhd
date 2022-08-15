library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.QpixPkg.all;
use work.QpixProtoPkg.all;


entity QpixProtoRegMap is
   generic (
      X_NUM_G : natural := 3;
      Y_NUM_G : natural := 3;
      Version : std_logic_vector(31 downto 0) := x"0000_0000"
   );
   port (
      clk         : in std_logic;
      rst         : in std_logic;
      
      -- interface to AXI slave module
      addr        : in  std_logic_vector(31 downto 0);
      rdata       : out std_logic_vector(31 downto 0);
      wdata       : in  std_logic_vector(31 downto 0);
      req         : in  std_logic;
      wen         : in  std_logic;
      ack         : out std_logic;

      asic_mask   : out std_logic_vector(15 downto 0);

      -- status regs
      evtSize     : in std_logic_vector(31 downto 0);
      status      : in std_logic_vector(31 downto 0);
      daqFrameErrCnt : in std_logic_vector(31 downto 0);
      daqBreakErrCnt : in std_logic_vector(31 downto 0);

      extFifoMax  : in Slv4b2DArray;
      
      -- local interfaces
      trgTime     : in std_logic_vector(31 downto 0);
      hitMask     : out Sl2DArray;
      timestamp   : out std_logic_vector(31 downto 0);
      chanMask    : out std_logic_vector(G_N_ANALOG_CHAN-1 downto 0);
      swRst       : out std_logic;
   
      -- asics interfaces
      trg         : out std_logic;
      asicAddr    : out std_logic_vector(31 downto 0);
      asicOpWrite : out std_logic;
      asicData    : out std_logic_vector(15 downto 0);
      asicReq     : out std_logic;
      
      memRdReq    : out std_logic;
      memRdAck    : in  std_logic;
      memData     : in  std_logic_vector(31 downto 0);
      memAddr     : out std_logic_vector(G_QPIX_PROTO_MEM_DEPTH-1+2 downto 0);

      daqTestWordIn  : in std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
      daqTestWordOut : out  std_logic_vector(G_DATA_BITS-1 downto 0)
   );
end entity QpixProtoRegMap;

architecture behav of QpixProtoRegMap is
   type reg_arr_t is array(0 to 15) of std_logic_vector(31 downto 0);

   signal s_addr       : std_logic_vector(31 downto 0) := (others => '0');
   alias  a_reg_addr   : std_logic_vector(G_QPIXPROTO_ADDR_BITS-1 downto 0) 
      is s_addr(G_QPIXPROTO_ADDR_BITS-1+2 downto 2);
   
   signal s_reg_arr    : reg_arr_t := (others => (others => '0'));
   signal s_timestamp  : std_logic_vector (G_TIMESTAMP_BITS-1 downto 0) := (others => '0');
   signal s_chanMask   : std_logic_vector (G_N_ANALOG_CHAN-1 downto 0)  := (others => '0');
   signal s_asic_mask  : std_logic_vector (15 downto 0) := (others => '1');
   signal test_word_out : std_logic_vector(63 downto 0);
   signal scratch_word : std_logic_vector(31 downto 0) := Version;

begin

   s_addr <= addr;

   process (clk)
      variable v_reg_ind : natural := 0;
      variable iX        : natural := 0;
      variable iY        : natural := 0;
   begin
      if rising_edge (clk) then
         -- defaults
         trg     <= '0';
         swRst   <= '0';
         --hitXY  <= (others => '0');
         hitMask <= (others => (others => '0'));
         rdata   <= (others => '0');
         memRdReq <= '0';

         asicReq <= '0';

         -- reg mapping
         
         if s_addr(21 downto 18) = x"0" then
            ack     <= req;
            v_reg_ind := to_integer(unsigned(a_reg_addr));
            case a_reg_addr is 
               
               when x"00" =>
                if wen = '1' and req = '1' then
                    scratch_word <= wdata;
                else
                    rdata <= scratch_word;           
                end if;
               
               when REGMAP_CMD     =>
                  if wen = '1' and req = '1' and ack = '0' then
                     trg <= wdata(0);
                     swRst <= wdata(1);
                  end if;
               
               when REGMAP_STATUS    =>
                  rdata <= status;

               when REGMAP_HITMASK =>
                  if wen = '1' and req = '1' and ack = '1' then
                     iX := to_integer(unsigned(wdata(31 downto 16)));
                     iY := to_integer(unsigned(wdata(15 downto 0)));
                     hitMask(iX, iY) <= '1';  
                  end if;

               when REGMAP_TIMESTAMP =>
                  if req = '1' and wen = '1' then
                     s_timestamp <= wdata(G_TIMESTAMP_BITS-1 downto 0);
                  else 
                     rdata <= (others => '0');
                     rdata(G_TIMESTAMP_BITS-1 downto 0) <= s_timestamp;
                  end if;

               when REGMAP_CHANMASK =>
                  if req = '1' and wen = '1' then
                     s_chanMask <= wdata(G_N_ANALOG_CHAN-1 downto 0);
                  else 
                     rdata <= (others => '0');
                     rdata(G_N_ANALOG_CHAN-1 downto 0) <= s_chanMask;
                  end if;

               when REGMAP_ASICMASK    =>
                  if req = '1' and wen = '1'  then
                     s_asic_mask <= wdata(15 downto 0);
                  else 
                     rdata <= (others => '0');
                     rdata(15 downto 0) <= s_asic_mask;
                  end if;

               when REGMAP_TESTOUT_H    =>
                  if req = '1' and wen = '1'  then
                     test_word_out(63 downto 32) <= wdata(31 downto 0);
                  else 
                     rdata <= (others => '0');
                     rdata(31 downto 0) <= test_word_out(63 downto 32);
                  end if;

               when REGMAP_TESTOUT_L    =>
                  if req = '1' and wen = '1'  then
                     test_word_out(31 downto 0) <= wdata(31 downto 0);
                  else 
                     rdata <= (others => '0');
                     rdata(31 downto 0) <= test_word_out(31 downto 0);
                  end if;

               when REGMAP_TESTIN_H     =>
                  rdata <= daqTestWordIn(63 downto 32);

               when REGMAP_TESTIN_L     =>
                  rdata <= daqTestWordIn(31 downto 0);

               when REGMAP_FRAMEERR    =>
                     rdata <= daqFrameErrCnt;

               when REGMAP_BREAKERR    =>
                     rdata <= daqFrameErrCnt;

               when REGMAP_EVTSIZE =>
                  rdata <= evtSize;

               when REGMAP_TRGTIME =>
                  rdata <= trgTime;

               when others => 
                  rdata <= x"0BAD_ADD0";

            end case;

         -- event memory
         elsif s_addr(21 downto 18) = x"1" then
            memRdReq <= req;
            ack     <= memRdAck;
            if req = '1' then 
               memAddr <= s_addr(G_QPIX_PROTO_MEM_DEPTH-1+2+2 downto 2);
               rdata   <= memData;
            end if;

         -- fifo counters
         elsif s_addr(21 downto 18) = x"2" then
            ack <= req;
            iX := to_integer(unsigned(a_reg_addr(3 downto 0)));
            iY := to_integer(unsigned(a_reg_addr(7 downto 4)));
            rdata <= extFifoMax(iX,iY);

         -- asic reg request
         elsif s_addr(21 downto 18) = x"3" then
            ack         <= req;
            rdata       <= x"aaaa_bbbb";
            if req = '1' and ack = '0' then
               asicReq     <= '1';
               asicOpWrite <= wen;
               asicData    <= wdata(15 downto 0);
               asicAddr    <= (others => '0');
               asicAddr(9 downto 0)  <= s_addr(11 downto 2);
            end if;
         else
            rdata <= x"0BAD_ADD0";
            ack <= req;

         end if;
         
      end if;
   end process;

   daqTestWordOut <= test_word_out;

   timestamp <= s_timestamp;
   chanMask  <= s_chanMask;
   asic_mask <= s_asic_mask;


end behav;
