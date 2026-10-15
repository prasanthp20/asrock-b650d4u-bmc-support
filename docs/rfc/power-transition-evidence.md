# B650D4U AST2600 power-transition evidence

## Hardware

- Board: ASRock Rack B650D4U
- BMC: ASPEED AST2600
- GPIOP2 / GPIO122: physical power-button input
- GPIOP3 / GPIO123: host power-control output
- GPIOF7 / GPIO47: PSU power-good input

## Vendor behavior

- SCU4BC idle: 0x0e000000
- SCU4BC transition: 0x02000000
- SCU4BC restored: 0x0e000000
- THRU1 and GPIO123 are mutually exclusive.

## OpenBMC validation

- SCU4BC idle write/readback: 0x0e000000
- Temporary GPIO123 transition: successful
- Host power-on: successful
- Graceful host power-off: successful
- Power-good assertion/deassertion: successful

## Upstream question

What existing kernel subsystem should own the temporary transition between
AST2600 THRU1 passthrough and GPIO123 software control?
