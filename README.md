# ASRock Rack B650D4U BMC Support

Engineering documentation, source references, validation evidence and
upstream submission records for Linux and U-Boot support on the
ASRock Rack B650D4U AST2600 BMC.

This repository is an evidence and documentation repository. The
canonical source code remains in the corresponding Linux and U-Boot
upstream repositories.

## Hardware overview

| Component | Description |
|---|---|
| Motherboard | ASRock Rack B650D4U |
| BMC SoC | ASPEED AST2600 |
| BMC DRAM | 512 MiB capacity |
| Usable BMC DRAM | 440 MiB with VGA and ECC reservations |
| SPI NOR | Winbond W25Q512JV, 64 MiB |
| Debug console | UART5, 115200 8N1 |
| MAC0 | Realtek RTL8211F, RGMII |
| MAC2 | RMII/NCSI |

## Repository structure

| Directory | Purpose |
|---|---|
| `docs/` | Engineering documentation and validation procedures |
| `evidence/` | Hardware, UART, network and QEMU test evidence |
| `manifests/` | Checksums and test-environment information |
| `patches/linux/` | Linux patch snapshots |
| `patches/u-boot/` | Exact U-Boot patch emails submitted upstream |
| `reference/linux/` | Linux device-tree reference snapshots |
| `reference/u-boot/` | U-Boot DTS and defconfig reference snapshots |
| `scripts/` | Reproducible evidence-capture and validation tools |

## U-Boot upstream status

RFC v1 was submitted to the U-Boot mailing list with the subject:

[RFC PATCH v1 0/1] arm: aspeed: Add ASRock Rack B650D4U BMC support

Source commit:

ace65ad310d18520fdf64f705812b1abc3d5ebbf

The exact submitted cover letter and patch are preserved under:

patches/u-boot/rfc-v1/

## U-Boot runtime validation

Main U-Boot was loaded into RAM from the vendor U-Boot using YMODEM.

| Property | Value |
|---|---|
| Load address | `0x83000000` |
| Binary size | 487552 bytes (`0x77080`) |
| CRC32 | `2d4beae2` |
| SHA256 | `8e506777667d91c1b9fdc8f6dafec798cdc6ae8838a1d0981bdf5a69a5c2e5c6` |
| SPI flash modified | No |

### Validation results

| Test | Result |
|---|---|
| `b650d4u_defconfig` build | PASS |
| YMODEM transfer | PASS |
| Main U-Boot RAM execution | PASS |
| UART5 input and output | PASS |
| Board model detection | PASS |
| DRAM reporting | PASS |
| SPI NOR detection | PASS |
| MAC0 link detection | PASS |
| MAC0 ARP and ICMP traffic | PASS |
| MAC2/NCSI end-to-end traffic | NOT VALIDATED |
| SPL execution from reset | NOT VALIDATED |
| Cold DRAM initialization | NOT VALIDATED |

## Validation limitation

The tested main U-Boot binary was started from RAM after the vendor
U-Boot had already initialized the AST2600 and DRAM.

Therefore, this test proves main U-Boot runtime operation, but it does
not prove:

- SPL execution from reset
- cold DRAM initialization
- complete boot from SPI flash
- complete MAC2/NCSI network operation

No upstream U-Boot image was written to the BMC SPI flash during this
validation.

## Integrity verification

Checksums for the published files are stored in:

manifests/SHA256SUMS

Verify them with:

sha256sum -c manifests/SHA256SUMS

## Safety and redistribution


This repository does not distribute:

- complete vendor firmware images
- SPI flash dumps
- extracted proprietary root filesystems
- passwords, private keys or authentication tokens
- copyrighted vendor documentation

Reference files and logs are included only for engineering,
reproducibility and upstream-development purposes.
