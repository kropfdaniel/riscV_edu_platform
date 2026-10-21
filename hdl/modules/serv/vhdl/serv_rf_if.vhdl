----------------------------------------------------------------------------------
-- File: serv_rf_if.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV register file interface
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.serv_pkg.all;

entity serv_rf_if is
    generic(
        WITH_CSR       : boolean := true;
        W              : integer := 1;
        B              : integer := W-1
    );
    port(
        -- RF interface
        i_cnt_en            : in  std_logic;
        o_wreg0             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_wreg1             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_wen0              : out std_logic;
        o_wen1              : out std_logic;
        o_wdata0            : out std_logic_vector(B downto 0);
        o_wdata1            : out std_logic_vector(B downto 0);
        o_rreg0             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        o_rreg1             : out std_logic_vector((4 + (bool_to_int(WITH_CSR))) downto 0);
        i_rdata0            : in  std_logic_vector(B downto 0);
        i_rdata1            : in  std_logic_vector(B downto 0);
        -- Trap interface
        i_trap              : in  std_logic;
        i_mret              : in  std_logic;
        i_mepc              : in  std_logic_vector(B downto 0);
        i_mtval_pc          : in  std_logic;
        i_bufreg_q          : in  std_logic_vector(B downto 0);
        i_bad_pc            : in  std_logic_vector(B downto 0);
        o_csr_pc            : out std_logic_vector(B downto 0);
        -- CSR interface
        i_csr_en            : in  std_logic;
        i_csr_addr          : in  std_logic_vector(1 downto 0);
        i_csr               : in  std_logic_vector(B downto 0);
        o_csr               : out std_logic_vector(B downto 0);
        -- RD write port
        i_rd_wen            : in  std_logic;
        i_rd_waddr          : in  std_logic_vector(4 downto 0);
        i_ctrl_rd           : in  std_logic_vector(B downto 0);
        i_alu_rd            : in  std_logic_vector(B downto 0);
        i_rd_alu_en         : in  std_logic;
        i_csr_rd            : in  std_logic_vector(B downto 0);
        i_rd_csr_en         : in  std_logic;
        i_mem_rd            : in  std_logic_vector(B downto 0);
        i_rd_mem_en         : in  std_logic;
        -- RS1 read port
        i_rs1_raddr          : in  std_logic_vector(4 downto 0);
        o_rs1               : out std_logic_vector(B downto 0);
        -- RS2 read port
        i_rs2_raddr          : in  std_logic_vector(4 downto 0);
        o_rs2               : out std_logic_vector(B downto 0)
    );
end entity serv_rf_if;

architecture rtl of serv_rf_if is
    signal rd_wen : std_logic;
    signal rd     : std_logic_vector(B downto 0);
begin
    -- ********** Write side ***********
    rd_wen <= i_rd_wen and (or i_rd_waddr);

    gen_csr : if WITH_CSR generate
        signal mtval : std_logic_vector(B downto 0);
        signal sel_rs2 : std_logic;
    begin
        rd <= ((B downto 0 => i_rd_alu_en) and i_alu_rd) or 
              ((B downto 0 => i_rd_csr_en) and i_csr_rd) or 
              ((B downto 0 => i_rd_mem_en) and i_mem_rd) or 
              i_ctrl_rd;
        mtval <= i_bad_pc when (??i_mtval_pc) else i_bufreg_q;

        o_wdata0 <= mtval  when (??i_trap) else rd;
        o_wdata1 <= i_mepc when (??i_trap) else i_csr;

        -- Port 0 handles writes to mtval during traps and rd otherwise
        -- Port 1 handles writes to mepc during traps and csr accesses otherwise
        -- 
        -- GPR registers are mapped to address 0-31 (bits 0xxxxx).
        -- Following that are four CSR registers
        -- mscratch 100000
        -- mtvec    100001
        -- mepc     100010
        -- mtval    100011

        o_wreg0 <= 6B"100011" when (??i_trap) else ('0' & i_rd_waddr);
        o_wreg1 <= 6B"100010" when (??i_trap) else (4B"1000" & i_csr_addr);

        o_wen0 <= i_cnt_en and (i_trap or rd_wen);
        o_wen1 <= i_cnt_en and (i_trap or i_csr_en);

        -- ********** Read side ***********

        -- 0 : RS1
        -- 1 : RS2 / CSR

        o_rreg0 <= '0' & i_rs1_raddr;

        
        -- The address of the second read port (o_rreg1) can get assigned from four
        -- different sources
        -- 
        -- Normal operations : i_rs2_raddr
        -- CSR access        : i_csr_addr
        -- trap              : MTVEC
        -- mret              : MEPC
        -- 
        -- Address 0-31 in the RF are assigned to the GPRs. After that follows the four
        -- CSRs on addresses 32-35
        -- 
        -- 32 MSCRATCH
        -- 33 MTVEC
        -- 34 MEPC
        -- 35 MTVAL
        -- 
        -- The expression below is an optimized version of this logic
        sel_rs2 <= not(i_trap or i_mret or i_csr_en);
        o_rreg1 <= not sel_rs2 & 
                   (i_rs2_raddr(4 downto 2) and (2 downto 0 => sel_rs2)) &
                   ( ('0' & i_trap) or (i_mret & '0') or ((1 downto 0 => i_csr_en) and i_csr_addr) or 
                     ((1 downto 0 => sel_rs2) and i_rs2_raddr(1 downto 0)) );
        o_rs1 <= i_rdata0;
        o_rs2 <= i_rdata1;
        o_csr <= i_rdata1 and (B downto 0 => i_csr_en);
        o_csr_pc <= i_rdata1;
    end generate gen_csr;

    gen_no_csr : if not WITH_CSR generate
        rd <= i_ctrl_rd or 
              (i_alu_rd and (B downto 0 => i_rd_alu_en)) or 
              (i_mem_rd and (B downto 0 => i_rd_mem_en));
            
        o_wdata0 <= rd;
        o_wdata1 <= (others => '0');

        o_wreg0 <= i_rd_waddr;
        o_wreg1 <= (others => '0');

        o_wen0 <= i_cnt_en and rd_wen;
        o_wen1 <= '0';

        -- ********** Read side ***********

        o_rreg0 <= i_rs1_raddr;
        o_rreg1 <= i_rs2_raddr;

        o_rs1 <= i_rdata0;
        o_rs2 <= i_rdata1;
        o_csr <= (others => '0');
        o_csr_pc <= (others => '0');
    end generate gen_no_csr;
end architecture;