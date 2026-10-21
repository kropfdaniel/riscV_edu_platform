----------------------------------------------------------------------------------
-- File: serv_mstate.vhdl
-- Author: Daniel Kropf
-- License: MIT License
-- 
-- Description: SERV module for handling internal state during instructions
-- Note:        This file is a VHDL translation of the original Verilog module.
--              Original architecture and Verilog implementation by:
--              Copyright (c) 2019 Olof Kindgren
--              Original License: ISC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serv_state is
    generic(
        RESET_STRATEGY : string := "MINI";
        WITH_CSR       : boolean := true;
        ALIGN          : boolean := false;
        MDU            : boolean := false;
        W              : integer := 1
    );
    port(
        i_clk               : in  std_logic;
        i_rst               : in  std_logic;
        -- State
        i_new_irq           : in  std_logic;
        i_alu_cmp           : in  std_logic;
        o_init              : out std_logic;
        o_cnt_en            : out std_logic;
        o_cnt0to3           : out std_logic;
        o_cnt12to31         : out std_logic;
        o_cnt0              : out std_logic;
        o_cnt1              : out std_logic;
        o_cnt2              : out std_logic;
        o_cnt3              : out std_logic;
        o_cnt7              : out std_logic;
        o_cnt11             : out std_logic;
        o_cnt12             : out std_logic;
        o_cnt_done          : out std_logic;
        o_bufreg_en         : out std_logic;
        o_ctrl_pc_en        : out std_logic;
        o_ctrl_jump         : out std_logic;
        o_ctrl_trap         : out std_logic;
        i_ctrl_misalign     : in  std_logic;
        i_sh_done           : in  std_logic;
        o_mem_bytecnt       : out std_logic_vector(1 downto 0);
        i_mem_misalign      : in  std_logic;
        -- Control
        i_bne_or_bge        : in  std_logic;
        i_cond_branch       : in  std_logic;
        i_dbus_en           : in  std_logic;
        i_two_stage_op      : in  std_logic;
        i_branch_op         : in  std_logic;
        i_shift_op          : in  std_logic;
        i_sh_right          : in  std_logic;
        i_alu_rd_sel1       : in  std_logic;
        i_rd_alu_en         : in  std_logic;
        i_e_op              : in  std_logic;
        i_rd_op             : in  std_logic;
        -- MDU
        i_mdu_op            : in  std_logic;
        o_mdu_valid         : out std_logic;
        -- Extension
        i_mdu_ready         : in  std_logic;
        -- External
        o_dbus_cyc          : out std_logic;
        i_dbus_ack          : in  std_logic;
        o_ibus_cyc          : out std_logic;
        i_ibus_ack          : in  std_logic;
        -- RF Interface
        o_rf_rreq           : out std_logic;
        o_rf_wreq           : out std_logic;
        i_rf_ready          : in  std_logic;
        o_rf_rd_en          : out std_logic
    );
end entity serv_state;

architecture rtl of serv_state is
    signal init_done, misalign_trap_sync, ibus_cyc, take_branch,
    last_init, trap_pending : std_logic;
    signal o_cnt : std_logic_vector(4 downto 2);
    signal cnt_r : std_logic_vector(3 downto 0);   
    
    signal mdu_rf_wreq, shift_rf_wreq : std_logic;
begin
    assert (W = 1 or W = 4)
        report "serv_state PARAMETER ERROR: W must be exactly 1 or 4."
        severity failure;

    -- Update PC in RUN or TRAP states
    o_ctrl_pc_en <= o_cnt_en and not o_init;

    o_mem_bytecnt <= o_cnt(4 downto 3);

    o_cnt0to3   <= '1' when (o_cnt(4 downto 2) = 3D"0")                   else '0';
    o_cnt12to31 <= '1' when ( (??o_cnt(4)) or o_cnt(3 downto 2) = 2B"11") else '0';
    o_cnt0      <= '1' when (o_cnt(4 downto 2) = 3D"0") and (??cnt_r(0))  else '0';
    o_cnt1      <= '1' when (o_cnt(4 downto 2) = 3D"0") and (??cnt_r(1))  else '0';
    o_cnt2      <= '1' when (o_cnt(4 downto 2) = 3D"0") and (??cnt_r(2))  else '0';
    o_cnt3      <= '1' when (o_cnt(4 downto 2) = 3D"0") and (??cnt_r(3))  else '0';
    o_cnt7      <= '1' when (o_cnt(4 downto 2) = 3D"1") and (??cnt_r(3))  else '0';
    o_cnt11     <= '1' when (o_cnt(4 downto 2) = 3D"2") and (??cnt_r(3))  else '0';
    o_cnt12     <= '1' when (o_cnt(4 downto 2) = 3D"3") and (??cnt_r(0))  else '0';

    -- Take branch for jump or branch instructions (opcode == 1x0xx) if
    -- a) It's an unconditional branch (opcode[0] == 1)
    -- b) It's a conditional branch (opcode[0] == 0) of type beq,blt,bltu (funct3[0] == 0) and ALU compare is true
    -- c) It's a conditional branch (opcode[0] == 0) of type bne,bge,bgeu (funct3[0] == 1) and ALU compare is false
    -- Only valid during the last cycle of INIT, when the branch condition has
    -- been calculated.
    take_branch <= i_branch_op and (not i_cond_branch or (i_alu_cmp xor i_bne_or_bge));

    last_init <= o_cnt_done and o_init;

    -- valid signal for mdu
    o_mdu_valid <= '1' when MDU and (??(not o_cnt_en and init_done and i_mdu_op)) else '0';
    
    -- trap_pending is only guaranteed to have correct value during the
    -- last cycle of the init stage
    trap_pending <= '1' when WITH_CSR and ( ((??take_branch) and (??i_ctrl_misalign) and not ALIGN) or 
                                            ((??i_dbus_en) and (??i_mem_misalign))) else '0';
    
    -- Prepare RF for writes when everything is ready to enter stage two
    --  and the first stage didn't cause a misalign exception
    -- Left shifts, SLT & Branch ops. First cycle after init
    -- Right shift. o_sh_done
    -- Mem ops. i_dbus_ack
    -- MDU ops. i_mdu_ready
    mdu_rf_wreq <= i_mdu_ready when MDU else '0';
    shift_rf_wreq <= i_sh_done and (last_init or (not o_cnt_en and init_done)) when (??i_sh_right) else 
                     last_init;
    o_rf_wreq <= (i_shift_op and shift_rf_wreq) or 
                 i_dbus_ack or 
                 mdu_rf_wreq or 
                 (i_branch_op and (last_init and not trap_pending)) or 
                 (i_rd_alu_en and i_alu_rd_sel1 and last_init);

    o_dbus_cyc <= not o_cnt_en and init_done and i_dbus_en and not i_mem_misalign;

    -- Prepare RF for reads when a new instruction is fetched
    -- or when stage one caused an exception (rreq implies a write request too)
    o_rf_rreq <= i_ibus_ack or (trap_pending and last_init);

    o_rf_rd_en <= i_rd_op and not o_init;

    --bufreg is used during mem, branch, and shift operations
    --
    --mem : bufreg is used for dbus address. Shift in data during phase 1.
    --      Shift out during phase 2 if there was a misalignment exception.
    --
    --branch : Shift in during phase 1. Shift out during phase 2
    --
    --shift : Shift in during phase 1. Continue shifting between phases (except
    --        for the first cycle after init). Shift out during phase 2

    o_bufreg_en <= (o_cnt_en and (o_init or ((o_ctrl_trap or i_branch_op) and i_two_stage_op))) or 
                   (i_shift_op and init_done and (i_sh_right or i_sh_done));

    o_ibus_cyc <= ibus_cyc and not i_rst;

    o_init <= i_two_stage_op and not i_new_irq and not init_done;

    o_cnt_done <= '1' when (o_cnt(4 downto 2) = 3B"111") and (??cnt_r(3)) else '0';

    process (i_clk)
    begin
        if rising_edge(i_clk) then 
            -- ibus_cyc changes on three conditions.
            -- 1. i_rst is asserted. Together with the async gating above, o_ibus_cyc
            --    will be asserted as soon as the reset is released. This is how the
            --    first instruction is fetched
            -- 2. o_cnt_done and o_ctrl_pc_en are asserted. This means that SERV just
            --    finished updating the PC, is done with the current instruction and
            --    o_ibus_cyc gets asserted to fetch a new instruction
            -- 3. When i_ibus_ack, a new instruction is fetched and o_ibus_cyc gets
            --    deasserted to finish the transaction
            if i_ibus_ack or o_cnt_done or i_rst then
                ibus_cyc <= o_ctrl_pc_en or i_rst;
            end if;

            if o_cnt_done then
                init_done <= o_init and not init_done;
                o_ctrl_jump <= o_init and take_branch;
            end if;

            if (??i_rst) and RESET_STRATEGY /= "NONE" then
                init_done <= '0';
                o_ctrl_jump <= '0';
            end if;
        end if;
    end process;

    -- Because SERV is 32-bit bit-serial we need a counter than can count 0-31
    -- to keep track of which bit we are currently processing. o_cnt and cnt_r
    -- are used together to create such a counter.
    -- The top three bits (o_cnt) are implemented as a normal counter, but
    -- instead of the two LSB, cnt_r is a 4-bit shift register which loops 0-3
    -- When cnt_r[3] is 1, o_cnt will be increased.
    -- 
    -- The counting starts when the core is idle and the i_rf_ready signal
    -- comes in from the RF module by shifting in the i_rf_ready bit as LSB of
    -- the shift register. Counting is stopped by using o_cnt_done to block the
    -- bit that was supposed to be shifted into bit 0 of cnt_r.
    -- 
    -- There are two benefit of doing the counter this way
    -- 1. We only need to check four bits instead of five when we want to check
    -- if the counter is at a certain value. For 4-LUT architectures this means
    -- we only need one LUT instead of two for each comparison.
    -- 2. We don't need a separate enable signal to turn on and off the counter
    -- between stages, which saves an extra FF and a unique control signal. We
    -- just need to check if cnt_r is not zero to see if the counter is
    -- currently running
    gen_cnt_w_eq_1 : if W=1 generate
        signal cnt_lsb : std_logic_vector(3 downto 0);
    begin
        process(i_clk) 
        begin
            if rising_edge(i_clk) then 
                o_cnt <= std_logic_vector( unsigned(o_cnt) +
                                        unsigned'("00" & cnt_r(3)) ); 
                cnt_lsb <= cnt_lsb(2 downto 0) & ( (cnt_lsb(3) and not o_cnt_done) or i_rf_ready );
                if (??i_rst) and RESET_STRATEGY /= "NONE" then
                    o_cnt <= 3D"0";
                    cnt_lsb <= 4B"0000";
                end if;
            end if;
        end process;
        cnt_r <= cnt_lsb;
        o_cnt_en <= (or cnt_lsb);
    end generate gen_cnt_w_eq_1;

    gen_cnt_w_eq_4 : if W=4 generate
        signal cnt_en : std_logic;
    begin
        process(i_clk)
        begin
            if rising_edge(i_clk) then 
                if i_rf_ready then
                    cnt_en <= '1';
                elsif o_cnt_done then
                    cnt_en <= '0';
                end if;
                o_cnt <= std_logic_vector( unsigned(o_cnt) +
                                           unsigned'("00" & cnt_en) ); 
                if (??i_rst) and RESET_STRATEGY /= "NONE" then
                    o_cnt <= 3D"0";
                    cnt_en <= '0';
                end if;
            end if;
        end process;
        cnt_r <= 4B"1111";
        o_cnt_en <= cnt_en;
    end generate gen_cnt_w_eq_4;

    o_ctrl_trap <= '1' when WITH_CSR and (??(i_e_op or i_new_irq or misalign_trap_sync)) else '0';
    
    gen_csr : if WITH_CSR generate
        signal misalign_trap_sync_r : std_logic;
    begin
        process(i_clk)
        begin
            if rising_edge(i_clk) and (??(i_ibus_ack or o_cnt_done or i_rst)) then
                misalign_trap_sync_r <= not(i_ibus_ack or i_rst) and 
                                        ((trap_pending and o_init) or misalign_trap_sync_r);
            end if;
        end process;
        misalign_trap_sync <= misalign_trap_sync_r;
    end generate gen_csr;
    
    gen_no_csr : if not WITH_CSR generate
        misalign_trap_sync <= '0';
    end generate gen_no_csr;
end architecture rtl;       