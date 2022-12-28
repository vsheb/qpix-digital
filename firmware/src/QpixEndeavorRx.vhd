----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
-- use IEEE.math_real."ceil";
-- use IEEE.math_real."log2";

entity qpixendeavorrx is
  generic (
    num_bits_g   : natural := 64;
    gate_delay_g : time    := 1 ns;
    n_zer_min_g  : natural := 4;
    n_zer_max_g  : natural := 12;
    n_one_min_g  : natural := 16;
    n_one_max_g  : natural := 32;
    n_gap_min_g  : natural := 8;
    n_gap_max_g  : natural := 32;
    n_fin_min_g  : natural := 32
  );
  port (
    -- Clock and reset
    clk     : in    std_logic;
    srst    : in    std_logic;
    scale   : in    std_logic_vector(2 downto 0);
    disable : in    std_logic;

    biterror : out   std_logic;
    gaperror : out   std_logic;
    lenerror : out   std_logic;
    rxerror  : out   std_logic;
    rxbusy   : out   std_logic;

    -- Byte data received
    rxbyte      : out   std_logic_vector(num_bits_g - 1 downto 0);
    rxbytevalid : out   std_logic;
    rxbyteack   : in    std_logic;
    rx          : in    std_logic
  );
end entity qpixendeavorrx;

architecture behavioral of qpixendeavorrx is

  type statetype is (idle_s, data_s, bit_s, gap_s,  finish_s, wait_finish_s);

  type regtype is record
    state     : statetype;
    byte      : std_logic_vector(num_bits_g - 1 downto 0);
    dataOut   : std_logic_vector(num_bits_g - 1 downto 0);
    byteValid : std_logic;
    lowCnt    : unsigned(7 downto 0);
    highCnt   : unsigned(7 downto 0);
    byteCount : unsigned(7 downto 0);
    waitCnt   : unsigned(7 downto 0);
    bitError  : std_logic;
    gapError  : std_logic;
    lenError  : std_logic;
    disable   : std_logic;
  end record regtype;

  constant reg_init_c : regtype :=
  (
    state     => IDLE_S,
    byte      => (others => '0'),
    dataOut   => (others => '0'),
    byteValid => '0',
    lowCnt    => (others => '0'),
    highCnt   => (others => '0'),
    byteCount => (others => '0'),
    waitCnt   => (others => '0'),
    biterror  => '0',
    gaperror  => '0',
    lenerror  => '0',
    disable   => '0'
  );

  signal zeromax : unsigned(7 downto 0) := (others => '0');
  signal zeromin : unsigned(7 downto 0) := (others => '0');
  signal onemax  : unsigned(7 downto 0) := (others => '0');
  signal onemin  : unsigned(7 downto 0) := (others => '0');
  signal gapmax  : unsigned(7 downto 0) := (others => '0');
  signal gapmin  : unsigned(7 downto 0) := (others => '0');
  signal finmin  : unsigned(7 downto 0) := (others => '0');

  signal scale0 : unsigned(7 downto 0);
  signal scale1 : unsigned(7 downto 0);
  signal scale2 : unsigned(7 downto 0);
  signal scale4 : unsigned(7 downto 0);
  signal scale8 : unsigned(7 downto 0);

  signal curreg : regtype := reg_init_c;
  signal nxtreg : regtype := reg_init_c;

  signal rx_q : std_logic_vector(3 downto 0);
  signal rx_r : std_logic := '0';

  attribute shreg_extract : string;
  attribute shreg_extract of rx_q : signal is "no";

begin

  -- Map outputs
  rxbyte      <= curReg.dataOut;
  rxbytevalid <= curReg.byteValid;

  biterror <= curReg.bitError;
  gaperror <= curReg.gapError;
  lenerror <= curReg.lenError;

  rxerror <= curReg.bitError or curReg.gapError or curReg.lenError;

  process (clk) is
  begin

    if rising_edge(clk) then
      scale0 <= RESIZE(unsigned(scale), scale0'length);
      scale1 <= scale0;
      scale2 <= unsigned(scale0(scale0'left-1 downto 0)) & '0';
      scale4 <= scale0(scale0'left-2 downto 0) & B"00";
      scale8 <= scale0(scale0'left-3 downto 0) & B"000";

      zeromin <= to_unsigned(n_zer_min_g, 7) + scale1;
      zeromax <= to_unsigned(n_zer_max_g, 7) + scale2;
      onemin  <= to_unsigned(n_one_min_g, 7) + scale2;
      onemax  <= to_unsigned(n_one_max_g, 7) + scale4;
      gapmin  <= to_unsigned(n_gap_min_g, 7) + scale1;
      gapmax  <= to_unsigned(n_gap_max_g, 7) + scale2;
      finmin  <= to_unsigned(n_fin_min_g, 7) + scale8;
    end if;

  end process;

  process (clk) is
  begin

    if (rising_edge (clk)) then
      rx_q <= rx_q(2 downto 0) & rx;
    end if;

  end process;

  rx_r <= rx_q(3);

  -- Asynchronous state logic
  process (curreg, rx_r, rxbyteack, zeromin, zeromax, onemin, onemax, gapmin, finmin, disable) is
  begin

    -- Set defaults
    nxtreg <= curreg;

    nxtReg.disable <= disable;

    if (rxbyteack = '1') then
      nxtReg.byteValid <= '0';
    end if;

    if (rx_r = '1') then
      nxtReg.highCnt <= curReg.highCnt + 1;
    elsif (rx_r = '0') then
      nxtReg.lowCnt <= curReg.lowCnt + 1;
    end if;

    case(curReg.state) is

      when IDLE_S =>

        nxtReg.byteCount <= (others => '0');
        nxtReg.highCnt   <= (others => '0');
        nxtReg.waitCnt   <= (others => '0');

        if (rx_r = '1' and curReg.disable = '0') then
          nxtReg.state    <= DATA_S;
          nxtReg.lowCnt   <= (others => '0');
          nxtReg.lenError <= '0';
          nxtReg.gapError <= '0';
          nxtReg.bitError <= '0';
        end if;

      when DATA_S =>

        if (rx_r = '0') then
          nxtReg.state <= BIT_S;
        end if;

        if (curReg.highCnt > onemax) then
          nxtReg.bitError <= '1';
          nxtReg.state    <= WAIT_FINISH_S;
        end if;

      when BIT_S =>

        if (curReg.highCnt >= zeromin and curReg.highCnt <= zeromax) then
          nxtReg.byte(to_integer(curReg.byteCount)) <= '0';
          nxtReg.state                              <= GAP_S;
        elsif (curReg.highCnt >= onemin and curReg.highCnt <= onemax) then
          nxtReg.byte(to_integer(curReg.byteCount)) <= '1';
          nxtReg.state                              <= GAP_S;
        else
          -- error
          nxtReg.bitError <= '1';
          nxtReg.state    <= WAIT_FINISH_S;
        end if;

        nxtReg.byteCount <= curReg.byteCount + 1;

        nxtReg.highCnt <= (others => '0');

      when GAP_S =>

        if (curReg.lowCnt >= finmin) then
          nxtReg.state <= FINISH_S;
        end if;

        if (rx_r = '1') then
          if (curReg.lowCnt >= gapmin) then
            -- more bytes have been received than expected
            if (curReg.byteCount = num_bits_g) then
              nxtReg.lenError <= '1';
              nxtReg.state    <= IDLE_S;
            else
              nxtReg.state <= DATA_S;
            end if;
          else
            nxtReg.gapError <= '1';
            nxtReg.state    <= WAIT_FINISH_S;
          end if;
          nxtReg.lowCnt <= (others => '0');
        end if;

      when FINISH_S =>

        if (to_integer(curReg.byteCount) = num_bits_g) then
          nxtReg.dataOut   <= curReg.byte;
          nxtReg.byteValid <= '1';
          nxtReg.lenError  <= '0';
          nxtReg.gapError  <= '0';
        else
          nxtReg.lenError <= '1';
        end if;

        nxtReg.state <= IDLE_S;

      when WAIT_FINISH_S =>

        if (rx_r = '0') then
          nxtReg.waitCnt <= curReg.waitCnt + 1;
        else
          nxtReg.waitCnt <= (others => '0');
        end if;

        if (curReg.waitCnt >= finmin) then
          nxtReg.state <= IDLE_S;
        end if;

      when others =>

        nxtReg.state <= IDLE_S;

    end case;

  end process;

  -- Synchronous part of state machine, including reset
  process (clk) is
  begin

    if rising_edge(clk) then
      if (srst = '1') then
        curreg <= reg_init_c after gate_delay_g;
      else
        curreg <= nxtreg after gate_delay_g;
      end if;
    end if;

  end process;

  rxbusy <= '0' when curReg.state = IDLE_S else
            '1';

end architecture behavioral;

