library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- qpix things
library work;
use work.QpixPkg.all;

-- std rtl things
use work.stdrtlpkg.all;

-- ice things
--library ice;
--use ice.all;

entity QDBFifo is

  generic (
    read_mode  : std_ulogic := '0';
    write_mode : std_ulogic := '0';
    RAM_TYPE   : string := "Lattice"; -- "Lattice_loc" / "Lattice_ext" for ext and loc IPs
    DATA_WIDTH : natural := 16;
    DEPTH      : natural := 8
    );

  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    -- bram ports
    din   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    wen   : in  std_logic;
    ren   : in  std_logic;
    dout  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    empty : out std_logic;
    full  : out std_logic
    );

end entity QDBFifo;


architecture Behavioral of QDBFifo is

   signal i_ren       : std_logic;
   signal i_full      : std_logic;
   signal i_empty     : std_logic;
   signal i_empty_r   : std_logic;
   signal i_waddr     : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
   signal i_raddr     : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
   signal i_cnt       : std_logic_vector(DEPTH-1 downto 0) := (others => '0');

  -- design copied from mem.vhd fifo_cc
   constant MAX_ADDR  : std_logic_vector(DEPTH-1 downto 0) := (others =>'1');
   constant ZERO_ADDR : std_logic_vector(DEPTH-1 downto 0) := (others =>'0');

   -- how many 256x16 BRAMs are required??
   constant BRAM_WIDTH : natural := DATA_WIDTH / 16;
   constant BRAM_DEPTH : natural := DEPTH / 256;

component sdp_ram_loc is
    port(
        wr_clk_i: in std_logic;
        rd_clk_i: in std_logic;
        rst_i: in std_logic;
        wr_clk_en_i: in std_logic;
        rd_en_i: in std_logic;
        rd_clk_en_i: in std_logic;
        wr_en_i: in std_logic;
        wr_data_i: in std_logic_vector(47 downto 0);
        wr_addr_i: in std_logic_vector(DEPTH-1 downto 0);
        rd_addr_i: in std_logic_vector(DEPTH-1 downto 0);
        rd_data_o: out std_logic_vector(47 downto 0)
    );
end component;

component sdp_ram_ext is
    port(
        wr_clk_i: in std_logic;
        rd_clk_i: in std_logic;
        rst_i: in std_logic;
        wr_clk_en_i: in std_logic;
        rd_en_i: in std_logic;
        rd_clk_en_i: in std_logic;
        wr_en_i: in std_logic;
        wr_data_i: in std_logic_vector(63 downto 0);
        wr_addr_i: in std_logic_vector(DEPTH-1 downto 0);
        rd_addr_i: in std_logic_vector(DEPTH-1 downto 0);
        rd_data_o: out std_logic_vector(63 downto 0)
    );
end component;
begin

   -- use RAM_loc IP
   def_gen_fifo_loc: if(RAM_TYPE = "Lattice_loc") generate
     ram_ip_loc : sdp_ram_loc 
		port map(
			wr_clk_i=> clk,
			rd_clk_i=> clk,
			rst_i=> rst,
			wr_clk_en_i=> '1',
			rd_en_i=> i_ren,
			rd_clk_en_i=> '1',
			wr_en_i=> wen,
			wr_data_i=> din,
			wr_addr_i=> i_waddr,
			rd_addr_i=> i_raddr,
			rd_data_o=> dout
		);       
   end generate;
   -- use RAM_ext IP
   def_gen_fifo_ext: if(RAM_TYPE = "Lattice_ext") generate
     ram_ip_ext : sdp_ram_ext
		port map(
			wr_clk_i=> clk,
			rd_clk_i=> clk,
			rst_i=> rst,
			wr_clk_en_i=> '1',
			rd_en_i=> i_ren,
			rd_clk_en_i=> '1',
			wr_en_i=> wen,
			wr_data_i=> din,
			wr_addr_i=> i_waddr,
			rd_addr_i=> i_raddr,
			rd_data_o=> dout
		);       
   end generate;
   ---------------------------------------------------

   ---- generate full and empty signals
   i_full   <= '1' when i_cnt = MAX_ADDR  else '0';
   i_empty  <= '1' when i_cnt = ZERO_ADDR else '0';
   full     <= i_full;
   empty    <= i_empty or i_empty_r;
   i_ren    <= ren;

   process(clk)
   begin
      if rising_edge(clk) then
         i_empty_r    <= i_empty;
      end if;
   end process;

   ---- count number of words in FIFO
   FIFO_CNT_PROC : process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            i_cnt <= (others => '0');
         else
            if wen = '1' and i_ren = '0' and i_full = '0' then
               i_cnt <= i_cnt + '1';
            elsif wen = '0' and i_ren = '1' and i_empty = '0' then
               i_cnt <= i_cnt - '1';
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
               if i_waddr = MAX_ADDR then
                  i_waddr <= (others => '0');
               else
                  i_waddr <= i_waddr + 1;
               end if;
            end if;

            if (i_ren = '1' and i_empty = '0') then
               if i_raddr = MAX_ADDR then
                  i_raddr <= (others => '0');
               else
                  i_raddr <= i_raddr + 1;
               end if;
            end if;

         end if;
      end if;
   end process RW_ADDR_PROC;

end Behavioral;
