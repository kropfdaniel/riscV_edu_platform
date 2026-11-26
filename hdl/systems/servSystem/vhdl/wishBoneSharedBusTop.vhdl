library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wishBoneSharedBusTop is
  generic( DataBits : integer := 32;
           AddrBits : integer := 32;
           priorityScheme : integer := 1);  port (
    -- Here the signals for the master "serv_wb_top" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    serv_wb_top_CLK_I : out std_logic;
    serv_wb_top_RST_I : out std_logic;
    serv_wb_top_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    serv_wb_top_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    serv_wb_top_ACK_I : out std_logic;
    serv_wb_top_ADDR_O : in  std_logic_vector((AddrBits - 1) downto 0);
    serv_wb_top_CYC_O : in  std_logic;
    serv_wb_top_ERR_I : out std_logic;
    serv_wb_top_LOCK_O : in  std_logic;
    serv_wb_top_SEL_O : in  std_logic_vector(((DataBits / 8) - 1) downto 0);
    serv_wb_top_STB_O : in  std_logic;
    serv_wb_top_WE_O : in  std_logic;
    serv_wb_top_CTI_O : in  std_logic_vector(2 downto 0);
    serv_wb_top_BTE_O : in  std_logic_vector(1 downto 0);

    -- Here the signals for the slave "spiXipBus" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    spiXipBus_CLK_I : out std_logic;
    spiXipBus_RST_I : out std_logic;
    spiXipBus_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    spiXipBus_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    spiXipBus_ACK_O : in  std_logic;
    spiXipBus_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    spiXipBus_CYC_I : out std_logic;
    spiXipBus_ERR_O : in  std_logic;
    spiXipBus_LOCK_I : out std_logic;
    spiXipBus_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    spiXipBus_STB_I : out std_logic;
    spiXipBus_WE_I : out std_logic;
    spiXipBus_CTI_I : out std_logic_vector(2 downto 0);
    spiXipBus_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "sramSlave" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    sramSlave_CLK_I : out std_logic;
    sramSlave_RST_I : out std_logic;
    sramSlave_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    sramSlave_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    sramSlave_ACK_O : in  std_logic;
    sramSlave_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    sramSlave_CYC_I : out std_logic;
    sramSlave_ERR_O : in  std_logic;
    sramSlave_LOCK_I : out std_logic;
    sramSlave_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    sramSlave_STB_I : out std_logic;
    sramSlave_WE_I : out std_logic;
    sramSlave_CTI_I : out std_logic_vector(2 downto 0);
    sramSlave_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "spiBus" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    spiBus_CLK_I : out std_logic;
    spiBus_RST_I : out std_logic;
    spiBus_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    spiBus_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    spiBus_ACK_O : in  std_logic;
    spiBus_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    spiBus_CYC_I : out std_logic;
    spiBus_ERR_O : in  std_logic;
    spiBus_LOCK_I : out std_logic;
    spiBus_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    spiBus_STB_I : out std_logic;
    spiBus_WE_I : out std_logic;
    spiBus_CTI_I : out std_logic_vector(2 downto 0);
    spiBus_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "uartBus" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    uartBus_CLK_I : out std_logic;
    uartBus_RST_I : out std_logic;
    uartBus_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    uartBus_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    uartBus_ACK_O : in  std_logic;
    uartBus_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    uartBus_CYC_I : out std_logic;
    uartBus_ERR_O : in  std_logic;
    uartBus_LOCK_I : out std_logic;
    uartBus_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    uartBus_STB_I : out std_logic;
    uartBus_WE_I : out std_logic;
    uartBus_CTI_I : out std_logic_vector(2 downto 0);
    uartBus_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "picBus" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    picBus_CLK_I : out std_logic;
    picBus_RST_I : out std_logic;
    picBus_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    picBus_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    picBus_ACK_O : in  std_logic;
    picBus_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    picBus_CYC_I : out std_logic;
    picBus_ERR_O : in  std_logic;
    picBus_LOCK_I : out std_logic;
    picBus_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    picBus_STB_I : out std_logic;
    picBus_WE_I : out std_logic;
    picBus_CTI_I : out std_logic_vector(2 downto 0);
    picBus_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "timer16" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    timer16_CLK_I : out std_logic;
    timer16_RST_I : out std_logic;
    timer16_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    timer16_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    timer16_ACK_O : in  std_logic;
    timer16_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    timer16_CYC_I : out std_logic;
    timer16_ERR_O : in  std_logic;
    timer16_LOCK_I : out std_logic;
    timer16_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    timer16_STB_I : out std_logic;
    timer16_WE_I : out std_logic;
    timer16_CTI_I : out std_logic_vector(2 downto 0);
    timer16_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "leds" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    leds_CLK_I : out std_logic;
    leds_RST_I : out std_logic;
    leds_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    leds_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    leds_ACK_O : in  std_logic;
    leds_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    leds_CYC_I : out std_logic;
    leds_ERR_O : in  std_logic;
    leds_LOCK_I : out std_logic;
    leds_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    leds_STB_I : out std_logic;
    leds_WE_I : out std_logic;
    leds_CTI_I : out std_logic_vector(2 downto 0);
    leds_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the Syscon connections are defined
    -- Connect the signals with the same name together
    -- Note that although we have the _O suffix these are inputs as
    -- they are outputs on the syscon component
    CLK_O : in  std_logic;
    RST_O : in  std_logic);
end entity wishBoneSharedBusTop;

architecture autogenerated of wishBoneSharedBusTop is

  signal s_masked_serv_wb_top_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_serv_wb_top_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_masked_serv_wb_top_CYC_O : std_logic;
  signal s_masked_serv_wb_top_LOCK_O : std_logic;
  signal s_masked_serv_wb_top_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_masked_serv_wb_top_STB_O : std_logic;
  signal s_masked_serv_wb_top_WE_O : std_logic;
  signal s_masked_serv_wb_top_CTI_O : std_logic_vector(2 downto 0);
  signal s_masked_serv_wb_top_BTE_O : std_logic_vector(1 downto 0);
  signal s_masked_spiXipBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_sramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_spiBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_uartBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_picBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_timer16_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_leds_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_sharedBusMaster_DAT : std_logic_vector(DataBits - 1 downto 0);
  signal s_sharedBusMaster_ACK : std_logic;
  signal s_sharedBusMaster_ERR : std_logic;
  signal s_sharedBusSlave_DAT : std_logic_vector(DataBits - 1 downto 0);
  signal s_sharedBusSlave_ADDR : std_logic_vector(AddrBits - 1 downto 0);
  signal s_sharedBusSlave_CYC : std_logic;
  signal s_sharedBusSlave_LOCK : std_logic;
  signal s_sharedBusSlave_SEL : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_sharedBusSlave_STB : std_logic;
  signal s_sharedBusSlave_WE : std_logic;
  signal s_sharedBusSlave_CTI : std_logic_vector(2 downto 0);
  signal s_sharedBusSlave_BTE : std_logic_vector(1 downto 0);
  signal s_arbiterMasterCycs : std_logic;
  signal s_arbiterMasterLocks : std_logic;
  signal s_arbiterBusEnables : std_logic;
  signal s_arbiterErrorOut : std_logic;
  signal s_arbiterMaskReg : std_logic;
  signal s_arbiterEnablesReg : std_logic;
  signal s_arbiterTimeOutReg : std_logic_vector(15 downto 0);
  signal s_arbiterBusIsUsedReg : std_logic;
  signal s_arbiterBeforeMeCarries : std_logic;
  signal s_arbiterAferMeCarries : std_logic;
  signal s_arbiterBeforeMeMask : std_logic;
  signal s_arbiterAfterMeMask : std_logic;
  signal s_arbiterNewMask : std_logic;
  signal s_arbiterServeRequest : std_logic;
  signal s_arbiterIsTimeOut : std_logic;
  signal s_arbiterIsBusRelease : std_logic;

begin

  -- Here we connect all clocks and resets to the syscon
  serv_wb_top_CLK_I <= CLK_O;
  serv_wb_top_RST_I <= RST_O;
  spiXipBus_CLK_I <= CLK_O;
  spiXipBus_RST_I <= RST_O;
  sramSlave_CLK_I <= CLK_O;
  sramSlave_RST_I <= RST_O;
  spiBus_CLK_I <= CLK_O;
  spiBus_RST_I <= RST_O;
  uartBus_CLK_I <= CLK_O;
  uartBus_RST_I <= RST_O;
  picBus_CLK_I <= CLK_O;
  picBus_RST_I <= RST_O;
  timer16_CLK_I <= CLK_O;
  timer16_RST_I <= RST_O;
  leds_CLK_I <= CLK_O;
  leds_RST_I <= RST_O;

  -- Here the arbiter signals are mapped
  s_arbiterMasterLocks <= serv_wb_top_LOCK_O;
  s_arbiterMasterCycs <= serv_wb_top_CYC_O;

  -- Here the masked slave signals are defined
  s_masked_spiXipBus_DAT_O <= spiXipBus_DAT_O when spiXipBus_ACK_O = '1' else (others => '0');
  s_masked_sramSlave_DAT_O <= sramSlave_DAT_O when sramSlave_ACK_O = '1' else (others => '0');
  s_masked_spiBus_DAT_O <= spiBus_DAT_O when spiBus_ACK_O = '1' else (others => '0');
  s_masked_uartBus_DAT_O <= uartBus_DAT_O when uartBus_ACK_O = '1' else (others => '0');
  s_masked_picBus_DAT_O <= picBus_DAT_O when picBus_ACK_O = '1' else (others => '0');
  s_masked_timer16_DAT_O <= timer16_DAT_O when timer16_ACK_O = '1' else (others => '0');
  s_masked_leds_DAT_O <= leds_DAT_O when leds_ACK_O = '1' else (others => '0');

  -- Here the masked master signals are defined
  s_masked_serv_wb_top_DAT_O <= serv_wb_top_DAT_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_serv_wb_top_ADDR_O <= serv_wb_top_ADDR_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_serv_wb_top_CYC_O <= serv_wb_top_CYC_O when s_arbiterBusEnables = '1' else '0';
  s_masked_serv_wb_top_LOCK_O <= serv_wb_top_LOCK_O when s_arbiterBusEnables = '1' else '0';
  s_masked_serv_wb_top_SEL_O <= serv_wb_top_SEL_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_serv_wb_top_STB_O <= serv_wb_top_STB_O when s_arbiterBusEnables = '1' else '0';
  s_masked_serv_wb_top_WE_O <= serv_wb_top_WE_O when s_arbiterBusEnables = '1' else '0';
  s_masked_serv_wb_top_CTI_O <= serv_wb_top_CTI_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_serv_wb_top_BTE_O <= serv_wb_top_BTE_O when s_arbiterBusEnables = '1' else (others => '0');

  -- Here the slave -> master databus is defined
  serv_wb_top_DAT_I <= s_sharedBusMaster_DAT;
  s_sharedBusMaster_DAT <=
      s_masked_spiXipBus_DAT_O or
      s_masked_sramSlave_DAT_O or
      s_masked_spiBus_DAT_O or
      s_masked_uartBus_DAT_O or
      s_masked_picBus_DAT_O or
      s_masked_timer16_DAT_O or
      s_masked_leds_DAT_O;

  -- Here the master -> slave databus is defined
  spiXipBus_DAT_I <= s_sharedBusSlave_DAT;
  sramSlave_DAT_I <= s_sharedBusSlave_DAT;
  spiBus_DAT_I <= s_sharedBusSlave_DAT;
  uartBus_DAT_I <= s_sharedBusSlave_DAT;
  picBus_DAT_I <= s_sharedBusSlave_DAT;
  timer16_DAT_I <= s_sharedBusSlave_DAT;
  leds_DAT_I <= s_sharedBusSlave_DAT;
  s_sharedBusSlave_DAT <=
      s_masked_serv_wb_top_DAT_O;

  -- Here all master inputs are mapped
  serv_wb_top_ACK_I <= s_sharedBusMaster_ACK and s_arbiterBusEnables;
  serv_wb_top_ERR_I <= s_sharedBusMaster_ERR and s_arbiterBusEnables;
  s_sharedBusMaster_ACK <=
      spiXipBus_ACK_O or
      sramSlave_ACK_O or
      spiBus_ACK_O or
      uartBus_ACK_O or
      picBus_ACK_O or
      timer16_ACK_O or
      leds_ACK_O;
  s_sharedBusMaster_ERR <=
      s_arbiterErrorOut or
      spiXipBus_ERR_O or
      sramSlave_ERR_O or
      spiBus_ERR_O or
      uartBus_ERR_O or
      picBus_ERR_O or
      timer16_ERR_O or
      leds_ERR_O;

  -- Here all slave inputs are mapped
  spiXipBus_ADDR_I <= s_sharedBusSlave_ADDR;
  spiXipBus_CYC_I <= s_sharedBusSlave_CYC;
  spiXipBus_LOCK_I <= s_sharedBusSlave_LOCK;
  spiXipBus_SEL_I <= s_sharedBusSlave_SEL;
  spiXipBus_STB_I <= s_sharedBusSlave_STB;
  spiXipBus_WE_I <= s_sharedBusSlave_WE;
  spiXipBus_CTI_I <= s_sharedBusSlave_CTI;
  spiXipBus_BTE_I <= s_sharedBusSlave_BTE;
  sramSlave_ADDR_I <= s_sharedBusSlave_ADDR;
  sramSlave_CYC_I <= s_sharedBusSlave_CYC;
  sramSlave_LOCK_I <= s_sharedBusSlave_LOCK;
  sramSlave_SEL_I <= s_sharedBusSlave_SEL;
  sramSlave_STB_I <= s_sharedBusSlave_STB;
  sramSlave_WE_I <= s_sharedBusSlave_WE;
  sramSlave_CTI_I <= s_sharedBusSlave_CTI;
  sramSlave_BTE_I <= s_sharedBusSlave_BTE;
  spiBus_ADDR_I <= s_sharedBusSlave_ADDR;
  spiBus_CYC_I <= s_sharedBusSlave_CYC;
  spiBus_LOCK_I <= s_sharedBusSlave_LOCK;
  spiBus_SEL_I <= s_sharedBusSlave_SEL;
  spiBus_STB_I <= s_sharedBusSlave_STB;
  spiBus_WE_I <= s_sharedBusSlave_WE;
  spiBus_CTI_I <= s_sharedBusSlave_CTI;
  spiBus_BTE_I <= s_sharedBusSlave_BTE;
  uartBus_ADDR_I <= s_sharedBusSlave_ADDR;
  uartBus_CYC_I <= s_sharedBusSlave_CYC;
  uartBus_LOCK_I <= s_sharedBusSlave_LOCK;
  uartBus_SEL_I <= s_sharedBusSlave_SEL;
  uartBus_STB_I <= s_sharedBusSlave_STB;
  uartBus_WE_I <= s_sharedBusSlave_WE;
  uartBus_CTI_I <= s_sharedBusSlave_CTI;
  uartBus_BTE_I <= s_sharedBusSlave_BTE;
  picBus_ADDR_I <= s_sharedBusSlave_ADDR;
  picBus_CYC_I <= s_sharedBusSlave_CYC;
  picBus_LOCK_I <= s_sharedBusSlave_LOCK;
  picBus_SEL_I <= s_sharedBusSlave_SEL;
  picBus_STB_I <= s_sharedBusSlave_STB;
  picBus_WE_I <= s_sharedBusSlave_WE;
  picBus_CTI_I <= s_sharedBusSlave_CTI;
  picBus_BTE_I <= s_sharedBusSlave_BTE;
  timer16_ADDR_I <= s_sharedBusSlave_ADDR;
  timer16_CYC_I <= s_sharedBusSlave_CYC;
  timer16_LOCK_I <= s_sharedBusSlave_LOCK;
  timer16_SEL_I <= s_sharedBusSlave_SEL;
  timer16_STB_I <= s_sharedBusSlave_STB;
  timer16_WE_I <= s_sharedBusSlave_WE;
  timer16_CTI_I <= s_sharedBusSlave_CTI;
  timer16_BTE_I <= s_sharedBusSlave_BTE;
  leds_ADDR_I <= s_sharedBusSlave_ADDR;
  leds_CYC_I <= s_sharedBusSlave_CYC;
  leds_LOCK_I <= s_sharedBusSlave_LOCK;
  leds_SEL_I <= s_sharedBusSlave_SEL;
  leds_STB_I <= s_sharedBusSlave_STB;
  leds_WE_I <= s_sharedBusSlave_WE;
  leds_CTI_I <= s_sharedBusSlave_CTI;
  leds_BTE_I <= s_sharedBusSlave_BTE;
  s_sharedBusSlave_ADDR <=
      s_masked_serv_wb_top_ADDR_O;
  s_sharedBusSlave_CYC <=
      s_masked_serv_wb_top_CYC_O;
  s_sharedBusSlave_LOCK <=
      s_masked_serv_wb_top_LOCK_O;
  s_sharedBusSlave_SEL <=
      s_masked_serv_wb_top_SEL_O;
  s_sharedBusSlave_STB <=
      s_masked_serv_wb_top_STB_O;
  s_sharedBusSlave_WE <=
      s_masked_serv_wb_top_WE_O;
  s_sharedBusSlave_CTI <=
      s_masked_serv_wb_top_CTI_O;
  s_sharedBusSlave_BTE <=
      s_masked_serv_wb_top_BTE_O;

  -- Here the arbiter is defined
  s_arbiterBusEnables <= '1';
  s_arbiterErrorOut <= s_arbiterIsTimeOut;
  s_arbiterIsTimeOut <= '1' when s_arbiterTimeOutReg = x"0000" else '0';
  arb_3 : process( CLK_O ) is
  begin
    if (rising_edge(CLK_O)) then
      if (serv_wb_top_CYC_O = '0' or s_sharedBusMaster_ACK = '1') then
        s_arbiterTimeOutReg <= (others => '1');
      elsif (s_arbiterIsTimeOut = '0') then
        s_arbiterTimeOutReg <= std_logic_vector(unsigned(s_arbiterTimeOutReg) - to_unsigned(1,16));
      end if;
    end if;
  end process arb_3;
end architecture autogenerated;
