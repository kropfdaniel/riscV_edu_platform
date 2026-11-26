library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity picBus is
    generic ( 
        DataBits    : integer := 32;  -- must be a multiple of 8, eg. 8, 16, 24, 32, ...
        AddrBits    : integer := 32;
        BaseAddress : std_logic_vector := std_logic_vector(to_unsigned(0,32))
    );
    port ( 
        CLK_I    : in  std_logic;
        RST_I    : in  std_logic;
        -- DAT_I is not supported (read only)
        DAT_O    : out std_logic_vector( DataBits-1 downto 0 );
        -- TAGD_I and TAGD_O are not implemented
        ACK_O    : out std_logic;
        ADDR_I   : in  std_logic_vector( AddrBits-1 downto 0 );
        CYC_I    : in  std_logic;
        ERR_O    : out std_logic;
        -- LOCK_I is not used in this module
        -- RTY_I is not implemented
        -- SEL_I is not used (module always returns a full word)
        STB_I    : in  std_logic;
        -- TGA_O and TGC_O are not implemented
        WE_I     : in  std_logic;
        CTI_I    : in  std_logic_vector( 2 downto 0 );
        -- BTE_I is not used in this module
         
        uart_irq  : in  std_logic;
        timer_irq : in  std_logic;

        total_irq : out std_logic
    );
end entity picBus;

architecture platformIndependent of picBus is
    --! wishbone acknowledge register
    signal s_ackReg               : std_logic;
    --! wishbone error register (error happens if CTI_I/="000")
    signal s_errorReg             : std_logic;
    --! flag if CYC_I and STB_I are set and the address on the bus is within the address space for this module
    signal s_isMyTransaction      : std_logic;
    --! flag if the transaction is mine and of type classic (CTI_I="000") and a read
    signal s_isCorrectTransaction : std_logic;
begin
    ERR_O <= s_errorReg;
    ACK_O <= s_ackReg;

    DAT_O(0)                   <= uart_irq;
    DAT_O(1)                   <= timer_irq;
    DAT_O(DataBits-1 downto 2) <= (others => '0');

    total_irq <= uart_irq or timer_irq;

    -- if the address on the bus is within the address space for this module
    s_isMyTransaction <= (CYC_I and STB_I) when ADDR_I( AddrBits-1 downto 2 ) = BaseAddress( AddrBits-1 downto 2 ) else '0';
    -- if it is classic cycle type and a read
    s_isCorrectTransaction <= s_isMyTransaction when (CTI_I = "000" and WE_I = '0') else '0'; 
  
    --! Wishbone interface process
    makeBusRegs : process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                s_ackReg         <= '0';
                s_errorReg       <= '0';
            else
                s_ackReg   <= not(s_ackReg) and s_isCorrectTransaction;
                s_errorReg <= not(s_errorReg) and s_isMyTransaction and not(s_isCorrectTransaction);
            end if;
        end if;
    end process makeBusRegs;

end architecture;
