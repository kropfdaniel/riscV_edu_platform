# SERV

SERV is a small, bit-serial RISC-V CPU core created by Olof Kindgren. This directory contains the
Verilog source and a VHDL translation adapted for this project.

## Project sources

- [`../verilog/`](../verilog/) — Verilog implementation, based on the upstream source and subject
  to project-specific modifications.
- [`../vhdl/`](../vhdl/) — VHDL translation of SERV, with project-specific modifications.

## Upstream project and documentation

- [SERV GitHub repository](https://github.com/olofk/serv)
- [Official SERV user manual](https://serv.readthedocs.io/en/latest/)

The local Verilog source is based on upstream commit
[`f200eb2ed7b69ac1c6b8eddd47654522aeee5ce8`](https://github.com/olofk/serv/commit/f200eb2ed7b69ac1c6b8eddd47654522aeee5ce8).
See [`../verilog/UPSTREAM_VERSION.md`](../verilog/UPSTREAM_VERSION.md) for the source snapshot
details. Local changes may mean the project sources differ from that upstream revision. The
upstream manual describes SERV generally; check this project's sources for differences in local
behavior and interfaces.

## Licenses

- The upstream Verilog source is licensed under the **ISC License**. See
  [`../verilog/LICENSE`](../verilog/LICENSE).
- The VHDL translation is licensed under the **MIT License** and is a derivative work based on the
  ISC-licensed SERV core. See [`../vhdl/LICENSE`](../vhdl/LICENSE).

Keep the applicable copyright and license notices with the source when using or redistributing it.

## Local modifications

Record project-specific changes here so it is clear how the local sources differ from upstream.

### VHDL

- Removed the `RESET_STRATEGY` generic and its propagation through the VHDL hierarchy.
  - Reset behavior is unconditional when reset is asserted; affected control, CSR, register-file
    interface, and state logic no longer support the upstream `"NONE"` reset strategy.
  - The program counter is set to `reset_vec` when reset is asserted.
- Removed the `DEBUG` generic and its propagation through the VHDL hierarchy.

### Verilog

- Included servile_arbiter with changes made to signal names
- Changed `RESET_PC` parameter to `reset_vec` input signal
