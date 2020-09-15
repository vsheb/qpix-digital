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

   constant G_DATA_BITS        : natural := 64;
   constant G_POS_BITS         : natural := 4;
   constant G_REG_ADDR_BITS    : natural := 16;
   constant G_REG_DATA_BITS    : natural := 16;
   constant G_TIMESTAMP_BITS   : natural := 32; 

   constant G_FIFO_LOC_DEPTH : natural := 8;
   constant G_FIFO_EXT_DEPTH : natural := 8;

   constant DirUp    : std_logic_vector(3 downto 0) := b"1000";
   constant DirRight : std_logic_vector(3 downto 0) := b"0100";
   constant DirDown  : std_logic_vector(3 downto 0) := b"0010";
   constant DirLeft  : std_logic_vector(3 downto 0) := b"0001";

   constant G_WORD_TYPE_DATA : std_logic_vector(3 downto 0) := x"0";


   ------------------------------------------------------------------

   type QpixByteArrType is array(0 to 3) of std_logic_vector(G_DATA_BITS-1 downto 0);
   type Sl2DArray is array(natural range <>, natural range <>) of std_logic;
   type SlvArray is array(natural range <>) of std_logic_vector;
   type Slv2DArray is array(natural range <>, natural range <>) of std_logic_vector;
   type TimeArray2DType is array(natural range<>, natural range<>) of time;

   ------------------------------------------------------------------
   subtype  QpixTxRxPortType is std_logic;
   constant QpixTxRxPortZero_C : QpixTxRxPortType := '0';

   --type QpixTxRxPortType is record
      --Data       : std_logic_vector(G_DATA_BITS-1 downto 0);
      --Valid      : std_logic;
   --end record;


   --constant QpixTxRxPortZero_C : QpixTxRxPortType := (
      --Valid      => '0',
      --Data       => (others => '0')
   --);

   type QpixTxRxPortsArrType is array(0 to 3) of QpixTxRxPortType;

   type QpixTxRxVarArrType is array(natural range <>) of QpixTxRxPortType;

   type QpixInPortsType is record 
      Valid      : std_logic;
      TimeStamp  : std_logic_vector(G_TIMESTAMP_BITS-1 downto 0);
   end record;

   type QpixInPortsArrType is array(natural range <>, natural range <>) of QpixInPortsType;

   constant QpixInPortsZero_C : QpixInPortsType := (
      Valid      => '0',
      TimesTamp  => (others => '0')
   );


   ------------------------------------------------------------------

   ------------------------------------------------------------------
   type QpixDataFormatType is record
      DataValid  : std_logic;
      Data       : std_logic_vector(G_DATA_BITS-1 downto 0);
      TimeStamp  : std_logic_vector(G_TIMESTAMP_BITS-1 downto 0);
      XPos       : std_logic_vector(G_POS_BITS-1 downto 0);
      YPos       : std_logic_vector(G_POS_BITS-1 downto 0);
      DirMask    : std_logic_vector(3 downto 0);
      WordType   : std_logic_vector(3 downto 0);
   end record;

   constant QpixDataZero_C : QPixDataFormatType := (
      DataValid  => '0',
      Data       => (others => '0'),
      TimeStamp  => (others => '0'),
      XPos       => (others => '0'),
      YPos       => (others => '0'),
      DirMask    => (others => '0'),
      WordType   => (others => '0')
   );
   ------------------------------------------------------------------


   ------------------------------------------------------------------
   type QpixRegDataType is record
      Valid  : std_logic;
      Addr   : std_logic_vector(G_REG_ADDR_BITS-1 downto 0);
      Data   : std_logic_vector(G_REG_DATA_BITS-1 downto 0);
   end record;

   constant QpixRegDataZero_C : QpixRegDataType := (
      Valid  => '0',
      Addr   => (others => '0'),
      Data   => (others => '0')
   );

   type QpixConfigType is record
      something : std_logic;
      Timeout   : std_logic_vector(G_REG_DATA_BITS-1 downto 0);

   end record;

   constant QpixConfigDef_C : QpixConfigType := (
      something => '0',
      Timeout   => std_logic_vector(to_unsigned(5000,G_REG_DATA_BITS))

   );

   type QpixRequestType is record
      Interrogation : std_logic;
   end record;

   constant QpixRequestZero_C : QpixRequestType := (
      Interrogation => '0'
   );
   ------------------------------------------------------------------

   type QpixWordType is (DATA_W, TS_CAST_W, TS_REPLY_W, REGREQ_W, UNKNOWN_W);

   type RouteStatesType is (IDLE_S, REP_LOCAL_S, REP_REMOTE_S, REQ_REPLY_S); 

   ------------------------------------------------------------------
   -- Function prototypes
   ------------------------------------------------------------------
   function fQpixRecordToByte(d : QpixDataFormatType) return std_logic_vector;
   function fQpixByteToRecord(d : std_logic_vector) return QpixDataFormatType;
   function fQpixGetWordType(x : std_logic_vector) return QpixWordType;
   function fQpixRegToByte(d : QpixRegDataType) return std_logic_vector;

   function fQpixGetDirectionMask(x : natural := 0; y : natural := 0) return std_logic_vector;

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
      x(59 downto 56) := d.WordType;  -- word type
      x(55 downto 40) := (others => '0');  -- chan mask
      x(39 downto 36) := d.XPos;           -- x
      x(35 downto 32) := d.YPos;           -- y
      x(31 downto 0 ) := d.TimeStamp;      -- timestamp

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
      --x(59 downto 56) ;  -- word type
      --x(55 downto 40) ;  -- chan mask
      x.XPos      := d(39 downto 36) ;           -- x
      x.YPos      := d(35 downto 32) ;           -- y
      x.TimeStamp := d(31 downto 0 ) ;      -- timestamp

      return x;

   end function;
   ------------------------------------------------------------------

   ------------------------------------------------------------------
   -- get word type
   ------------------------------------------------------------------
   function fQpixGetWordType(x : std_logic_vector) 
         return QpixWordType is
      variable q : QpixWordType := UNKNOWN_W;
   begin
      case x(59 downto 56) is
         when x"0"   => q := TS_CAST_W;
         when x"1"   => q := TS_REPLY_W;
         when x"2"   => q := DATA_W;
         when x"3"   => q := REGREQ_W;
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
      x(59 downto 56) := x"3";             -- word type
      x(55 downto 40) := (others => '0');  -- chan mask
      x(39 downto 36) := (others => '0');           -- x
      x(35 downto 32) := (others => '0');           -- y
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
         dir_mask := DirUp;   
      else
         dir_mask := DirLeft;
      end if;

      return dir_mask;

   end function;
   ------------------------------------------------------------------

   function int2slv(x, s : natural) return std_logic_vector is
   begin
      return std_logic_vector(to_unsigned(x,s));
   end function;

end package body QpixPkg;




