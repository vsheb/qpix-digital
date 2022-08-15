------------------------------------------------------------------------
---- SIMPLE DUAL PORT BRAM WITH COMMON CLOCK ---------------------------
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity bram_sdp_cc is
generic (
    DATA     : integer := 16;
    ADDR     : integer := 10
);
port (
    -- Port A
    clk   : in  std_logic;
    wea    : in  std_logic;
    addra  : in  std_logic_vector(ADDR-1 downto 0);
    dina   : in  std_logic_vector(DATA-1 downto 0);
    -- Port B
    addrb  : in  std_logic_vector(ADDR-1 downto 0);
    doutb  : out std_logic_vector(DATA-1 downto 0)
);
end bram_sdp_cc;
 
architecture read_first of bram_sdp_cc is
    -- Shared memory
    type mem_type is array ( (2**ADDR)-1 downto 0 ) of std_logic_vector(DATA-1 downto 0);
    signal mem : mem_type := (others => (others => '0'));
begin
 
  process(clk)
  begin
    if(clk'event and clk='1') then
        if(wea='1') then
            mem(to_integer(unsigned(addra))) <= dina;
        end if;
    end if;
  end process;
  doutb <= mem(to_integer(unsigned(addrb)));
 
end read_first;
------------------------------------------------------------------------


------------------------------------------------------------------------
---- FIFO with common clock
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_cc is
generic(
   DATA_WIDTH : natural := 16;
   DEPTH      : natural := 4;
   RAM_TYPE   : string  := "block" 
);

port(
   clk   : in  std_logic;
   rst   : in  std_logic;
   din   : in  std_logic_vector(DATA_WIDTH-1 downto 0); 
   wen   : in  std_logic;
   ren   : in  std_logic;
   dout  : out std_logic_vector(DATA_WIDTH-1 downto 0);
   full  : out std_logic;
   empty : out std_logic
);
end fifo_cc;

architecture fifo_cc_arch of fifo_cc is
   
   signal i_ren       : std_logic;
   signal i_full      : std_logic;
   signal i_empty     : std_logic;
   signal aempty      : std_logic;
                     
   signal i_waddr     : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
   signal i_raddr     : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
   signal i_cnt       : unsigned(DEPTH-1 downto 0) := (others => '0');
   signal i_valid     : std_logic := '0';

   constant ZERO_ADDR : unsigned(DEPTH-1 downto 0) := (others =>'0');
   constant MAX_ADDR  : unsigned(DEPTH-1 downto 0) := (others =>'1');
   
begin

   ---- instantiate BRAM with FIFO content
   bram_i : entity work.bram_sdp_cc 
   generic map(
      DATA => DATA_WIDTH,
      ADDR => DEPTH
   )
   port map (
      clk   => clk,
      wea   => wen,
      addra => i_waddr,
      dina  => din,
      addrb => i_raddr,
      doutb => dout 
   );
   ----

   ---- generate full and empty signals
   i_full   <= '1' when i_cnt = MAX_ADDR  else '0';
   i_empty  <= '1' when i_cnt = ZERO_ADDR else '0';
   aempty   <= '1' when i_cnt = to_unsigned(1,DEPTH) else '0';

   full     <= i_full;

   empty    <= i_empty or (aempty and (ren));
   ----

   i_ren <= ren;

   ---- count number of words in FIFO
   FIFO_CNT_PROC : process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then 
            i_cnt <= (others => '0');
         else
            if wen = '1' and i_ren = '0' and i_full = '0' then
               i_cnt <= i_cnt + 1;
            elsif wen = '0' and i_ren = '1' and i_empty = '0' then
               i_cnt <= i_cnt - 1;
            end if;
         end if;
      end if;
   end process FIFO_CNT_PROC;
   ----

   ---- manage read/write addresses for BRAM
   RW_ADDR_PROC : process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then 
            i_waddr <= (others => '0');
            i_raddr <= (others => '0'); 
         else
            if (wen = '1' and i_full = '0') then
               if i_waddr = std_logic_vector(MAX_ADDR) then
                  i_waddr <= (others => '0');
               else
                  i_waddr <= std_logic_vector(unsigned(i_waddr) + 1);
               end if;
            end if;

            if (i_ren = '1' and i_empty = '0') then
               if i_raddr = std_logic_vector(MAX_ADDR) then
                  i_raddr <= (others => '0');
               else
                  i_raddr <= std_logic_vector(unsigned(i_raddr) + 1);
               end if;
            end if;

         end if;
      end if;
   end process RW_ADDR_PROC;
   ----

end fifo_cc_arch;
------------------------------------------------------------------------



