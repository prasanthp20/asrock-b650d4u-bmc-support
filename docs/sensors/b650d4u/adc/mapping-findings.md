# Static vendor mapping findings

Sources are the locally extracted B650D4U 7.02.00 libraries. Their default
platform.conf selects ast2600evb_ami; the running platform selection still
needs confirmation. No vendor executable code is redistributed here.

Voltage sensor wrappers named dev_asrrvoltagev06_<number>_0_32_read_device
call specific dev_asrr_ast2600_v03_avin_<channel>_read functions. libadc's
get_adc_val helper selects engine 0 for channels 0-7, engine 1 for 8-15,
subtracting 8 for the latter. See vendor-adc-call-mapping.csv.

Temperature call relationships:
- SDR 0x50 TEMP_FCH -> dev_nct6796d_cputin_read.
- SDR 0x51 TEMP_MB -> dev_nct6796d_systin_read.
- SDR 0x53 TEMP_CARD_SIDE -> dev_nct6796d_auxtin5_read.
- SDR 0x2a TEMP_CPU -> AMD CPU reader -> vendor I2C bus-2 read helper.
- SDR 0x2b FSC_INDEX uses a second AMD CPU reader; do not infer its meaning
  solely from similar code.
- DDR5 SDR 0x32 -> chl1_dimm1 temperature routine. Logical DIMM numbering
  must come from the sensor wrapper, not assumed from the B1 display name.

NCT6796D helpers use vendor bus 1 and address-field byte 0x5a. It is NOT yet
established whether that byte uses an 8-bit address convention (0x2d 7-bit)
or a direct 7-bit address. Do not instantiate a device at either address yet.
The routines change a bank selector before reading; generic direct reads
would need coordination with the active vendor reader.

Next static work: recover address convention from the shared I2C HAL;
recover ADC arithmetic/divider coefficients from the voltage wrappers;
identify AMD protocol/register and DDR5 mux/address handling. Driver support
must then be checked against these transports. No active DT configuration
has been changed based only on a symbol name.

## Further static recovery

The shared HAL shifts the address field right by one at 0x14a0/0x150c
(read paths) and 0x158c (write path). The NCT path therefore targets 0x2d
on vendor bus 1. The AMD path targets 0x4c on vendor bus 2, register 0x01.
The routine names identify paths, not a validated target-driver binding.

Voltage wrappers add a literal 1 to the raw sample, multiply by 2.5 and
1/1024, apply the recovered gain numerator/denominator, divide by the
SDR's raw-unit step and convert to integer. Soft-float helper calls at
0x10f380 and 0x10f5ec are interpreted as multiplication and division.
The exported factors are effective software gains, not independently
measured physical resistor values. See vendor-adc-scaling.csv.

Do not add the vendor literal +1 to an already calibrated IIO voltage: the
target driver reports its own offset/scale. Avoid double calibration.
Likewise do not apply an IPMI raw-unit step as an ADC divider.

Discrepancy to resolve: the earlier ADC1 local channel 4 sample was 2.
The static default profile maps battery there with gain 3, inconsistent
with the separately captured ~3.02 V battery reading. Captures are not
simultaneous; profile selection, battery measurement behavior and dynamic
configuration remain possibilities. Do not activate this battery mapping
until explained. Other channels must also be compared on the target.

DDR5 temperature access also changes GPIO routing and writes registers.
It is not just an ordinary continuously readable hwmon temperature device.
