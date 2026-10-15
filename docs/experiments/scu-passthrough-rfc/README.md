# B650D4U SCU passthrough experiment

This experiment enabled the AST2600 GPIOP passthrough selector around the
host power pulse. It was validated on real B650D4U hardware and allowed
host power control through OpenBMC.

The approach was submitted as an RFC and rejected during review because
the selector should be handled by the existing GPIO and pinctrl framework.
The files are retained as historical validation evidence and are not part
of the active OpenBMC build.
