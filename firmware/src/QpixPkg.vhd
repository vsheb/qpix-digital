library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

package QpixPkg is

   ------------------------------------------------------------------
   -- Global constants
   ------------------------------------------------------------------
   -- Create a new type, with indexing scheme:
   --    bitArray2d(row)(col)(dir)
   --    dir decoding: 0 - right
   --                  1 - down
   --                  2 - left
   --                  3 - up
   constant RT : integer := 0;
   constant DN : integer := 1;
   constant LT : integer := 2;
   constant UP : integer := 3;

   constant G_REG_ADDR_BITS    : natural := 16;
   constant G_REG_DATA_BITS    : natural := 16;
   constant G_TIMESTAMP_BITS   : natural := 32; 
   constant G_N_ANALOG_CHAN    : natural := 16;
   constant G_DATA_BITS        : natural := 64;
   constant G_POS_BITS         : natural := 4;
   
-- constant G_FIFO_LOC_DEPTH : natural := 9;
   constant G_FIFO_LOC_DEPTH : natural := 8;
   constant G_FIFO_EXT_DEPTH : natural := 8;
   constant G_FIFO_MUX_DEPTH : natural := 3;

   constant DirUp    : std_logic_vector(3 downto 0) := b"0001";
   constant DirRight : std_logic_vector(3 downto 0) := b"0010";
   constant DirDown  : std_logic_vector(3 downto 0) := b"0100";
   constant DirLeft  : std_logic_vector(3 downto 0) := b"1000";

   constant G_WORD_TYPE_DATA   : std_logic_vector(3 downto 0) := x"1";
   constant G_WORD_TYPE_REGREQ : std_logic_vector(3 downto 0) := x"3";
   constant G_WORD_TYPE_REGRSP : std_logic_vector(3 downto 0) := x"4";
   constant G_WORD_TYPE_EVTEND : std_logic_vector(3 downto 0) := x"5";
   ------------------------------------------------------------------

   --type QpixByteArrType is array(0 to 3) of std_logic_vector(G_DATA_BITS-1 downto 0);
   --type Sl2DArray is array(natural range <>, natural range <>) of std_logic;
   --type SlvArray is array(natural range <>) of std_logic_vector;
   --type Slv2DArray is array(natural range <>, natural range <>) of std_logic_vector;
   --type Slv4b2DArray is array(natural range <>, natural range <>) of std_logic_vector(31 downto 0);
   --type TimeArray2DType is array(natural range<>, natural range<>) of time;

   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- TXRX
   ------------------------------------------------------------------
   type QpixTransceiverTypes is (DUMMY, UART);
   ------------------------------------------------------------------
   -- UART transceiver
   subtype  QpixTxRxPortType   is std_logic;
   constant QpixTxRxPortZero_C : QpixTxRxPortType := '0';
   constant G_QPIX_TXRX_TYPE   : QpixTransceiverTypes := UART;
   --
   -- DUMMY transceiver
   --constant G_QPIX_TXRX_TYPE : QpixTransceiverTypes := DUMMY;
   --type QpixTxRxPortType is record
      --Data       : std_logic_vector(G_DATA_BITS-1 downto 0);
      --Valid      : std_logic;
   --end record;
   --constant QpixTxRxPortZero_C : QpixTxRxPortType := (
      --Valid      => '0',
      --Data       => (others => '0')
   --);


   ------------------------------------------------------------------
   -- Debug record
   ------------------------------------------------------------------
   type QpixDebugType is record
      extFifoCnt : std_logic_vector(31 downto 0);
      locFifoCnt : std_logic_vector(31 downto 0);
   end record;

   constant QpixDebugZero_C : QpixDebugType := (
      extFifoCnt  => (others => '0'),
      locFifoCnt  => (others => '0')
   );

   ------------------------------------------------------------------

  type QpixTxRxVarArrType is array(natural range <>) of QpixTxRxPortType;
  type QpixByteArrType is array(0 to 3) of std_logic_vector(G_DATA_BITS-1 downto 0);
-- depdenencies
  type QpixTxRxPortsArrType is array(0 to 3) of QpixTxRxPortType;
  type QpixDebug2DArrayType is array(natural range <>, natural range<>) of QpixDebugType;
-- uncomment for simulation
type Sl2DArray is array(0 to 3, 0 to 3) of std_logic;
type Slv4b2DArray is array(0 to 3, 0 to 3) of std_logic_vector(31 downto 0);
type TimeArray2DType is array(0 to 3, 0 to 3) of time;

   ------------------------------------------------------------------
   -- Input port from Qpix analog
   ------------------------------------------------------------------
   --type QpixInPortsType is record 
      --Valid      : std_logic;
      --Timestamp  : std_logic_vector(G_TIMESTAMP_BITS-1 downto 0);
      --ChanMask   : std_logic_vector(G_N_ANALOG_CHAN-1  downto 0);
   --end record;

   --constant QpixInPortsZero_C : QpixInPortsType := (
      --Valid      => '0',
      --Timestamp  => (others => '0'),
      --ChanMask   => (others => '0')
   --);

   subtype QpixInPortsType is std_logic_vector(G_N_ANALOG_CHAN-1 downto 0);
   constant QpixInPortsZero_C : QpixInPortsType := (others => '0');

type QpixInPortsArrType is array(natural range <>, natural range <>) of QpixInPortsType;

   ------------------------------------------------------------------


   ------------------------------------------------------------------
   type QpixDataFormatType is record
      DataValid  : std_logic;
      Data       : std_logic_vector(G_DATA_BITS-1 downto 0);
      ChanMask   : std_logic_vector(G_N_ANALOG_CHAN-1 downto 0);
      Timestamp  : std_logic_vector(G_TIMESTAMP_BITS-1 downto 0);
      XPos       : std_logic_vector(G_POS_BITS-1 downto 0);
      YPos       : std_logic_vector(G_POS_BITS-1 downto 0);
      DirMask    : std_logic_vector(3 downto 0); -- directions mask b"URDL"
      WordType   : std_logic_vector(3 downto 0);
   end record;

   constant QpixDataZero_C : QPixDataFormatType := (
      DataValid  => '0',
      Data       => (others => '0'),
      ChanMask   => (others => '0'),
      Timestamp  => (others => '0'),
      XPos       => (others => '0'),
      YPos       => (others => '0'),
      DirMask    => (others => '0'),
      WordType   => (others => '0')
   );
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   type QpixRegReqType is record
      Valid  : std_logic;
      XDest  : std_logic_vector(G_POS_BITS-1 downto 0);
      YDest  : std_logic_vector(G_POS_BITS-1 downto 0);
      Addr   : std_logic_vector(G_REG_ADDR_BITS-1 downto 0);
      Data   : std_logic_vector(G_REG_DATA_BITS-1 downto 0);
   end record;

   constant QpixRegReqZero_C : QpixRegReqType := (
      Valid  => '0',
      XDest  => (others => '0'),
      YDest  => (others => '0'),
      Addr   => (others => '0'),
      Data   => (others => '0')
   );
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Qpix register record
   ------------------------------------------------------------------
   type QpixRegDataType is record
      Valid   : std_logic;
      XDest   : std_logic_vector(G_POS_BITS-1 downto 0);
      YDest   : std_logic_vector(G_POS_BITS-1 downto 0);
      OpWrite : std_logic;
      OpRead  : std_logic;
      ReqID   : std_logic_vector(3 downto 0);
      SrcDaq  : std_logic;
      Dest    : std_logic; -- broadcast if 0
      Addr    : std_logic_vector(G_REG_ADDR_BITS-1 downto 0);
      Data    : std_logic_vector(G_REG_DATA_BITS-1 downto 0);
   end record;

   constant QpixRegDataZero_C : QpixRegDataType := (
      Valid   => '0',
      XDest   => (others => '0'),
      YDest   => (others => '0'),
      OpWrite => '0',
      OpRead  => '0',
      ReqID   => (others => '0'),
      SrcDaq  => '0',
      Dest    => '0',
      Addr    => (others => '0'),
      Data    => (others => '0')
   );
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Configuration record
   ------------------------------------------------------------------
   type QpixConfigType is record
      something   : std_logic;
      Timeout     : std_logic_vector(G_REG_DATA_BITS-1 downto 0);
      DirMask     : std_logic_vector(3 downto 0);
      locEnaSnd   : std_logic; -- analog data enabled while sending 
      locEnaRcv   : std_logic; -- analog data enabled while receiving
      locEnaReg   : std_logic; -- analog data enabled while reg broadcasting
      ManRoute    : std_logic;

   end record;

   constant QpixConfigDef_C : QpixConfigType := (
      something  => '0',
      Timeout    => std_logic_vector(to_unsigned(15000,G_REG_DATA_BITS)), -- UART
      -- Timeout    => (others => '0'), -- Lattice sim testing
      --Timeout   => std_logic_vector(to_unsigned(100,G_REG_DATA_BITS)),   -- dummy
      DirMask    => (others => '0'),
      locEnaSnd  => '0',
      locEnaRcv  => '0',
      locEnaReg  => '0',
      ManRoute   => '0'
   );
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Error statuses
   ------------------------------------------------------------------
   type routeErrType is record 
      locFifoFullCnt : std_logic_vector(3 downto 0);
      extFifoFullCnt : std_logic_vector(3 downto 0);
   end record;

   constant routeErrZero_C : routeErrType := (
      locFifoFullCnt => (others => '0'),
      extFifoFullCnt => (others => '0')
   );

   ------------------------------------------------------------------


   ------------------------------------------------------------------


   ------------------------------------------------------------------
   -- Request type
   ------------------------------------------------------------------
   type QpixRequestType is record
      Interrogation : std_logic;
      ResetState    : std_logic;
      AsicReset     : std_logic;
   end record;

   constant QpixRequestZero_C : QpixRequestType := (
      Interrogation => '0',
      ResetState    => '0',
      AsicReset     => '0'
   );
   ------------------------------------------------------------------

   type QpixWordType is (DATA_W, TS_CAST_W, TS_REPLY_W, REGREQ_W, REGRSP_W, UNKNOWN_W);


   ------------------------------------------------------------------
   -- Function prototypes
   ------------------------------------------------------------------
   function fQpixRecordToByte(d : QpixDataFormatType) return std_logic_vector;
   function fQpixByteToRecord(d : std_logic_vector) return QpixDataFormatType;
   function fQpixGetWordType(x : std_logic_vector) return QpixWordType;
   function fQpixRegToByte(d : QpixRegDataType) return std_logic_vector;
   function fQpixRegReqToByte(d : QpixRegReqType) return std_logic_vector;

   function fQpixGetDirectionMask(x : natural := 0; y : natural := 0) return std_logic_vector;

   -- shortcut function to convert integer to slv
   function int2slv(x, s : natural) return std_logic_vector;
   ------------------------------------------------------------------
   
end QpixPkg;

package body QpixPkg is

   ------------------------------------------------------------------
   -- Convert data record to std_logic_vector
   ------------------------------------------------------------------
   function fQpixRecordToByte(d : QpixDataFormatType) 
         return std_logic_vector is
      variable x : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   begin
      x(63 downto 60) := (others => '0');  -- reserved
      x(59 downto 56) := d.WordType;       -- word type
      x(55 downto 40) := d.ChanMask;       -- chan mask
      x(39 downto 36) := d.XPos;           -- x
      x(35 downto 32) := d.YPos;           -- y
      x(31 downto 0 ) := d.Timestamp;      -- timestamp

      return x;

   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- Convert a byte word to the data record
   ------------------------------------------------------------------
   function fQpixByteToRecord(d : std_logic_vector) 
         return QpixDataFormatType is
      variable x : QpixDataFormatType := QpixDataZero_C;
   begin
      --x(63 downto 60) ;  -- reserved
      x.WordType  := d(59 downto 56) ;  -- word type
      x.ChanMask  := d(55 downto 40) ;  -- chan mask
      x.XPos      := d(39 downto 36) ;  -- x
      x.YPos      := d(35 downto 32) ;  -- y
      x.Timestamp := d(31 downto 0 ) ;  -- timestamp

      return x;

   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- get word type
   ------------------------------------------------------------------
   function fQpixGetWordType(x : std_logic_vector) 
         return QpixWordType is
      variable q : QpixWordType := UNKNOWN_W;
      variable x0 : std_logic_vector(3 downto 0) := x(59 downto 56);
   begin
      case x0 is
         when x"0"   => q := TS_CAST_W;
         when x"1"   => q := TS_REPLY_W;
         when x"2"   => q := DATA_W;
         when x"3"   => q := REGREQ_W;
         when x"4"   => q := REGRSP_W;
         when others => q := UNKNOWN_W;
      end case;
      return q;
   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- convert registers data to byte word to be transmitted
   ------------------------------------------------------------------
   function fQpixRegToByte(d : QpixRegDataType) 
         return std_logic_vector is
      variable x : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   begin
      x(63 downto 60) := (others => '0');  -- reserved
      if d.OpWrite = '0' and d.OpRead = '0' then
         x(59 downto 56) := G_WORD_TYPE_REGRSP;
      else
         x(59 downto 56) := G_WORD_TYPE_REGREQ;             -- word type
      end if;
      x(55)           := d.OpWrite;
      x(54)           := d.OpRead;
      x(53)           := d.Dest;
      x(52 downto 49) := d.ReqID;
      x(48)           := d.SrcDaq;
      x(47 downto 40) := (others => '0');  
      x(39 downto 36) := d.XDest;           -- x
      x(35 downto 32) := d.YDest;           -- y
      x(31 downto 32 - G_REG_ADDR_BITS) := d.Addr; 
      x(15 downto 0 ) := d.Data; 

      return x;

   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- convert register request to byte word to be transmitted
   ------------------------------------------------------------------
   function fQpixRegReqToByte(d : QpixRegReqType) 
         return std_logic_vector is
      variable x : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
   begin
      x(63 downto 60) := (others => '0');  -- reserved
      x(59 downto 56) := G_WORD_TYPE_REGREQ;             -- word type
      x(55 downto 40) := (others => '0');  -- chan mask
      x(39 downto 36) := d.XDest;           -- x
      x(35 downto 32) := d.YDest;           -- y
      x(31 downto 16) := d.Addr; 
      x(15 downto 0 ) := d.Data; 

      return x;

   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- get direction for data to be sent to based on the current coordinates
   ------------------------------------------------------------------
   function fQpixGetDirectionMask(x : natural := 0; y : natural := 0) 
      return std_logic_vector is
      variable dir_mask : std_logic_vector(3 downto 0) := (others => '0');
   begin
      if x > 0 then
         dir_mask := DirLeft;   
      else
         dir_mask := DirUp;
      end if;

      return dir_mask;

   end function;
   ------------------------------------------------------------------

   function int2slv(x, s : natural) return std_logic_vector is
   begin
      return std_logic_vector(to_unsigned(x,s));
   end function;

end package body QpixPkg;