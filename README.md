# ASRock Rack B650D4U OpenBMC Support

## Supported hardware

This project supports the following platform:

- **Baseboard:** ASRock Rack B650D4U
- **BMC:** ASPEED AST2600
- **Tested host processor:** AMD Ryzen 5 7500F (AM5)
- **Tested board revision:** not recorded; confirm the revision printed on the board before reproducing the validation

The BMC firmware was built and tested on a physical B650D4U system. Host power control uses the board-specific GPIO and AST2600 SCU passthrough behavior implemented in this layer.
