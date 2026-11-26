localparam AddrBits = 32;
localparam DataBits = 32;
localparam priorityScheme = 1;

// Here all signals are defined that are used to connect the
// master and slaves to the shared bus component.
// You can copy-paste them in your toplevel file.

  wire s_serv_wb_top_CLK_I;
  wire s_serv_wb_top_RST_I;
  wire [DataBits - 1:0] s_serv_wb_top_DAT_I;
  wire [DataBits - 1:0] s_serv_wb_top_DAT_O;
  wire s_serv_wb_top_ACK_I;
  wire [AddrBits - 1:0] s_serv_wb_top_ADDR_O;
  wire s_serv_wb_top_CYC_O;
  wire s_serv_wb_top_ERR_I;
  wire s_serv_wb_top_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_serv_wb_top_SEL_O;
  wire s_serv_wb_top_STB_O;
  wire s_serv_wb_top_WE_O;
  wire [2:0] s_serv_wb_top_CTI_O;
  wire [1:0] s_serv_wb_top_BTE_O;
  wire s_spiXipBus_CLK_I;
  wire s_spiXipBus_RST_I;
  wire [DataBits - 1:0] s_spiXipBus_DAT_I;
  wire [DataBits - 1:0] s_spiXipBus_DAT_O;
  wire s_spiXipBus_ACK_O;
  wire [AddrBits - 1:0] s_spiXipBus_ADDR_I;
  wire s_spiXipBus_CYC_I;
  wire s_spiXipBus_ERR_O;
  wire s_spiXipBus_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_spiXipBus_SEL_I;
  wire s_spiXipBus_STB_I;
  wire s_spiXipBus_WE_I;
  wire [2:0] s_spiXipBus_CTI_I;
  wire [1:0] s_spiXipBus_BTE_I;
  wire s_sramSlave_CLK_I;
  wire s_sramSlave_RST_I;
  wire [DataBits - 1:0] s_sramSlave_DAT_I;
  wire [DataBits - 1:0] s_sramSlave_DAT_O;
  wire s_sramSlave_ACK_O;
  wire [AddrBits - 1:0] s_sramSlave_ADDR_I;
  wire s_sramSlave_CYC_I;
  wire s_sramSlave_ERR_O;
  wire s_sramSlave_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_sramSlave_SEL_I;
  wire s_sramSlave_STB_I;
  wire s_sramSlave_WE_I;
  wire [2:0] s_sramSlave_CTI_I;
  wire [1:0] s_sramSlave_BTE_I;
  wire s_spiBus_CLK_I;
  wire s_spiBus_RST_I;
  wire [DataBits - 1:0] s_spiBus_DAT_I;
  wire [DataBits - 1:0] s_spiBus_DAT_O;
  wire s_spiBus_ACK_O;
  wire [AddrBits - 1:0] s_spiBus_ADDR_I;
  wire s_spiBus_CYC_I;
  wire s_spiBus_ERR_O;
  wire s_spiBus_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_spiBus_SEL_I;
  wire s_spiBus_STB_I;
  wire s_spiBus_WE_I;
  wire [2:0] s_spiBus_CTI_I;
  wire [1:0] s_spiBus_BTE_I;
  wire s_uartBus_CLK_I;
  wire s_uartBus_RST_I;
  wire [DataBits - 1:0] s_uartBus_DAT_I;
  wire [DataBits - 1:0] s_uartBus_DAT_O;
  wire s_uartBus_ACK_O;
  wire [AddrBits - 1:0] s_uartBus_ADDR_I;
  wire s_uartBus_CYC_I;
  wire s_uartBus_ERR_O;
  wire s_uartBus_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_uartBus_SEL_I;
  wire s_uartBus_STB_I;
  wire s_uartBus_WE_I;
  wire [2:0] s_uartBus_CTI_I;
  wire [1:0] s_uartBus_BTE_I;
  wire s_picBus_CLK_I;
  wire s_picBus_RST_I;
  wire [DataBits - 1:0] s_picBus_DAT_I;
  wire [DataBits - 1:0] s_picBus_DAT_O;
  wire s_picBus_ACK_O;
  wire [AddrBits - 1:0] s_picBus_ADDR_I;
  wire s_picBus_CYC_I;
  wire s_picBus_ERR_O;
  wire s_picBus_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_picBus_SEL_I;
  wire s_picBus_STB_I;
  wire s_picBus_WE_I;
  wire [2:0] s_picBus_CTI_I;
  wire [1:0] s_picBus_BTE_I;
  wire s_timer16_CLK_I;
  wire s_timer16_RST_I;
  wire [DataBits - 1:0] s_timer16_DAT_I;
  wire [DataBits - 1:0] s_timer16_DAT_O;
  wire s_timer16_ACK_O;
  wire [AddrBits - 1:0] s_timer16_ADDR_I;
  wire s_timer16_CYC_I;
  wire s_timer16_ERR_O;
  wire s_timer16_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_timer16_SEL_I;
  wire s_timer16_STB_I;
  wire s_timer16_WE_I;
  wire [2:0] s_timer16_CTI_I;
  wire [1:0] s_timer16_BTE_I;
  wire s_leds_CLK_I;
  wire s_leds_RST_I;
  wire [DataBits - 1:0] s_leds_DAT_I;
  wire [DataBits - 1:0] s_leds_DAT_O;
  wire s_leds_ACK_O;
  wire [AddrBits - 1:0] s_leds_ADDR_I;
  wire s_leds_CYC_I;
  wire s_leds_ERR_O;
  wire s_leds_LOCK_I;
  wire [(DataBits / 8) - 1:0] s_leds_SEL_I;
  wire s_leds_STB_I;
  wire s_leds_WE_I;
  wire [2:0] s_leds_CTI_I;
  wire [1:0] s_leds_BTE_I;
  wire s_SYSCON_CLK_O;
  wire s_SYSCON_RST_O;

// Here all your master and slave connections are mapped
// Probably you have to change it slightly to adapt to your
// masters/slaves

  serv_wb_top #(
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busMaster_serv_wb_top (
    .CLK_I(s_serv_wb_top_CLK_I),
    .RST_I(s_serv_wb_top_RST_I),
    .DAT_I(s_serv_wb_top_DAT_I),
    .DAT_O(s_serv_wb_top_DAT_O),
    .ACK_I(s_serv_wb_top_ACK_I),
    .ADDR_O(s_serv_wb_top_ADDR_O),
    .CYC_O(s_serv_wb_top_CYC_O),
    .ERR_I(s_serv_wb_top_ERR_I),
    .LOCK_O(s_serv_wb_top_LOCK_O),
    .SEL_O(s_serv_wb_top_SEL_O),
    .STB_O(s_serv_wb_top_STB_O),
    .WE_O(s_serv_wb_top_WE_O),
    .CTI_O(s_serv_wb_top_CTI_O),
    .BTE_O(s_serv_wb_top_BTE_O));

  spiXipBus #(
    .BaseAddress('h0),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_spiXipBus (
    .CLK_I(s_spiXipBus_CLK_I),
    .RST_I(s_spiXipBus_RST_I),
    .DAT_I(s_spiXipBus_DAT_I),
    .DAT_O(s_spiXipBus_DAT_O),
    .ACK_O(s_spiXipBus_ACK_O),
    .ADDR_I(s_spiXipBus_ADDR_I),
    .CYC_I(s_spiXipBus_CYC_I),
    .ERR_O(s_spiXipBus_ERR_O),
    .LOCK_I(s_spiXipBus_LOCK_I),
    .SEL_I(s_spiXipBus_SEL_I),
    .STB_I(s_spiXipBus_STB_I),
    .WE_I(s_spiXipBus_WE_I),
    .CTI_I(s_spiXipBus_CTI_I),
    .BTE_I(s_spiXipBus_BTE_I));

  sramSlave #(
    .BaseAddress('h40000000),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_sramSlave (
    .CLK_I(s_sramSlave_CLK_I),
    .RST_I(s_sramSlave_RST_I),
    .DAT_I(s_sramSlave_DAT_I),
    .DAT_O(s_sramSlave_DAT_O),
    .ACK_O(s_sramSlave_ACK_O),
    .ADDR_I(s_sramSlave_ADDR_I),
    .CYC_I(s_sramSlave_CYC_I),
    .ERR_O(s_sramSlave_ERR_O),
    .LOCK_I(s_sramSlave_LOCK_I),
    .SEL_I(s_sramSlave_SEL_I),
    .STB_I(s_sramSlave_STB_I),
    .WE_I(s_sramSlave_WE_I),
    .CTI_I(s_sramSlave_CTI_I),
    .BTE_I(s_sramSlave_BTE_I));

  spiBus #(
    .BaseAddress('h80000000),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_spiBus (
    .CLK_I(s_spiBus_CLK_I),
    .RST_I(s_spiBus_RST_I),
    .DAT_I(s_spiBus_DAT_I),
    .DAT_O(s_spiBus_DAT_O),
    .ACK_O(s_spiBus_ACK_O),
    .ADDR_I(s_spiBus_ADDR_I),
    .CYC_I(s_spiBus_CYC_I),
    .ERR_O(s_spiBus_ERR_O),
    .LOCK_I(s_spiBus_LOCK_I),
    .SEL_I(s_spiBus_SEL_I),
    .STB_I(s_spiBus_STB_I),
    .WE_I(s_spiBus_WE_I),
    .CTI_I(s_spiBus_CTI_I),
    .BTE_I(s_spiBus_BTE_I));

  uartBus #(
    .BaseAddress('h80000100),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_uartBus (
    .CLK_I(s_uartBus_CLK_I),
    .RST_I(s_uartBus_RST_I),
    .DAT_I(s_uartBus_DAT_I),
    .DAT_O(s_uartBus_DAT_O),
    .ACK_O(s_uartBus_ACK_O),
    .ADDR_I(s_uartBus_ADDR_I),
    .CYC_I(s_uartBus_CYC_I),
    .ERR_O(s_uartBus_ERR_O),
    .LOCK_I(s_uartBus_LOCK_I),
    .SEL_I(s_uartBus_SEL_I),
    .STB_I(s_uartBus_STB_I),
    .WE_I(s_uartBus_WE_I),
    .CTI_I(s_uartBus_CTI_I),
    .BTE_I(s_uartBus_BTE_I));

  picBus #(
    .BaseAddress('h80000200),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_picBus (
    .CLK_I(s_picBus_CLK_I),
    .RST_I(s_picBus_RST_I),
    .DAT_I(s_picBus_DAT_I),
    .DAT_O(s_picBus_DAT_O),
    .ACK_O(s_picBus_ACK_O),
    .ADDR_I(s_picBus_ADDR_I),
    .CYC_I(s_picBus_CYC_I),
    .ERR_O(s_picBus_ERR_O),
    .LOCK_I(s_picBus_LOCK_I),
    .SEL_I(s_picBus_SEL_I),
    .STB_I(s_picBus_STB_I),
    .WE_I(s_picBus_WE_I),
    .CTI_I(s_picBus_CTI_I),
    .BTE_I(s_picBus_BTE_I));

  timer16 #(
    .BaseAddress('h80000300),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_timer16 (
    .CLK_I(s_timer16_CLK_I),
    .RST_I(s_timer16_RST_I),
    .DAT_I(s_timer16_DAT_I),
    .DAT_O(s_timer16_DAT_O),
    .ACK_O(s_timer16_ACK_O),
    .ADDR_I(s_timer16_ADDR_I),
    .CYC_I(s_timer16_CYC_I),
    .ERR_O(s_timer16_ERR_O),
    .LOCK_I(s_timer16_LOCK_I),
    .SEL_I(s_timer16_SEL_I),
    .STB_I(s_timer16_STB_I),
    .WE_I(s_timer16_WE_I),
    .CTI_I(s_timer16_CTI_I),
    .BTE_I(s_timer16_BTE_I));

  leds #(
    .BaseAddress('h80000800),
    .AddrBits(AddrBits),
    .DataBits(DataBits)
  ) busSlave_leds (
    .CLK_I(s_leds_CLK_I),
    .RST_I(s_leds_RST_I),
    .DAT_I(s_leds_DAT_I),
    .DAT_O(s_leds_DAT_O),
    .ACK_O(s_leds_ACK_O),
    .ADDR_I(s_leds_ADDR_I),
    .CYC_I(s_leds_CYC_I),
    .ERR_O(s_leds_ERR_O),
    .LOCK_I(s_leds_LOCK_I),
    .SEL_I(s_leds_SEL_I),
    .STB_I(s_leds_STB_I),
    .WE_I(s_leds_WE_I),
    .CTI_I(s_leds_CTI_I),
    .BTE_I(s_leds_BTE_I));

//Finally here the wishboneBus is mapped
  wishBoneSharedBusTop #(
    .AddrBits(AddrBits),
    .DataBits(DataBits),
    .priorityScheme(priorityScheme)
  ) wishboneBus (
    .serv_wb_top_CLK_I(s_serv_wb_top_CLK_I),
    .serv_wb_top_RST_I(s_serv_wb_top_RST_I),
    .serv_wb_top_DAT_I(s_serv_wb_top_DAT_I),
    .serv_wb_top_DAT_O(s_serv_wb_top_DAT_O),
    .serv_wb_top_ACK_I(s_serv_wb_top_ACK_I),
    .serv_wb_top_ADDR_O(s_serv_wb_top_ADDR_O),
    .serv_wb_top_CYC_O(s_serv_wb_top_CYC_O),
    .serv_wb_top_ERR_I(s_serv_wb_top_ERR_I),
    .serv_wb_top_LOCK_O(s_serv_wb_top_LOCK_O),
    .serv_wb_top_SEL_O(s_serv_wb_top_SEL_O),
    .serv_wb_top_STB_O(s_serv_wb_top_STB_O),
    .serv_wb_top_WE_O(s_serv_wb_top_WE_O),
    .serv_wb_top_CTI_O(s_serv_wb_top_CTI_O),
    .serv_wb_top_BTE_O(s_serv_wb_top_BTE_O),
    .spiXipBus_CLK_I(s_spiXipBus_CLK_I),
    .spiXipBus_RST_I(s_spiXipBus_RST_I),
    .spiXipBus_DAT_I(s_spiXipBus_DAT_I),
    .spiXipBus_DAT_O(s_spiXipBus_DAT_O),
    .spiXipBus_ACK_O(s_spiXipBus_ACK_O),
    .spiXipBus_ADDR_I(s_spiXipBus_ADDR_I),
    .spiXipBus_CYC_I(s_spiXipBus_CYC_I),
    .spiXipBus_ERR_O(s_spiXipBus_ERR_O),
    .spiXipBus_LOCK_I(s_spiXipBus_LOCK_I),
    .spiXipBus_SEL_I(s_spiXipBus_SEL_I),
    .spiXipBus_STB_I(s_spiXipBus_STB_I),
    .spiXipBus_WE_I(s_spiXipBus_WE_I),
    .spiXipBus_CTI_I(s_spiXipBus_CTI_I),
    .spiXipBus_BTE_I(s_spiXipBus_BTE_I),
    .sramSlave_CLK_I(s_sramSlave_CLK_I),
    .sramSlave_RST_I(s_sramSlave_RST_I),
    .sramSlave_DAT_I(s_sramSlave_DAT_I),
    .sramSlave_DAT_O(s_sramSlave_DAT_O),
    .sramSlave_ACK_O(s_sramSlave_ACK_O),
    .sramSlave_ADDR_I(s_sramSlave_ADDR_I),
    .sramSlave_CYC_I(s_sramSlave_CYC_I),
    .sramSlave_ERR_O(s_sramSlave_ERR_O),
    .sramSlave_LOCK_I(s_sramSlave_LOCK_I),
    .sramSlave_SEL_I(s_sramSlave_SEL_I),
    .sramSlave_STB_I(s_sramSlave_STB_I),
    .sramSlave_WE_I(s_sramSlave_WE_I),
    .sramSlave_CTI_I(s_sramSlave_CTI_I),
    .sramSlave_BTE_I(s_sramSlave_BTE_I),
    .spiBus_CLK_I(s_spiBus_CLK_I),
    .spiBus_RST_I(s_spiBus_RST_I),
    .spiBus_DAT_I(s_spiBus_DAT_I),
    .spiBus_DAT_O(s_spiBus_DAT_O),
    .spiBus_ACK_O(s_spiBus_ACK_O),
    .spiBus_ADDR_I(s_spiBus_ADDR_I),
    .spiBus_CYC_I(s_spiBus_CYC_I),
    .spiBus_ERR_O(s_spiBus_ERR_O),
    .spiBus_LOCK_I(s_spiBus_LOCK_I),
    .spiBus_SEL_I(s_spiBus_SEL_I),
    .spiBus_STB_I(s_spiBus_STB_I),
    .spiBus_WE_I(s_spiBus_WE_I),
    .spiBus_CTI_I(s_spiBus_CTI_I),
    .spiBus_BTE_I(s_spiBus_BTE_I),
    .uartBus_CLK_I(s_uartBus_CLK_I),
    .uartBus_RST_I(s_uartBus_RST_I),
    .uartBus_DAT_I(s_uartBus_DAT_I),
    .uartBus_DAT_O(s_uartBus_DAT_O),
    .uartBus_ACK_O(s_uartBus_ACK_O),
    .uartBus_ADDR_I(s_uartBus_ADDR_I),
    .uartBus_CYC_I(s_uartBus_CYC_I),
    .uartBus_ERR_O(s_uartBus_ERR_O),
    .uartBus_LOCK_I(s_uartBus_LOCK_I),
    .uartBus_SEL_I(s_uartBus_SEL_I),
    .uartBus_STB_I(s_uartBus_STB_I),
    .uartBus_WE_I(s_uartBus_WE_I),
    .uartBus_CTI_I(s_uartBus_CTI_I),
    .uartBus_BTE_I(s_uartBus_BTE_I),
    .picBus_CLK_I(s_picBus_CLK_I),
    .picBus_RST_I(s_picBus_RST_I),
    .picBus_DAT_I(s_picBus_DAT_I),
    .picBus_DAT_O(s_picBus_DAT_O),
    .picBus_ACK_O(s_picBus_ACK_O),
    .picBus_ADDR_I(s_picBus_ADDR_I),
    .picBus_CYC_I(s_picBus_CYC_I),
    .picBus_ERR_O(s_picBus_ERR_O),
    .picBus_LOCK_I(s_picBus_LOCK_I),
    .picBus_SEL_I(s_picBus_SEL_I),
    .picBus_STB_I(s_picBus_STB_I),
    .picBus_WE_I(s_picBus_WE_I),
    .picBus_CTI_I(s_picBus_CTI_I),
    .picBus_BTE_I(s_picBus_BTE_I),
    .timer16_CLK_I(s_timer16_CLK_I),
    .timer16_RST_I(s_timer16_RST_I),
    .timer16_DAT_I(s_timer16_DAT_I),
    .timer16_DAT_O(s_timer16_DAT_O),
    .timer16_ACK_O(s_timer16_ACK_O),
    .timer16_ADDR_I(s_timer16_ADDR_I),
    .timer16_CYC_I(s_timer16_CYC_I),
    .timer16_ERR_O(s_timer16_ERR_O),
    .timer16_LOCK_I(s_timer16_LOCK_I),
    .timer16_SEL_I(s_timer16_SEL_I),
    .timer16_STB_I(s_timer16_STB_I),
    .timer16_WE_I(s_timer16_WE_I),
    .timer16_CTI_I(s_timer16_CTI_I),
    .timer16_BTE_I(s_timer16_BTE_I),
    .leds_CLK_I(s_leds_CLK_I),
    .leds_RST_I(s_leds_RST_I),
    .leds_DAT_I(s_leds_DAT_I),
    .leds_DAT_O(s_leds_DAT_O),
    .leds_ACK_O(s_leds_ACK_O),
    .leds_ADDR_I(s_leds_ADDR_I),
    .leds_CYC_I(s_leds_CYC_I),
    .leds_ERR_O(s_leds_ERR_O),
    .leds_LOCK_I(s_leds_LOCK_I),
    .leds_SEL_I(s_leds_SEL_I),
    .leds_STB_I(s_leds_STB_I),
    .leds_WE_I(s_leds_WE_I),
    .leds_CTI_I(s_leds_CTI_I),
    .leds_BTE_I(s_leds_BTE_I),
    .CLK_O(s_SYSCON_CLK_O),
    .RST_O(s_SYSCON_RST_O));

