-- -----------------------------------------------------------------------------
-- 'xxx' Register Component
-- Revision: 8
-- -----------------------------------------------------------------------------
-- Generated on 2020-09-10 at 19:05 (UTC) by airhdl version 2020.06.1
-- -----------------------------------------------------------------------------
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
-- POSSIBILITY OF SUCH DAMAGE.
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AxiLiteSlaveSimple is
    generic(
        AXI_ADDR_WIDTH : integer := 32  -- width of the AXI address bus
    );
    port(
        -- Clock and Reset
        axi_aclk    : in  std_logic;
        axi_aresetn : in  std_logic;
        -- AXI Write Address Channel
        axi_awaddr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        axi_awprot  : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        axi_awvalid : in  std_logic;
        axi_awready : out std_logic;
        -- AXI Write Data Channel
        axi_wdata   : in  std_logic_vector(31 downto 0);
        axi_wstrb   : in  std_logic_vector(3 downto 0);
        axi_wvalid  : in  std_logic;
        axi_wready  : out std_logic;
        -- AXI Read Address Channel
        axi_araddr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        axi_arprot  : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        axi_arvalid : in  std_logic;
        axi_arready : out std_logic;
        -- AXI Read Data Channel
        axi_rdata   : out std_logic_vector(31 downto 0);
        axi_rresp   : out std_logic_vector(1 downto 0);
        axi_rvalid  : out std_logic;
        axi_rready  : in  std_logic;
        -- AXI Write Response Channel
        axi_bresp   : out std_logic_vector(1 downto 0);
        axi_bvalid  : out std_logic;
        axi_bready  : in  std_logic;

        -- User Ports
        addr          : out std_logic_vector(31 downto 0);
        rdata         : in  std_logic_vector(31 downto 0);
        wdata         : out std_logic_vector(31 downto 0);
        req           : out std_logic;
        wen           : out std_logic;
        ack           : in  std_logic
    );
end entity AxiLiteSlaveSimple;

architecture RTL of AxiLiteSlaveSimple is

    -- Constants
    constant AXI_OKAY           : std_logic_vector(1 downto 0) := "00";
    constant AXI_DECERR         : std_logic_vector(1 downto 0) := "11";

    -- Registered signals
    signal s_axi_awready_r    : std_logic;
    signal s_axi_wready_r     : std_logic;
    signal s_axi_awaddr_reg_r : unsigned(axi_awaddr'range);
    signal s_axi_bvalid_r     : std_logic;
    signal s_axi_bresp_r      : std_logic_vector(axi_bresp'range);
    signal s_axi_arready_r    : std_logic;
    signal s_axi_araddr_reg_r : unsigned(axi_araddr'range);
    signal s_axi_rvalid_r     : std_logic;
    signal s_axi_rresp_r      : std_logic_vector(axi_rresp'range);
    signal s_axi_wdata_reg_r  : std_logic_vector(axi_wdata'range);
    signal s_axi_wstrb_reg_r  : std_logic_vector(axi_wstrb'range);
    signal s_axi_rdata_r      : std_logic_vector(axi_rdata'range);

    signal s_raddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    signal s_waddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);

    signal rreq_r : std_logic := '0';
    signal wreq_r : std_logic := '0';
    
begin

    ----------------------------------------------------------------------------
    -- Inputs
    --

    ----------------------------------------------------------------------------
    -- Read-transaction FSM
    --    
    read_fsm : process(axi_aclk, axi_aresetn) is
        constant MEM_WAIT_COUNT : natural := 2;
        type t_state is (IDLE, READ_REGISTER, WAIT_MEMORY_RDATA, READ_RESPONSE, DONE);
        -- registered state variables
        variable v_state_r          : t_state;
        variable v_rdata_r          : std_logic_vector(31 downto 0);
        variable v_rresp_r          : std_logic_vector(axi_rresp'range);
        variable v_mem_wait_count_r : natural range 0 to MEM_WAIT_COUNT - 1;
        -- combinatorial helper variables
        variable v_addr_hit : boolean;
        variable v_mem_addr : unsigned(AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r          := IDLE;
            v_rdata_r          := (others => '0');
            v_rresp_r          := (others => '0');
            v_mem_wait_count_r := 0;
            s_axi_arready_r    <= '0';
            s_axi_rvalid_r     <= '0';
            s_axi_rresp_r      <= (others => '0');
            s_axi_araddr_reg_r <= (others => '0');
            s_axi_rdata_r      <= (others => '0');
 
        elsif rising_edge(axi_aclk) then
            -- Default values:
            s_axi_arready_r <= '0';

            case v_state_r is

                -- Wait for the start of a read transaction, which is 
                -- initiated by the assertion of ARVALID
                when IDLE =>
                    v_mem_wait_count_r := 0;
                    --
                    rreq_r <= '0';
                    if axi_arvalid = '1' then
                        s_axi_araddr_reg_r <= unsigned(axi_araddr); -- save the read address
                        s_axi_arready_r    <= '1'; -- acknowledge the read-address
                        v_state_r          := WAIT_MEMORY_RDATA;
                        rreq_r                <= '1';
                        s_raddr               <= axi_araddr;
                    end if;

                -- Wait for memory read data
                when WAIT_MEMORY_RDATA =>
                  if ack = '1' then
                     rreq_r <= '0';
                     v_state_r := READ_REGISTER;
                  end if;

                -- Read from the actual storage element
                when READ_REGISTER =>
                    -- defaults:
                    v_addr_hit := false;
                    v_rdata_r  := rdata;
                    v_state_r := READ_RESPONSE;
                    
                    --if v_addr_hit then
                        --v_rresp_r := AXI_OKAY;
                    --else
                        --v_rresp_r := AXI_DECERR;
                        --v_state_r := READ_RESPONSE;
                    --end if;

                -- Generate read response
                when READ_RESPONSE =>
                    s_axi_rvalid_r <= '1';
                    s_axi_rresp_r  <= v_rresp_r;
                    s_axi_rdata_r  <= v_rdata_r;
                    --
                    v_state_r      := DONE;

                -- Read transaction completed, wait for master RREADY to proceed
                when DONE =>
                    if axi_rready = '1' then
                        s_axi_rvalid_r <= '0';
                        s_axi_rdata_r   <= (others => '0');
                        v_state_r      := IDLE;
                    end if;
            end case;
        end if;
    end process read_fsm;

    ----------------------------------------------------------------------------
    -- Write-transaction FSM
    --    
    write_fsm : process(axi_aclk, axi_aresetn) is
        type t_state is (IDLE, ADDR_FIRST, DATA_FIRST, UPDATE_REGISTER, DONE);
        variable v_state_r  : t_state;
        variable v_addr_hit : boolean;
        variable v_mem_addr : unsigned(AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r          := IDLE;
            s_axi_awready_r    <= '0';
            s_axi_wready_r     <= '0';
            s_axi_awaddr_reg_r <= (others => '0');
            s_axi_wdata_reg_r  <= (others => '0');
            s_axi_wstrb_reg_r  <= (others => '0');
            s_axi_bvalid_r     <= '0';
            s_axi_bresp_r      <= (others => '0');
            --            

        elsif rising_edge(axi_aclk) then
            -- Default values:
            s_axi_awready_r <= '0';
            s_axi_wready_r  <= '0';

            case v_state_r is

                -- Wait for the start of a write transaction, which may be 
                -- initiated by either of the following conditions:
                --   * assertion of both AWVALID and WVALID
                --   * assertion of AWVALID
                --   * assertion of WVALID
                when IDLE =>
                    wreq_r <= '0';
                    wen    <= '0';
                    if axi_awvalid = '1' and axi_wvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(axi_awaddr); -- save the write-address 
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        s_axi_wdata_reg_r  <= axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r  <= axi_wstrb; -- save the write-strobe
                        s_axi_wready_r     <= '1'; -- acknowledge the write-data
                        s_waddr            <= axi_awaddr;
                        v_state_r          := UPDATE_REGISTER;
                    elsif axi_awvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(axi_awaddr); -- save the write-address 
                        s_waddr            <= axi_awaddr;
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        v_state_r          := ADDR_FIRST;
                    elsif axi_wvalid = '1' then
                        s_axi_wdata_reg_r <= axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r <= axi_wstrb; -- save the write-strobe
                        s_axi_wready_r    <= '1'; -- acknowledge the write-data
                        v_state_r         := DATA_FIRST;
                    end if;

                -- Address-first write transaction: wait for the write-data
                when ADDR_FIRST =>
                    if axi_wvalid = '1' then
                        s_axi_wdata_reg_r <= axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r <= axi_wstrb; -- save the write-strobe
                        s_axi_wready_r    <= '1'; -- acknowledge the write-data
                        v_state_r         := UPDATE_REGISTER;
                    end if;

                -- Data-first write transaction: wait for the write-address
                when DATA_FIRST =>
                    if axi_awvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(axi_awaddr); -- save the write-address 
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        s_waddr            <= axi_awaddr;
                        v_state_r          := UPDATE_REGISTER;
                    end if;

                -- Update the actual storage element
                when UPDATE_REGISTER =>
                    s_axi_bresp_r               <= AXI_OKAY; -- default value, may be overriden in case of decode error

                    wdata <= (others => '0');

                     v_addr_hit := true;                        
                     -- field 'value':
                     if s_axi_wstrb_reg_r(0) = '1' then
                         wdata(7 downto 0) <= s_axi_wdata_reg_r(7 downto 0); -- value(0)
                     end if;

                     if s_axi_wstrb_reg_r(1) = '1' then
                         wdata(15 downto 8) <= s_axi_wdata_reg_r(15 downto 8); -- value(8)
                     end if;

                     if s_axi_wstrb_reg_r(2) = '1' then
                         wdata(23 downto 16) <= s_axi_wdata_reg_r(23 downto 16); -- value(16)
                     end if;

                     if s_axi_wstrb_reg_r(3) = '1' then
                         wdata(31 downto 24) <= s_axi_wdata_reg_r(31 downto 24); -- value(24)
                     end if;


                    wreq_r <= '1';
                    wen    <= '1';
                    if ack = '1' then
                       wreq_r <= '0';
                       wen    <= '0';
                       s_axi_bvalid_r              <= '1';
                       v_state_r := DONE;
                    end if;


                -- Write transaction completed, wait for master BREADY to proceed
                when DONE =>
                    if axi_bready = '1' then
                        s_axi_bvalid_r <= '0';
                        v_state_r      := IDLE;
                    end if;

            end case;


        end if;
    end process write_fsm;

    ----------------------------------------------------------------------------
    -- Outputs
    --
    axi_awready <= s_axi_awready_r;
    axi_wready  <= s_axi_wready_r;
    axi_bvalid  <= s_axi_bvalid_r;
    axi_bresp   <= s_axi_bresp_r;
    axi_arready <= s_axi_arready_r;
    axi_rvalid  <= s_axi_rvalid_r;
    axi_rresp   <= s_axi_rresp_r;
    axi_rdata   <= s_axi_rdata_r;
    
    addr <= s_waddr when wreq_r = '1' else s_raddr;
    req <= rreq_r or wreq_r;

end architecture RTL;
