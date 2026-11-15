library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_top is
  port (
    clock       : in  std_logic; -- 50MHz
    n_reset     : in  std_logic;

    -- SPI
    spiNCs      : out std_logic_vector(1 downto 0);
    spiClk      : out std_logic;
    spiMoSi     : out std_logic;
    spiMiSo     : in  std_logic;

    -- External SPI Flash Pins
    spiXipNCs   : out std_logic;
    spiXipClk   : out std_logic;
    spiXipMoSi  : out std_logic;
    spiXipMiSo  : in  std_logic;
    flashWpN    : out std_logic;
    flashResetN : out std_logic;

    -- UART
    RxD         : in  std_logic;
    TxD         : out std_logic
  );
end entity system_top;

architecture rtl of system_top is
    constant AddrBits : integer := 32;
    constant DataBits : integer := 32;
    constant priorityScheme : integer := 1;

    -- Here all signals are defined that are used to connect the
    -- master and slaves to the shared bus component.
    -- You can copy-paste them in your toplevel file.

    signal s_serv_wb_top_CLK_I : std_logic;
    signal s_serv_wb_top_RST_I : std_logic;
    signal s_serv_wb_top_DAT_I : std_logic_vector((DataBits - 1) downto 0);
    signal s_serv_wb_top_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_serv_wb_top_ACK_I : std_logic;
    signal s_serv_wb_top_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
    signal s_serv_wb_top_CYC_O : std_logic;
    signal s_serv_wb_top_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
    signal s_serv_wb_top_STB_O : std_logic;
    signal s_serv_wb_top_WE_O : std_logic;
    signal s_spiXipBus_CLK_I : std_logic;
    signal s_spiXipBus_RST_I : std_logic;
    signal s_spiXipBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_spiXipBus_ACK_O : std_logic;
    signal s_spiXipBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
    signal s_spiXipBus_CYC_I : std_logic;
    signal s_spiXipBus_ERR_O : std_logic;
    signal s_spiXipBus_STB_I : std_logic;
    signal s_spiXipBus_WE_I : std_logic;
    signal s_spiXipBus_CTI_I : std_logic_vector(2 downto 0);
    signal s_sramSlave_CLK_I : std_logic;
    signal s_sramSlave_RST_I : std_logic;
    signal s_sramSlave_DAT_I : std_logic_vector((DataBits - 1) downto 0);
    signal s_sramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_sramSlave_ACK_O : std_logic;
    signal s_sramSlave_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
    signal s_sramSlave_CYC_I : std_logic;
    signal s_sramSlave_ERR_O : std_logic;
    signal s_sramSlave_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
    signal s_sramSlave_STB_I : std_logic;
    signal s_sramSlave_WE_I : std_logic;
    signal s_sramSlave_CTI_I : std_logic_vector(2 downto 0);
    signal s_sramSlave_BTE_I : std_logic_vector(1 downto 0);
    signal s_spiBus_CLK_I : std_logic;
    signal s_spiBus_RST_I : std_logic;
    signal s_spiBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
    signal s_spiBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_spiBus_ACK_O : std_logic;
    signal s_spiBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
    signal s_spiBus_CYC_I : std_logic;
    signal s_spiBus_ERR_O : std_logic;
    signal s_spiBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
    signal s_spiBus_STB_I : std_logic;
    signal s_spiBus_WE_I : std_logic;
    signal s_spiBus_CTI_I : std_logic_vector(2 downto 0);
    signal s_uartBus_CLK_I : std_logic;
    signal s_uartBus_RST_I : std_logic;
    signal s_uartBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
    signal s_uartBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_uartBus_ACK_O : std_logic;
    signal s_uartBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
    signal s_uartBus_CYC_I : std_logic;
    signal s_uartBus_ERR_O : std_logic;
    signal s_uartBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
    signal s_uartBus_STB_I : std_logic;
    signal s_uartBus_WE_I : std_logic;
    signal s_uartBus_CTI_I : std_logic_vector(2 downto 0);
    signal s_picBus_CLK_I : std_logic;
    signal s_picBus_RST_I : std_logic;
    signal s_picBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
    signal s_picBus_ACK_O : std_logic;
    signal s_picBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
    signal s_picBus_CYC_I : std_logic;
    signal s_picBus_ERR_O : std_logic;
    signal s_picBus_STB_I : std_logic;
    signal s_picBus_WE_I : std_logic;
    signal s_picBus_CTI_I : std_logic_vector(2 downto 0);
    signal s_SYSCON_CLK_O : std_logic;
    signal s_SYSCON_RST_O : std_logic;

    signal s_reset : std_logic_vector(3 downto 0);

    signal s_uart_irq : std_logic;
    signal s_total_irq : std_logic;
begin
    s_SYSCON_CLK_O <= clock;
    s_SYSCON_RST_O <= not n_reset;

    -- Here all your master and slave connections are mapped
    -- Probably you have to change it slightly to adapt to your
    -- masters/slaves

    busMaster_serv_wb_top : entity work.serv_wb_top(rtl)
    generic map (
        AddrBits => AddrBits,
        DataBits => DataBits,
        COMPRESSED => true,
        MDU => false,
        PRE_REGISTER => false,
        WITH_CSR => true    
    )
    port map (
        CLK_I => s_serv_wb_top_CLK_I,
        RST_I => s_serv_wb_top_RST_I,
        DAT_I => s_serv_wb_top_DAT_I,
        DAT_O => s_serv_wb_top_DAT_O,
        ACK_I => s_serv_wb_top_ACK_I,
        ADDR_O => s_serv_wb_top_ADDR_O,
        CYC_O => s_serv_wb_top_CYC_O,
        SEL_O => s_serv_wb_top_SEL_O,
        STB_O => s_serv_wb_top_STB_O,
        WE_O => s_serv_wb_top_WE_O,
        
        i_timer_irq => s_total_irq,
        o_ext_rs1 => open,
        o_ext_rs2 => open,
        o_ext_funct3 => open,
        i_ext_rd => (others => '0'),
        i_ext_ready => '0',
        o_mdu_valid => open,
        reset_vec => (others => '0')
    );

    busSlave_spiXipBus : entity work.spiXipBus(platformIndependent)
    generic map (
        BaseAddress => std_logic_vector(to_unsigned(16#0#, AddrBits)),
        AddrBits => AddrBits,
        DataBits => DataBits)
    port map (
        CLK_I => s_spiXipBus_CLK_I,
        RST_I => s_spiXipBus_RST_I,
        DAT_O => s_spiXipBus_DAT_O,
        ACK_O => s_spiXipBus_ACK_O,
        ADDR_I => s_spiXipBus_ADDR_I,
        CYC_I => s_spiXipBus_CYC_I,
        ERR_O => s_spiXipBus_ERR_O,
        STB_I => s_spiXipBus_STB_I,
        WE_I => s_spiXipBus_WE_I,
        CTI_I => s_spiXipBus_CTI_I,

        spiNCs      => spiXipNCs,
        spiClk      => spiXipClk,
        spiMoSi     => spiXipMoSi,
        spiMiSo     => spiXipMiSo,
        flashWpN    => flashWpN,
        flashResetN => flashResetN   
    );

    busSlave_sramSlave : entity work.sramSlave(platformIndependent)
  generic map (
    BaseAddress => std_logic_vector'(AddrBits-1 downto 0 => 32X"40000000"),
    AddrBits => AddrBits,
    DataBits => DataBits,
    nrOfEntriesInBytes => 4*1024) -- 4kB
  port map (
    CLK_I => s_sramSlave_CLK_I,
    RST_I => s_sramSlave_RST_I,
    DAT_I => s_sramSlave_DAT_I,
    DAT_O => s_sramSlave_DAT_O,
    ACK_O => s_sramSlave_ACK_O,
    ADDR_I => s_sramSlave_ADDR_I,
    CYC_I => s_sramSlave_CYC_I,
    ERR_O => s_sramSlave_ERR_O,
    SEL_I => s_sramSlave_SEL_I,
    STB_I => s_sramSlave_STB_I,
    WE_I => s_sramSlave_WE_I,
    CTI_I => s_sramSlave_CTI_I,
    BTE_I => s_sramSlave_BTE_I);

  busSlave_spiBus : entity work.spiBus(platformIndependent)
  generic map (
    BaseAddress => std_logic_vector'(AddrBits-1 downto 0 => 32X"80000000"),
    AddrBits => AddrBits,
    DataBits => DataBits,
    NrOfCS => 2)
  port map (
    CLK_I => s_spiBus_CLK_I,
    RST_I => s_spiBus_RST_I,
    DAT_I => s_spiBus_DAT_I,
    DAT_O => s_spiBus_DAT_O,
    ACK_O => s_spiBus_ACK_O,
    ADDR_I => s_spiBus_ADDR_I,
    CYC_I => s_spiBus_CYC_I,
    ERR_O => s_spiBus_ERR_O,
    SEL_I => s_spiBus_SEL_I,
    STB_I => s_spiBus_STB_I,
    WE_I => s_spiBus_WE_I,
    CTI_I => s_spiBus_CTI_I,
    spiNCs => spiNCs,
    spiClk => spiClk,
    spiMosi => spiMosi,
    spiMiso => spiMiso);

  busSlave_uartBus : entity work.uartBus(platformIndependent)
  generic map (
    BaseAddress => std_logic_vector'(AddrBits-1 downto 0 => 32X"80000100"),
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
    SEL_I => s_uartBus_SEL_I,
    STB_I => s_uartBus_STB_I,
    WE_I => s_uartBus_WE_I,
    CTI_I => s_uartBus_CTI_I,
    clock50MHz => s_uartBus_CLK_I,
    irq => s_uart_irq,
    RxD => RxD,
    TxD => TxD);

  busSlave_picBus : entity work.picBus(platformIndependent)
  generic map (
    BaseAddress => std_logic_vector'(AddrBits-1 downto 0 => 32X"80000200"),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_picBus_CLK_I,
    RST_I => s_picBus_RST_I,
    DAT_O => s_picBus_DAT_O,
    ACK_O => s_picBus_ACK_O,
    ADDR_I => s_picBus_ADDR_I,
    CYC_I => s_picBus_CYC_I,
    ERR_O => s_picBus_ERR_O,
    STB_I => s_picBus_STB_I,
    WE_I => s_picBus_WE_I,
    CTI_I => s_picBus_CTI_I,
    uart_irq => s_uart_irq,
    total_irq => s_total_irq
    );

--Finally here the wishboneBus is mapped
  wishboneBus : entity work.wishBoneSharedBusTop(autogenerated)
  generic map (
      AddrBits => AddrBits,
      DataBits => DataBits,
      priorityScheme => priorityScheme
  ) port map (
    serv_wb_top_CLK_I => s_serv_wb_top_CLK_I,
    serv_wb_top_RST_I => s_serv_wb_top_RST_I,
    serv_wb_top_DAT_I => s_serv_wb_top_DAT_I,
    serv_wb_top_DAT_O => s_serv_wb_top_DAT_O,
    serv_wb_top_ACK_I => s_serv_wb_top_ACK_I,
    serv_wb_top_ADDR_O => s_serv_wb_top_ADDR_O,
    serv_wb_top_CYC_O => s_serv_wb_top_CYC_O,
    serv_wb_top_ERR_I => open,
    serv_wb_top_LOCK_O => '0',
    serv_wb_top_SEL_O => s_serv_wb_top_SEL_O,
    serv_wb_top_STB_O => s_serv_wb_top_STB_O,
    serv_wb_top_WE_O => s_serv_wb_top_WE_O,
    serv_wb_top_CTI_O => "000", -- Classic cycle
    serv_wb_top_BTE_O => "00",-- Linear burst
    spiXipBus_CLK_I => s_spiXipBus_CLK_I,
    spiXipBus_RST_I => s_spiXipBus_RST_I,
    spiXipBus_DAT_I => open,
    spiXipBus_DAT_O => s_spiXipBus_DAT_O,
    spiXipBus_ACK_O => s_spiXipBus_ACK_O,
    spiXipBus_ADDR_I => s_spiXipBus_ADDR_I,
    spiXipBus_CYC_I => s_spiXipBus_CYC_I,
    spiXipBus_ERR_O => s_spiXipBus_ERR_O,
    spiXipBus_LOCK_I => open,
    spiXipBus_SEL_I => open,
    spiXipBus_STB_I => s_spiXipBus_STB_I,
    spiXipBus_WE_I => s_spiXipBus_WE_I,
    spiXipBus_CTI_I => s_spiXipBus_CTI_I,
    spiXipBus_BTE_I => open,
    sramSlave_CLK_I => s_sramSlave_CLK_I,
    sramSlave_RST_I => s_sramSlave_RST_I,
    sramSlave_DAT_I => s_sramSlave_DAT_I,
    sramSlave_DAT_O => s_sramSlave_DAT_O,
    sramSlave_ACK_O => s_sramSlave_ACK_O,
    sramSlave_ADDR_I => s_sramSlave_ADDR_I,
    sramSlave_CYC_I => s_sramSlave_CYC_I,
    sramSlave_ERR_O => s_sramSlave_ERR_O,
    sramSlave_LOCK_I => open,
    sramSlave_SEL_I => s_sramSlave_SEL_I,
    sramSlave_STB_I => s_sramSlave_STB_I,
    sramSlave_WE_I => s_sramSlave_WE_I,
    sramSlave_CTI_I => s_sramSlave_CTI_I,
    sramSlave_BTE_I => s_sramSlave_BTE_I,
    spiBus_CLK_I => s_spiBus_CLK_I,
    spiBus_RST_I => s_spiBus_RST_I,
    spiBus_DAT_I => s_spiBus_DAT_I,
    spiBus_DAT_O => s_spiBus_DAT_O,
    spiBus_ACK_O => s_spiBus_ACK_O,
    spiBus_ADDR_I => s_spiBus_ADDR_I,
    spiBus_CYC_I => s_spiBus_CYC_I,
    spiBus_ERR_O => s_spiBus_ERR_O,
    spiBus_LOCK_I => open,
    spiBus_SEL_I => s_spiBus_SEL_I,
    spiBus_STB_I => s_spiBus_STB_I,
    spiBus_WE_I => s_spiBus_WE_I,
    spiBus_CTI_I => s_spiBus_CTI_I,
    spiBus_BTE_I => open,
    uartBus_CLK_I => s_uartBus_CLK_I,
    uartBus_RST_I => s_uartBus_RST_I,
    uartBus_DAT_I => s_uartBus_DAT_I,
    uartBus_DAT_O => s_uartBus_DAT_O,
    uartBus_ACK_O => s_uartBus_ACK_O,
    uartBus_ADDR_I => s_uartBus_ADDR_I,
    uartBus_CYC_I => s_uartBus_CYC_I,
    uartBus_ERR_O => s_uartBus_ERR_O,
    uartBus_LOCK_I => open,
    uartBus_SEL_I => s_uartBus_SEL_I,
    uartBus_STB_I => s_uartBus_STB_I,
    uartBus_WE_I => s_uartBus_WE_I,
    uartBus_CTI_I => s_uartBus_CTI_I,
    uartBus_BTE_I => open,
    picBus_CLK_I => s_picBus_CLK_I,
    picBus_RST_I => s_picBus_RST_I,
    picBus_DAT_I => open,
    picBus_DAT_O => s_picBus_DAT_O,
    picBus_ACK_O => s_picBus_ACK_O,
    picBus_ADDR_I => s_picBus_ADDR_I,
    picBus_CYC_I => s_picBus_CYC_I,
    picBus_ERR_O => s_picBus_ERR_O,
    picBus_LOCK_I => open,
    picBus_SEL_I => open,
    picBus_STB_I => s_picBus_STB_I,
    picBus_WE_I => s_picBus_WE_I,
    picBus_CTI_I => s_picBus_CTI_I,
    picBus_BTE_I => open,
    CLK_O => s_SYSCON_CLK_O,
    RST_O => s_SYSCON_RST_O);

end architecture;