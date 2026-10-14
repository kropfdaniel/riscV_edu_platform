----------------------------------------------------------------------------------
-- File: serv_compdec.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: Decodes RISC-V compressed instructions into their RV32i equivalent
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2018 ETH Zurich and University of Bologna
--              Original License: Apache-2.0
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_compdec is
    port(
        i_clk           : in  std_logic;
        i_instr         : in  std_logic_vector(31 downto 0);
        i_ack           : in  std_logic;
        o_instr         : out std_logic_vector(31 downto 0);
        o_iscomp        : out std_logic
    );
end entity serv_compdec;

architecture rtl of serv_compdec is
    constant OPCODE_LOAD    : std_logic_vector(6 downto 0) := 7x"03";
    constant OPCODE_OP_IMM  : std_logic_vector(6 downto 0) := 7x"13";
    constant OPCODE_STORE   : std_logic_vector(6 downto 0) := 7x"23";
    constant OPCODE_OP      : std_logic_vector(6 downto 0) := 7x"33";
    constant OPCODE_LUI     : std_logic_vector(6 downto 0) := 7x"37";
    constant OPCODE_BRANCH  : std_logic_vector(6 downto 0) := 7x"63";
    constant OPCODE_JALR    : std_logic_vector(6 downto 0) := 7x"67";
    constant OPCODE_JAL     : std_logic_vector(6 downto 0) := 7x"6f";

    signal comp_instr : std_logic_vector(31 downto 0);
    signal illegal_instr : std_logic;
begin
    o_instr <= i_instr when illegal_instr = '1' else comp_instr;

    process(i_clk) 
    begin
        if rising_edge(i_clk) and i_ack='1' then
            o_iscomp <= not illegal_instr;
        end if;
    end process;

    process(all)
    begin
        -- By default, forward incoming instruction, mark it as legal.
        comp_instr <= i_instr;
        illegal_instr <= '0';

        -- Check if incoming instruction is compressed.
        case i_instr(1 downto 0) is 
            -- C0
            when 2B"00" =>
                case i_instr(15 downto 14) is 
                    when 2B"00" =>
                        -- c.addi4spn -> addi rd', x2, imm
                        comp_instr <= 2B"00" & i_instr(10 downto 7) & i_instr(12 downto 11) &
                                      i_instr(5) & i_instr(6) & 2B"00" & 5x"02" & 3B"000" & 2B"01" &
                                      i_instr(4 downto 2) & OPCODE_OP_IMM;
                    when 2B"01" =>
                        -- c.lw -> lw rd', imm(rs1')
                        comp_instr <= 5B"0" & i_instr(5) & i_instr(12 downto 10) & i_instr(6) &
                                      2B"00" & 2B"01" & i_instr(9 downto 7) & 3B"010" & 2B"01" & 
                                      i_instr(4 downto 2) & OPCODE_LOAD;
                    when 2B"11" =>
                        -- c.sw -> sw rs2', imm(rs1')
                        comp_instr <= 5B"0" & i_instr(5) & i_instr(12) & 2B"01" & i_instr(4 downto 2) &
                                      2B"01" & i_instr(9 downto 7) & 3B"010" & i_instr(11 downto 10) &
                                      i_instr(6) & 2B"00" & OPCODE_STORE;
                    when 2B"10" => illegal_instr <= '1';
                    when others => null;
                end case;

            -- C1

            -- Register address checks for RV32E are performed in the regular instruction decoder.
            -- If this check fails, an illegal instruction exception is triggered and the controller
            -- writes the actual faulting instruction to mtval.
            when 2B"01" =>
                case i_instr(15 downto 13) is 
                    when 3B"000" =>
                        -- c.addi -> addi rd, rd, nzimm
                        -- c.nop
                        comp_instr <= (31 downto 26 => i_instr(12)) & i_instr(12) & i_instr(6 downto 2) &
                                      i_instr(11 downto 7) & 3B"000" & i_instr(11 downto 7) & OPCODE_OP_IMM;
                    when 3B"001" | 3B"101" =>
                        -- 001: c.jal -> jal x1, imm
                        -- 101: c.j   -> jal x0, imm
                        comp_instr <= i_instr(12) & i_instr(8) & i_instr(10 downto 9) & i_instr(6) &
                                      i_instr(7) & i_instr(2) & i_instr(11) & i_instr(5 downto 3) &
                                      (20 downto 12 => i_instr(12)) & 4B"0000" & not i_instr(15) & OPCODE_JAL;
                    when 3B"010" =>
                        -- c.li -> addi rd, x0, nzimm
                        -- (c.li hints are translated into an addi hint)
                        comp_instr <= (31 downto 26 => i_instr(12)) & i_instr(12) & i_instr(6 downto 2) &
                                      5B"00000" & 3B"000" & i_instr(11 downto 7) & OPCODE_OP_IMM;
                    when 3B"011" =>
                        -- c.lui -> lui rd, imm
                        -- c.lui hints are translated into a lui hint)
                        comp_instr <= (31 downto 17 => i_instr(12)) & i_instr(6 downto 2) & 
                                      i_instr(11 downto 7) & OPCODE_LUI;

                        if i_instr(11 downto 7) = 5x"02" then
                            -- c.addi16sp -> addi x2, x2, nzimm
                            comp_instr <= (31 downto 29 => i_instr(12)) & i_instr(4 downto 3) & 
                                          i_instr(5) & i_instr(2) & i_instr(6) & 4B"0000" & 5x"02" &
                                          3B"000" & 5x"02" & OPCODE_OP_IMM;
                        end if;
                    when 3B"100" =>
                        case i_instr(11 downto 10) is 
                            when 2B"00" | 2B"01" =>
                                -- 00: c.srli -> srli rd, rd, shamt
                                -- 01: c.srai -> srai rd, rd, shamt
                                -- (c.srli/c.srai hints are translated into a srli/srai hint)
                                comp_instr <= '0' & i_instr(10) & 5B"00000" & i_instr(6 downto 2) &
                                              2B"01" & i_instr(9 downto 7) & 3B"101" & 2B"01" &
                                              i_instr(9 downto 7) & OPCODE_OP_IMM;
                            when 2B"10" =>
                                -- c.andi -> andi rd, rd, imm
                                comp_instr <= (31 downto 26 => i_instr(12)) & i_instr(12) & 
                                              i_instr(6 downto 2) & 2B"01" & i_instr(9 downto 7) &
                                              3B"111" & 2B"01" & i_instr(9 downto 7) & OPCODE_OP_IMM;
                            when 2B"11" =>
                                case i_instr(6 downto 5) is 
                                    when 2B"00" =>
                                        -- c.sub -> sub rd', rd', rs2'
                                        comp_instr <= 2B"01" & 5B"0000" & 2B"01" & i_instr(4 downto 2) &
                                                      2B"01" & i_instr(9 downto 7) & 3B"000" & 2B"01" &
                                                      i_instr(9 downto 7) & OPCODE_OP;
                                    when 2B"01" =>
                                        -- c.xor -> xor rd', rd', rs2'
                                        comp_instr <= 7B"0000000" & 2B"01" & i_instr(4 downto 2) & 2B"01" &
                                                      i_instr(9 downto 7) & 3B"100" & 2B"01" &
                                                      i_instr(9 downto 7) & OPCODE_OP;
                                    when 2B"10" =>
                                        -- c.or  -> or  rd', rd', rs2'
                                        comp_instr <= 7B"0000000" & 2B"01" & i_instr(4 downto 2) & 2B"01" &
                                                      i_instr(9 downto 7) & 3B"110" & 2B"01" &
                                                      i_instr(9 downto 7) & OPCODE_OP;
                                    when 2B"11" =>
                                        -- c.and -> and rd', rd', rs2'
                                        comp_instr <= 7B"0000000" & 2B"01" & i_instr(4 downto 2) & 2B"01" &
                                                      i_instr(9 downto 7) & 3B"111" & 2B"01" &
                                                      i_instr(9 downto 7) & OPCODE_OP;
                                    when others => null;
                                end case;
                            when others => null;
                        end case;
                    when 3B"110" | 3B"111" =>
                        -- 0: c.beqz -> beq rs1', x0, imm
                        -- 1: c.bnez -> bne rs1', x0, imm
                        comp_instr <= (31 downto 28 => i_instr(12)) & i_instr(6 downto 5) & i_instr(2) &
                                      5B"00000" & 2B"01" & i_instr(9 downto 7) & 2B"00" & i_instr(13) &
                                      i_instr(11 downto 10) & i_instr(4 downto 3) & i_instr(12) & OPCODE_BRANCH;
                    
                    when others => null;
                end case;
            -- C2

            -- Register address checks for RV32E are performed in the regular instruction decoder.
            -- If this check fails, an illegal instruction exception is triggered and the controller
            -- writes the actual faulting instruction to mtval.
            when 2B"10" =>
                case i_instr(15 downto 14) is 
                    when 2B"00" =>
                        -- c.slli -> slli rd, rd, shamt
                        -- (c.slli hints are translated into a slli hint)
                        comp_instr <= 7B"0000000" & i_instr(6 downto 2) & i_instr(11 downto 7) & 3B"001" &
                                      i_instr(11 downto 7) & OPCODE_OP_IMM;
                    when 2B"01" =>
                        -- c.lwsp -> lw rd, imm(x2)
                        comp_instr <= 4B"0000" & i_instr(3 downto 2) & i_instr(12) & i_instr(6 downto 4) &
                                      2B"00" & 5x"02" & 3B"010" & i_instr(11 downto 7) & OPCODE_LOAD;
                    when 2B"10" =>
                        if i_instr(12) = '0' then
                            if i_instr(6 downto 2) /= 5B"00000" then
                                -- c.mv -> add rd/rs1, x0, rs2
                                -- (c.mv hints are translated into an add hint)
                                comp_instr <= 7B"0000000" & i_instr(6 downto 2) & 5B"00000" & 3B"000" &
                                              i_instr(11 downto 7) & OPCODE_OP;
                            else
                                -- c.jr -> jalr x0, rd/rs1, 0
                                comp_instr <= 12x"000" & i_instr(11 downto 7) & 3B"000" & 5B"00000" & 
                                              OPCODE_JALR;
                            end if;
                        else 
                            if i_instr(6 downto 2) /= 5B"00000" then
                                -- c.add -> add rd, rd, rs2
                                -- (c.add hints are translated into an add hint)
                                comp_instr <= 7x"00" & i_instr(6 downto 2) & i_instr(11 downto 7) &
                                              3B"000" & i_instr(11 downto 7) & OPCODE_OP;
                            else
                                if i_instr(11 downto 7) = 5B"00000" then
                                    -- c.ebreak -> ebreak
                                    comp_instr <= 32x"00_10_00_73";
                                else
                                    -- c.jalr -> jalr x1, rs1, 0
                                    comp_instr <= 12x"000" & i_instr(11 downto 7) & 3B"000" & 5B"00001" &
                                                  OPCODE_JALR;
                                end if;
                            end if;
                        end if;
                    when 2B"11" =>
                        -- c.swsp -> sw rs2, imm(x2)
                        comp_instr <= 4x"0" & i_instr(8 downto 7) & i_instr(12) & i_instr(6 downto 2) & 
                                      5x"02" & 3B"010" & i_instr(11 downto 9) & 2B"00" & OPCODE_STORE;
                
                    when others => null;
                end case;
            
            -- Incoming instruction is not compressed.
            when 2B"11" => illegal_instr <= '1';
            when others => null;
        end case;
    end process;
end architecture rtl;
