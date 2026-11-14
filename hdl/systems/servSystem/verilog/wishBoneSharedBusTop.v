module wishBoneSharedBusTop
  #( parameter DataBits = 32,
     parameter AddrBits = 32,
     parameter priorityScheme = 1)
   (
    // Here the signals for the master "serv_system_top" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire serv_system_top_CLK_I,
    output wire serv_system_top_RST_I,
    output wire [DataBits - 1:0] serv_system_top_DAT_I,
    input  wire [DataBits - 1:0] serv_system_top_DAT_O,
    output wire serv_system_top_ACK_I,
    input  wire [AddrBits - 1:0] serv_system_top_ADDR_O,
    input  wire serv_system_top_CYC_O,
    output wire serv_system_top_ERR_I,
    input  wire serv_system_top_LOCK_O,
    input  wire [(DataBits / 8) - 1:0] serv_system_top_SEL_O,
    input  wire serv_system_top_STB_O,
    input  wire serv_system_top_WE_O,
    input  wire [2:0] serv_system_top_CTI_O,
    input  wire [1:0] serv_system_top_BTE_O,

    // Here the signals for the slave "spiXipBus" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire spiXipBus_CLK_I,
    output wire spiXipBus_RST_I,
    output wire [DataBits - 1:0] spiXipBus_DAT_I,
    input  wire [DataBits - 1:0] spiXipBus_DAT_O,
    input  wire spiXipBus_ACK_O,
    output wire [AddrBits - 1:0] spiXipBus_ADDR_I,
    output wire spiXipBus_CYC_I,
    input  wire spiXipBus_ERR_O,
    output wire spiXipBus_LOCK_I,
    output wire [(DataBits / 8) - 1:0] spiXipBus_SEL_I,
    output wire spiXipBus_STB_I,
    output wire spiXipBus_WE_I,
    output wire [2:0] spiXipBus_CTI_I,
    output wire [1:0] spiXipBus_BTE_I,

    // Here the signals for the slave "srramSlave" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire srramSlave_CLK_I,
    output wire srramSlave_RST_I,
    output wire [DataBits - 1:0] srramSlave_DAT_I,
    input  wire [DataBits - 1:0] srramSlave_DAT_O,
    input  wire srramSlave_ACK_O,
    output wire [AddrBits - 1:0] srramSlave_ADDR_I,
    output wire srramSlave_CYC_I,
    input  wire srramSlave_ERR_O,
    output wire srramSlave_LOCK_I,
    output wire [(DataBits / 8) - 1:0] srramSlave_SEL_I,
    output wire srramSlave_STB_I,
    output wire srramSlave_WE_I,
    output wire [2:0] srramSlave_CTI_I,
    output wire [1:0] srramSlave_BTE_I,

    // Here the signals for the slave "spiBus" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire spiBus_CLK_I,
    output wire spiBus_RST_I,
    output wire [DataBits - 1:0] spiBus_DAT_I,
    input  wire [DataBits - 1:0] spiBus_DAT_O,
    input  wire spiBus_ACK_O,
    output wire [AddrBits - 1:0] spiBus_ADDR_I,
    output wire spiBus_CYC_I,
    input  wire spiBus_ERR_O,
    output wire spiBus_LOCK_I,
    output wire [(DataBits / 8) - 1:0] spiBus_SEL_I,
    output wire spiBus_STB_I,
    output wire spiBus_WE_I,
    output wire [2:0] spiBus_CTI_I,
    output wire [1:0] spiBus_BTE_I,

    // Here the signals for the slave "uartBus" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire uartBus_CLK_I,
    output wire uartBus_RST_I,
    output wire [DataBits - 1:0] uartBus_DAT_I,
    input  wire [DataBits - 1:0] uartBus_DAT_O,
    input  wire uartBus_ACK_O,
    output wire [AddrBits - 1:0] uartBus_ADDR_I,
    output wire uartBus_CYC_I,
    input  wire uartBus_ERR_O,
    output wire uartBus_LOCK_I,
    output wire [(DataBits / 8) - 1:0] uartBus_SEL_I,
    output wire uartBus_STB_I,
    output wire uartBus_WE_I,
    output wire [2:0] uartBus_CTI_I,
    output wire [1:0] uartBus_BTE_I,

    // Here the signals for the slave "picBus" are defined
    // Note that although the signals are noted with _O/_I their direction is oposite defined
    // as they connect directly with the same signals on the master.
    output wire picBus_CLK_I,
    output wire picBus_RST_I,
    output wire [DataBits - 1:0] picBus_DAT_I,
    input  wire [DataBits - 1:0] picBus_DAT_O,
    input  wire picBus_ACK_O,
    output wire [AddrBits - 1:0] picBus_ADDR_I,
    output wire picBus_CYC_I,
    input  wire picBus_ERR_O,
    output wire picBus_LOCK_I,
    output wire [(DataBits / 8) - 1:0] picBus_SEL_I,
    output wire picBus_STB_I,
    output wire picBus_WE_I,
    output wire [2:0] picBus_CTI_I,
    output wire [1:0] picBus_BTE_I,

    // Here the Syscon connections are defined
    // Connect the signals with the same name together
    // Note that although we have the _O suffix these are inputs as
    // they are outputs on the syscon component
    input wire CLK_O,
    input wire RST_O);

  wire [DataBits - 1:0] s_masked_serv_system_top_DAT_O;
  wire [AddrBits - 1:0] s_masked_serv_system_top_ADDR_O;
  wire s_masked_serv_system_top_CYC_O;
  wire s_masked_serv_system_top_LOCK_O;
  wire [(DataBits / 8) - 1:0] s_masked_serv_system_top_SEL_O;
  wire s_masked_serv_system_top_STB_O;
  wire s_masked_serv_system_top_WE_O;
  wire [2:0] s_masked_serv_system_top_CTI_O;
  wire [1:0] s_masked_serv_system_top_BTE_O;
  wire [DataBits - 1:0] s_masked_spiXipBus_DAT_O;
  wire [DataBits - 1:0] s_masked_srramSlave_DAT_O;
  wire [DataBits - 1:0] s_masked_spiBus_DAT_O;
  wire [DataBits - 1:0] s_masked_uartBus_DAT_O;
  wire [DataBits - 1:0] s_masked_picBus_DAT_O;
  wire [DataBits - 1:0] s_sharedBusMaster_DAT;
  wire s_sharedBusMaster_ACK;
  wire s_sharedBusMaster_ERR;
  wire [DataBits - 1:0] s_sharedBusSlave_DAT;
  wire [AddrBits - 1:0] s_sharedBusSlave_ADDR;
  wire s_sharedBusSlave_CYC;
  wire s_sharedBusSlave_LOCK;
  wire [(DataBits / 8) - 1:0] s_sharedBusSlave_SEL;
  wire s_sharedBusSlave_STB;
  wire s_sharedBusSlave_WE;
  wire [2:0] s_sharedBusSlave_CTI;
  wire [1:0] s_sharedBusSlave_BTE;
  wire s_arbiterMasterCycs;
  wire s_arbiterMasterLocks;
  wire s_arbiterBusEnables;
  wire s_arbiterErrorOut;
  reg s_arbiterMaskReg;
  reg s_arbiterEnablesReg;
  reg [15:0] s_arbiterTimeOutReg;
  reg s_arbiterBusIsUsedReg;
  wire s_arbiterBeforeMeCarries;
  wire s_arbiterAferMeCarries;
  wire s_arbiterBeforeMeMask;
  wire s_arbiterAfterMeMask;
  wire s_arbiterNewMask;
  wire s_arbiterServeRequest;
  wire s_arbiterIsTimeOut;
  wire s_arbiterIsBusRelease;

  // Here we connect all clocks and resets to the syscon
  assign serv_system_top_CLK_I = CLK_O;
  assign serv_system_top_RST_I = RST_O;
  assign spiXipBus_CLK_I = CLK_O;
  assign spiXipBus_RST_I = RST_O;
  assign srramSlave_CLK_I = CLK_O;
  assign srramSlave_RST_I = RST_O;
  assign spiBus_CLK_I = CLK_O;
  assign spiBus_RST_I = RST_O;
  assign uartBus_CLK_I = CLK_O;
  assign uartBus_RST_I = RST_O;
  assign picBus_CLK_I = CLK_O;
  assign picBus_RST_I = RST_O;

  // Here the arbiter signals are mapped
  assign s_arbiterMasterLocks = serv_system_top_LOCK_O;
  assign s_arbiterMasterCycs = serv_system_top_CYC_O;

  // Here the masked slave signals are defined
  assign s_masked_spiXipBus_DAT_O = (spiXipBus_ACK_O == 1'b1) ? spiXipBus_DAT_O : {DataBits{1'b0}};
  assign s_masked_srramSlave_DAT_O = (srramSlave_ACK_O == 1'b1) ? srramSlave_DAT_O : {DataBits{1'b0}};
  assign s_masked_spiBus_DAT_O = (spiBus_ACK_O == 1'b1) ? spiBus_DAT_O : {DataBits{1'b0}};
  assign s_masked_uartBus_DAT_O = (uartBus_ACK_O == 1'b1) ? uartBus_DAT_O : {DataBits{1'b0}};
  assign s_masked_picBus_DAT_O = (picBus_ACK_O == 1'b1) ? picBus_DAT_O : {DataBits{1'b0}};

  // Here the masked master signals are defined
  assign s_masked_serv_system_top_DAT_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_DAT_O : {DataBits{1'b0}};
  assign s_masked_serv_system_top_ADDR_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_ADDR_O : {AddrBits{1'b0}};
  assign s_masked_serv_system_top_CYC_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_CYC_O : 1'b0;
  assign s_masked_serv_system_top_LOCK_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_LOCK_O : 1'b0;
  assign s_masked_serv_system_top_SEL_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_SEL_O : {(DataBits / 8){1'b0}};
  assign s_masked_serv_system_top_STB_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_STB_O : 1'b0;
  assign s_masked_serv_system_top_WE_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_WE_O : 1'b0;
  assign s_masked_serv_system_top_CTI_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_CTI_O : {3{1'b0}};
  assign s_masked_serv_system_top_BTE_O = (s_arbiterBusEnables == 1'b1) ? serv_system_top_BTE_O : {2{1'b0}};

  // Here the slave -> master databus is defined
  assign serv_system_top_DAT_I = s_sharedBusMaster_DAT;
  assign s_sharedBusMaster_DAT =
      s_masked_spiXipBus_DAT_O |
      s_masked_srramSlave_DAT_O |
      s_masked_spiBus_DAT_O |
      s_masked_uartBus_DAT_O |
      s_masked_picBus_DAT_O;

  // Here the master -> slave databus is defined
  assign spiXipBus_DAT_I = s_sharedBusSlave_DAT;
  assign srramSlave_DAT_I = s_sharedBusSlave_DAT;
  assign spiBus_DAT_I = s_sharedBusSlave_DAT;
  assign uartBus_DAT_I = s_sharedBusSlave_DAT;
  assign picBus_DAT_I = s_sharedBusSlave_DAT;
  assign s_sharedBusSlave_DAT =
      s_masked_serv_system_top_DAT_O;

  // Here all master inputs are mapped
  assign serv_system_top_ACK_I = s_sharedBusMaster_ACK & s_arbiterBusEnables;
  assign serv_system_top_ERR_I = s_sharedBusMaster_ERR & s_arbiterBusEnables;
  assign s_sharedBusMaster_ACK =
      spiXipBus_ACK_O |
      srramSlave_ACK_O |
      spiBus_ACK_O |
      uartBus_ACK_O |
      picBus_ACK_O;
  assign s_sharedBusMaster_ERR =
      s_arbiterErrorOut |
      spiXipBus_ERR_O |
      srramSlave_ERR_O |
      spiBus_ERR_O |
      uartBus_ERR_O |
      picBus_ERR_O;

  // Here all slave inputs are mapped
  assign spiXipBus_ADDR_I = s_sharedBusSlave_ADDR;
  assign spiXipBus_CYC_I = s_sharedBusSlave_CYC;
  assign spiXipBus_LOCK_I = s_sharedBusSlave_LOCK;
  assign spiXipBus_SEL_I = s_sharedBusSlave_SEL;
  assign spiXipBus_STB_I = s_sharedBusSlave_STB;
  assign spiXipBus_WE_I = s_sharedBusSlave_WE;
  assign spiXipBus_CTI_I = s_sharedBusSlave_CTI;
  assign spiXipBus_BTE_I = s_sharedBusSlave_BTE;
  assign srramSlave_ADDR_I = s_sharedBusSlave_ADDR;
  assign srramSlave_CYC_I = s_sharedBusSlave_CYC;
  assign srramSlave_LOCK_I = s_sharedBusSlave_LOCK;
  assign srramSlave_SEL_I = s_sharedBusSlave_SEL;
  assign srramSlave_STB_I = s_sharedBusSlave_STB;
  assign srramSlave_WE_I = s_sharedBusSlave_WE;
  assign srramSlave_CTI_I = s_sharedBusSlave_CTI;
  assign srramSlave_BTE_I = s_sharedBusSlave_BTE;
  assign spiBus_ADDR_I = s_sharedBusSlave_ADDR;
  assign spiBus_CYC_I = s_sharedBusSlave_CYC;
  assign spiBus_LOCK_I = s_sharedBusSlave_LOCK;
  assign spiBus_SEL_I = s_sharedBusSlave_SEL;
  assign spiBus_STB_I = s_sharedBusSlave_STB;
  assign spiBus_WE_I = s_sharedBusSlave_WE;
  assign spiBus_CTI_I = s_sharedBusSlave_CTI;
  assign spiBus_BTE_I = s_sharedBusSlave_BTE;
  assign uartBus_ADDR_I = s_sharedBusSlave_ADDR;
  assign uartBus_CYC_I = s_sharedBusSlave_CYC;
  assign uartBus_LOCK_I = s_sharedBusSlave_LOCK;
  assign uartBus_SEL_I = s_sharedBusSlave_SEL;
  assign uartBus_STB_I = s_sharedBusSlave_STB;
  assign uartBus_WE_I = s_sharedBusSlave_WE;
  assign uartBus_CTI_I = s_sharedBusSlave_CTI;
  assign uartBus_BTE_I = s_sharedBusSlave_BTE;
  assign picBus_ADDR_I = s_sharedBusSlave_ADDR;
  assign picBus_CYC_I = s_sharedBusSlave_CYC;
  assign picBus_LOCK_I = s_sharedBusSlave_LOCK;
  assign picBus_SEL_I = s_sharedBusSlave_SEL;
  assign picBus_STB_I = s_sharedBusSlave_STB;
  assign picBus_WE_I = s_sharedBusSlave_WE;
  assign picBus_CTI_I = s_sharedBusSlave_CTI;
  assign picBus_BTE_I = s_sharedBusSlave_BTE;
  assign s_sharedBusSlave_ADDR =
      s_masked_serv_system_top_ADDR_O;
  assign s_sharedBusSlave_CYC =
      s_masked_serv_system_top_CYC_O;
  assign s_sharedBusSlave_LOCK =
      s_masked_serv_system_top_LOCK_O;
  assign s_sharedBusSlave_SEL =
      s_masked_serv_system_top_SEL_O;
  assign s_sharedBusSlave_STB =
      s_masked_serv_system_top_STB_O;
  assign s_sharedBusSlave_WE =
      s_masked_serv_system_top_WE_O;
  assign s_sharedBusSlave_CTI =
      s_masked_serv_system_top_CTI_O;
  assign s_sharedBusSlave_BTE =
      s_masked_serv_system_top_BTE_O;

  // Here the arbiter is defined
  assign s_arbiterBusEnables = 1'b1;
  assign s_arbiterErrorOut = s_arbiterIsTimeOut;
  assign s_arbiterIsTimeOut = (s_arbiterTimeOutReg == 16'd0) ? 1'b1 : 1'b0;
  always @(posedge CLK_O)
  begin
    s_arbiterTimeOutReg <= (serv_system_top_CYC_O == 1'b0 || s_sharedBusMaster_ACK == 1'b1) ? {16{1'b1}} : (s_arbiterIsTimeOut == 1'b0) ? s_arbiterTimeOutReg - 16'd1 : s_arbiterTimeOutReg;
  end
endmodule