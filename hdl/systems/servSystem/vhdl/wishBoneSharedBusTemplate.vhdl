  constant AddrBits : integer := 32;
  constant DataBits : integer := 32;
  constant priorityScheme : integer := 1;

-- Here all signals are defined that are used to connect the
-- master and slaves to the shared bus component.
-- You can copy-paste them in your toplevel file.

  signal s_serv_system_top_CLK_I : std_logic;
  signal s_serv_system_top_RST_I : std_logic;
  signal s_serv_system_top_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_serv_system_top_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_serv_system_top_ACK_I : std_logic;
  signal s_serv_system_top_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_serv_system_top_CYC_O : std_logic;
  signal s_serv_system_top_ERR_I : std_logic;
  signal s_serv_system_top_LOCK_O : std_logic;
  signal s_serv_system_top_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_serv_system_top_STB_O : std_logic;
  signal s_serv_system_top_WE_O : std_logic;
  signal s_serv_system_top_CTI_O : std_logic_vector(2 downto 0);
  signal s_serv_system_top_BTE_O : std_logic_vector(1 downto 0);
  signal s_spiXipBus_CLK_I : std_logic;
  signal s_spiXipBus_RST_I : std_logic;
  signal s_spiXipBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_spiXipBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_spiXipBus_ACK_O : std_logic;
  signal s_spiXipBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_spiXipBus_CYC_I : std_logic;
  signal s_spiXipBus_ERR_O : std_logic;
  signal s_spiXipBus_LOCK_I : std_logic;
  signal s_spiXipBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_spiXipBus_STB_I : std_logic;
  signal s_spiXipBus_WE_I : std_logic;
  signal s_spiXipBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_spiXipBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_srramSlave_CLK_I : std_logic;
  signal s_srramSlave_RST_I : std_logic;
  signal s_srramSlave_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_srramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_srramSlave_ACK_O : std_logic;
  signal s_srramSlave_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_srramSlave_CYC_I : std_logic;
  signal s_srramSlave_ERR_O : std_logic;
  signal s_srramSlave_LOCK_I : std_logic;
  signal s_srramSlave_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_srramSlave_STB_I : std_logic;
  signal s_srramSlave_WE_I : std_logic;
  signal s_srramSlave_CTI_I : std_logic_vector(2 downto 0);
  signal s_srramSlave_BTE_I : std_logic_vector(1 downto 0);
  signal s_spiBus_CLK_I : std_logic;
  signal s_spiBus_RST_I : std_logic;
  signal s_spiBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_spiBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_spiBus_ACK_O : std_logic;
  signal s_spiBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_spiBus_CYC_I : std_logic;
  signal s_spiBus_ERR_O : std_logic;
  signal s_spiBus_LOCK_I : std_logic;
  signal s_spiBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_spiBus_STB_I : std_logic;
  signal s_spiBus_WE_I : std_logic;
  signal s_spiBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_spiBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_uartBus_CLK_I : std_logic;
  signal s_uartBus_RST_I : std_logic;
  signal s_uartBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_ACK_O : std_logic;
  signal s_uartBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_uartBus_CYC_I : std_logic;
  signal s_uartBus_ERR_O : std_logic;
  signal s_uartBus_LOCK_I : std_logic;
  signal s_uartBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_uartBus_STB_I : std_logic;
  signal s_uartBus_WE_I : std_logic;
  signal s_uartBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_uartBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_picBus_CLK_I : std_logic;
  signal s_picBus_RST_I : std_logic;
  signal s_picBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_picBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_picBus_ACK_O : std_logic;
  signal s_picBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_picBus_CYC_I : std_logic;
  signal s_picBus_ERR_O : std_logic;
  signal s_picBus_LOCK_I : std_logic;
  signal s_picBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_picBus_STB_I : std_logic;
  signal s_picBus_WE_I : std_logic;
  signal s_picBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_picBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_SYSCON_CLK_O : std_logic;
  signal s_SYSCON_RST_O : std_logic;

-- Here all your master and slave connections are mapped
-- Probably you have to change it slightly to adapt to your
-- masters/slaves

  busMaster_serv_system_top : entity work.serv_system_top(yourImplementation)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_serv_system_top_CLK_I,
    RST_I => s_serv_system_top_RST_I,
    DAT_I => s_serv_system_top_DAT_I,
    DAT_O => s_serv_system_top_DAT_O,
    ACK_I => s_serv_system_top_ACK_I,
    ADDR_O => s_serv_system_top_ADDR_O,
    CYC_O => s_serv_system_top_CYC_O,
    ERR_I => s_serv_system_top_ERR_I,
    LOCK_O => s_serv_system_top_LOCK_O,
    SEL_O => s_serv_system_top_SEL_O,
    STB_O => s_serv_system_top_STB_O,
    WE_O => s_serv_system_top_WE_O,
    CTI_O => s_serv_system_top_CTI_O,
    BTE_O => s_serv_system_top_BTE_O);

  busSlave_spiXipBus : entity work.spiXipBus(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#0#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_spiXipBus_CLK_I,
    RST_I => s_spiXipBus_RST_I,
    DAT_I => s_spiXipBus_DAT_I,
    DAT_O => s_spiXipBus_DAT_O,
    ACK_O => s_spiXipBus_ACK_O,
    ADDR_I => s_spiXipBus_ADDR_I,
    CYC_I => s_spiXipBus_CYC_I,
    ERR_O => s_spiXipBus_ERR_O,
    LOCK_I => s_spiXipBus_LOCK_I,
    SEL_I => s_spiXipBus_SEL_I,
    STB_I => s_spiXipBus_STB_I,
    WE_I => s_spiXipBus_WE_I,
    CTI_I => s_spiXipBus_CTI_I,
    BTE_I => s_spiXipBus_BTE_I);

  busSlave_srramSlave : entity work.srramSlave(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#40000000#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_srramSlave_CLK_I,
    RST_I => s_srramSlave_RST_I,
    DAT_I => s_srramSlave_DAT_I,
    DAT_O => s_srramSlave_DAT_O,
    ACK_O => s_srramSlave_ACK_O,
    ADDR_I => s_srramSlave_ADDR_I,
    CYC_I => s_srramSlave_CYC_I,
    ERR_O => s_srramSlave_ERR_O,
    LOCK_I => s_srramSlave_LOCK_I,
    SEL_I => s_srramSlave_SEL_I,
    STB_I => s_srramSlave_STB_I,
    WE_I => s_srramSlave_WE_I,
    CTI_I => s_srramSlave_CTI_I,
    BTE_I => s_srramSlave_BTE_I);

  busSlave_spiBus : entity work.spiBus(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#80000000#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_spiBus_CLK_I,
    RST_I => s_spiBus_RST_I,
    DAT_I => s_spiBus_DAT_I,
    DAT_O => s_spiBus_DAT_O,
    ACK_O => s_spiBus_ACK_O,
    ADDR_I => s_spiBus_ADDR_I,
    CYC_I => s_spiBus_CYC_I,
    ERR_O => s_spiBus_ERR_O,
    LOCK_I => s_spiBus_LOCK_I,
    SEL_I => s_spiBus_SEL_I,
    STB_I => s_spiBus_STB_I,
    WE_I => s_spiBus_WE_I,
    CTI_I => s_spiBus_CTI_I,
    BTE_I => s_spiBus_BTE_I);

  busSlave_uartBus : entity work.uartBus(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#80000100#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_uartBus_CLK_I,
    RST_I => s_uartBus_RST_I,
    DAT_I => s_uartBus_DAT_I,
    DAT_O => s_uartBus_DAT_O,
    ACK_O => s_uartBus_ACK_O,
    ADDR_I => s_uartBus_ADDR_I,
    CYC_I => s_uartBus_CYC_I,
    ERR_O => s_uartBus_ERR_O,
    LOCK_I => s_uartBus_LOCK_I,
    SEL_I => s_uartBus_SEL_I,
    STB_I => s_uartBus_STB_I,
    WE_I => s_uartBus_WE_I,
    CTI_I => s_uartBus_CTI_I,
    BTE_I => s_uartBus_BTE_I);

  busSlave_picBus : entity work.picBus(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#80000200#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_picBus_CLK_I,
    RST_I => s_picBus_RST_I,
    DAT_I => s_picBus_DAT_I,
    DAT_O => s_picBus_DAT_O,
    ACK_O => s_picBus_ACK_O,
    ADDR_I => s_picBus_ADDR_I,
    CYC_I => s_picBus_CYC_I,
    ERR_O => s_picBus_ERR_O,
    LOCK_I => s_picBus_LOCK_I,
    SEL_I => s_picBus_SEL_I,
    STB_I => s_picBus_STB_I,
    WE_I => s_picBus_WE_I,
    CTI_I => s_picBus_CTI_I,
    BTE_I => s_picBus_BTE_I);

--Finally here the wishboneBus is mapped
  wishboneBus : entity work.wishBoneSharedBusTop(autogenerated)
  generic map (
      AddrBits => AddrBits,
      DataBits => DataBits,
      priorityScheme => priorityScheme
  ) port map (
    serv_system_top_CLK_I => s_serv_system_top_CLK_I,
    serv_system_top_RST_I => s_serv_system_top_RST_I,
    serv_system_top_DAT_I => s_serv_system_top_DAT_I,
    serv_system_top_DAT_O => s_serv_system_top_DAT_O,
    serv_system_top_ACK_I => s_serv_system_top_ACK_I,
    serv_system_top_ADDR_O => s_serv_system_top_ADDR_O,
    serv_system_top_CYC_O => s_serv_system_top_CYC_O,
    serv_system_top_ERR_I => s_serv_system_top_ERR_I,
    serv_system_top_LOCK_O => s_serv_system_top_LOCK_O,
    serv_system_top_SEL_O => s_serv_system_top_SEL_O,
    serv_system_top_STB_O => s_serv_system_top_STB_O,
    serv_system_top_WE_O => s_serv_system_top_WE_O,
    serv_system_top_CTI_O => s_serv_system_top_CTI_O,
    serv_system_top_BTE_O => s_serv_system_top_BTE_O,
    spiXipBus_CLK_I => s_spiXipBus_CLK_I,
    spiXipBus_RST_I => s_spiXipBus_RST_I,
    spiXipBus_DAT_I => s_spiXipBus_DAT_I,
    spiXipBus_DAT_O => s_spiXipBus_DAT_O,
    spiXipBus_ACK_O => s_spiXipBus_ACK_O,
    spiXipBus_ADDR_I => s_spiXipBus_ADDR_I,
    spiXipBus_CYC_I => s_spiXipBus_CYC_I,
    spiXipBus_ERR_O => s_spiXipBus_ERR_O,
    spiXipBus_LOCK_I => s_spiXipBus_LOCK_I,
    spiXipBus_SEL_I => s_spiXipBus_SEL_I,
    spiXipBus_STB_I => s_spiXipBus_STB_I,
    spiXipBus_WE_I => s_spiXipBus_WE_I,
    spiXipBus_CTI_I => s_spiXipBus_CTI_I,
    spiXipBus_BTE_I => s_spiXipBus_BTE_I,
    srramSlave_CLK_I => s_srramSlave_CLK_I,
    srramSlave_RST_I => s_srramSlave_RST_I,
    srramSlave_DAT_I => s_srramSlave_DAT_I,
    srramSlave_DAT_O => s_srramSlave_DAT_O,
    srramSlave_ACK_O => s_srramSlave_ACK_O,
    srramSlave_ADDR_I => s_srramSlave_ADDR_I,
    srramSlave_CYC_I => s_srramSlave_CYC_I,
    srramSlave_ERR_O => s_srramSlave_ERR_O,
    srramSlave_LOCK_I => s_srramSlave_LOCK_I,
    srramSlave_SEL_I => s_srramSlave_SEL_I,
    srramSlave_STB_I => s_srramSlave_STB_I,
    srramSlave_WE_I => s_srramSlave_WE_I,
    srramSlave_CTI_I => s_srramSlave_CTI_I,
    srramSlave_BTE_I => s_srramSlave_BTE_I,
    spiBus_CLK_I => s_spiBus_CLK_I,
    spiBus_RST_I => s_spiBus_RST_I,
    spiBus_DAT_I => s_spiBus_DAT_I,
    spiBus_DAT_O => s_spiBus_DAT_O,
    spiBus_ACK_O => s_spiBus_ACK_O,
    spiBus_ADDR_I => s_spiBus_ADDR_I,
    spiBus_CYC_I => s_spiBus_CYC_I,
    spiBus_ERR_O => s_spiBus_ERR_O,
    spiBus_LOCK_I => s_spiBus_LOCK_I,
    spiBus_SEL_I => s_spiBus_SEL_I,
    spiBus_STB_I => s_spiBus_STB_I,
    spiBus_WE_I => s_spiBus_WE_I,
    spiBus_CTI_I => s_spiBus_CTI_I,
    spiBus_BTE_I => s_spiBus_BTE_I,
    uartBus_CLK_I => s_uartBus_CLK_I,
    uartBus_RST_I => s_uartBus_RST_I,
    uartBus_DAT_I => s_uartBus_DAT_I,
    uartBus_DAT_O => s_uartBus_DAT_O,
    uartBus_ACK_O => s_uartBus_ACK_O,
    uartBus_ADDR_I => s_uartBus_ADDR_I,
    uartBus_CYC_I => s_uartBus_CYC_I,
    uartBus_ERR_O => s_uartBus_ERR_O,
    uartBus_LOCK_I => s_uartBus_LOCK_I,
    uartBus_SEL_I => s_uartBus_SEL_I,
    uartBus_STB_I => s_uartBus_STB_I,
    uartBus_WE_I => s_uartBus_WE_I,
    uartBus_CTI_I => s_uartBus_CTI_I,
    uartBus_BTE_I => s_uartBus_BTE_I,
    picBus_CLK_I => s_picBus_CLK_I,
    picBus_RST_I => s_picBus_RST_I,
    picBus_DAT_I => s_picBus_DAT_I,
    picBus_DAT_O => s_picBus_DAT_O,
    picBus_ACK_O => s_picBus_ACK_O,
    picBus_ADDR_I => s_picBus_ADDR_I,
    picBus_CYC_I => s_picBus_CYC_I,
    picBus_ERR_O => s_picBus_ERR_O,
    picBus_LOCK_I => s_picBus_LOCK_I,
    picBus_SEL_I => s_picBus_SEL_I,
    picBus_STB_I => s_picBus_STB_I,
    picBus_WE_I => s_picBus_WE_I,
    picBus_CTI_I => s_picBus_CTI_I,
    picBus_BTE_I => s_picBus_BTE_I,
    CLK_O => s_SYSCON_CLK_O,
    RST_O => s_SYSCON_RST_O);

