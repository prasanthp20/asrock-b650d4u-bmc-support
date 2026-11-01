# Staged monitoring translation

No build, image deployment or hardware access performed.

Files:
- Board monitoring DTSI: disabled combined PWM/tach node, disabled IIO-hwmon
  bridge with ADC0 0-7 then ADC1 0-7 (preserves aggregate index 0-15), and
  disabled NCT6796/SBTSI I2C clients.
- Kernel fragment: G6 tach/PWM, ADC, IIO-hwmon, SBTSI and NCT6775-I2C drivers.
- b650d4u-monitoring.json: candidate REPLACEMENT for b650d4u.json, not a second
  simultaneously installed board config. Includes FRU-backed identity, 12 ADC
  rails, and CPU Temperature SBTSI. Local Entity Manager schema check passes.

These monitoring files remain unselected by the recipes. Existing identity
JSON remains selected. No overlapping board probes are installed.

ADC ScaleFactor = 1 / recovered software gain because ADCSensor divides
hwmon millivolts by 1000 and by ScaleFactor. The JSON Index assumes the staged
IIO-hwmon bridge ordering. No IPMI raw-unit multiplier or vendor literal +1
is added to already calibrated IIO output. Battery and unused inputs are not
published. No thresholds or nominal rails are guessed.

Activation requirements:
- Confirm running vendor profile and resolve battery/raw discrepancy.
- Confirm ADC reference source (internal/external) and pin selections, then
  enable ADC engines/bridge together. Current bridge description alone does
  not create voltage measurements.
- Review I2C1/2 ownership, pinmux and profile, enable buses and client nodes
  deliberately. NCT6796 bank accesses must not race vendor/other raw readers.
- SBTSI is supported by HwmonTemp; verify chip protocol and reading on target.
- NCT6796 backend and Entity Manager schema patches are now selected by board
  recipe appends. Staged JSON exposes the first six channels under neutral names.
  Actual labels must determine final board-specific names; do not impersonate NCT6779.
- Validate cooling behavior before enabling shared PWM/tach controller.
- Choose persistent recipe inclusion and switch board JSON once ready for
  the consolidated experimental image. Preserve the identity configuration.

Not included: DDR5 GPIO/register sequence, PSU telemetry placeholders, FSC_INDEX,
voltage thresholds, or unverified physical fan header names.

## NCT6796 publication update

The source patches add NCT6796 -> nct6796 in HwmonTemp and allow NCT6796
in the temperature schema. Both apply cleanly to the local recipe sources.
Staged JSON validates against the patched local schema. No build performed.

The first six temperature indices have neutral diagnostic names, not guessed
physical names. Missing files are skipped by the backend; additional dynamic
channels may exist and must be examined. No thresholds are assigned.

After board activation, read name, temp*_label and temp*_input from the NCT
hwmon directory. Map CPUTIN to TEMP_FCH, SYSTIN to TEMP_MB, and AUXTIN5 to
TEMP_CARD_SIDE ONLY when the actual labels/register source mapping confirms
them. If a source is absent, investigate dynamic label/channel configuration
rather than renaming a convenient index. Compare to vendor readings under
similar host/power/thermal conditions; previous samples are not a simultaneous
accuracy reference. Final index-to-board-name mapping and hardware tests remain
pending operator capture.

## NCT6796 lifecycle integration (2026-10-24)

The installed b650d4u.json exposes NCT6796 on bus 1/address 0x2d with
PowerState "On" and six neutral channel names. The kernel driver fragment,
I2C1 controller and I2C2 pin group remain enabled. The monitoring DTSI no
longer declares superio@2d: HwmonTempSensor is the sole client lifecycle owner.

Board evidence before this change: a static client failed binding while the
host was off (ENXIO); manual binding after power-on succeeded. Restarting
hwmontempsensor then published six numeric D-Bus readings. Its attempted
new_device creation had collided with the static client (EBUSY).

Existing dbus-sensors DeviceMgmt gates instantiation with readingStateGood(),
and HwmonTempMain recreates sensors on power-state activation. Sensor
deactivation releases its shared I2CDevice; the last owner removes the dynamic
client. No board-specific bind/restart service or kernel retry patch is added.

This source integration still requires a new image and target validation:
boot with host off, request host on, and verify automatic driver binding and
six numeric D-Bus values without manual intervention. Then perform a normal
host shutdown/on cycle and a BMC restart with host already on. Check that
unavailable sensors are not reported as current measurements while off and
that no duplicate-client errors recur. If probing still occurs before the
chip becomes accessible, capture the failure; a generic retry policy needs
separate investigation rather than assuming this change handles that case.

## Failed-probe recovery draft (2026-10-24)

The e8a66e2 image removed the static client successfully. Initial dynamic
discovery failed around boot-relative 234.9 s and cleaned up the client;
restarting hwmontempsensor around 415.6 s succeeded without manual binding
and published six temperature objects. These observations establish recovery
on a later attempt, not the precise chip readiness time or cause.

Selected dbus-sensors patch 0002 adds a bounded discovery retry path to
HwmonTempMain. Startup, power activation and configuration refresh start a
window of up to 24 additional attempts at five-second intervals. Only
configured I2C devices whose reading state is eligible and whose expected
sysfs interface is missing trigger retries. Activation-only scans retain
already-active sensor objects. Existing DeviceMgmt cleans up unsuccessful
dynamic clients. A power-off notification cancels the timer; generation
checks discard stale asynchronous discovery replies before device creation.

The interval and approximately two-minute retry window are initial policy,
not hardware requirements. Failure after exhaustion is logged; a subsequent
power activation, configuration refresh or service restart starts a new
window. This is a local generic-backend draft, not maintainer-approved code.
Patch application and formatting were checked; compilation and target tests
remain pending. Validate late readiness, permanent failure/limit exhaustion,
power-off during retries, repeated power cycles and BMC restart with host on.

## ADC reference confirmation and activation (2026-10-24)

Operator read vendor ADC0 0x1e6e9000 and ADC1 0x1e6e9100 control
registers as 0x00ff010f. Driver reference bits [7:6] = 0 select internal
2.5 V; channel enable bits [23:16] = 0xff select all eight channels per
engine. This resolves the earlier internal/external reference ambiguity.
Custom firmware devmem failed opening /dev/mem and supplied no ADC values.

The monitoring DTSI now enables both ADC engines with the supported
aspeed,int-vref-microvolt = <2500000> property, ADC0-15 pin groups, and
the ordered sixteen-channel IIO-hwmon bridge. No raw register writes or
vendor vref property are introduced. Battery mode remains unset.

The installed b650d4u.json now adds twelve ADC rail entries using recovered
inverse software gains and retains NCT6796. Only 3VSB/5VSB use Always;
other rails conservatively use On pending off-state validation. Index 12
(battery) and unused indices 9-11 have no D-Bus exposes. Their raw bridge
channels remain present to preserve indices. No speculative thresholds,
SBTSI activation, or fan-control enablement is included.

Entity Manager schema validation and static index/pin-label checks passed.
No build, DT schema check or target test was performed. Next target captures:
both IIO names/scale/offset/raw values, IIO-hwmon in*_input ordering, ADC
D-Bus readings, and comparison with vendor IPMI under comparable host states.
Recovered gains are candidates until actual rail readings are validated.

## Fan tachometer discovery preparation (2026-10-25)

Enabled the existing AST2600 PWM/tach controller node with tach0 pinmux and
its single fan-0/tach-ch=0 child. The installed JSON now includes AspeedFan
Index 0, neutral Name "Fan Tach 0", PowerState "On". No Connector/PWM
configuration or thresholds are added. FanSensor is already selected by the
base dbus-sensors recipe. Existing backend recognizes the controller's
compatible. The kernel driver assumes two pulses per revolution, matching
previously captured vendor tach configuration.

This enables RPM discovery, not a complete cooling policy. The controller
registers a PWM provider and manages a shared reset, so inspect fan operation
on first boot; no assertion of electrically unchanged PWM behavior is made.
Do not unbind this controller as a harmless read-only operation: removal
asserts its reset. Physical header association remains unknown. Confirm the
connected fan cable terminates at the expected motherboard header before
renaming to CPU Fan. The internal PSU fan is not assumed monitorable.

Entity Manager schema and whitespace checks passed. No build, flash or target
test was run. Target completion: fan1_input gives plausible RPM, fan daemon
publishes Fan_Tach_0, web UI shows RPM, normal cooling persists, and readings
become unavailable/recover correctly across host power transitions. Compare
with vendor FAN1_1 in similar conditions; previous samples are not calibration.
This source integration is local and not yet prepared for upstream submission.

## Vendor FAN1 mapping review (2026-10-25)

Operator confirmed the second controlled capture followed restoration to
Optimal mode, not a 90% manual test. FAN1 Manual 100%: pwm-fan0=255,
tach0=2604 RPM. FAN1 Optimal: pwm-fan0=141, tach0=1954 RPM. PWM1-6
remained 141 and PWM7 remained 76. FAN1 is restored to Optimal and its
stored manual setting is 30%. This supports the vendor FAN1/PWM0/tach0
relationship. No 90% result or exact physical header label is claimed.

Renamed the installed tach sensor from Fan Tach 0 to FAN1, matching the
verified vendor logical identity. Expected D-Bus path is now
/xyz/openbmc_project/sensors/fan_tach/FAN1. Physical CPU-header labeling is
still separate. Prior vendor IPMI readings (1600) and kernel readings (1921)
differed; sensor scaling must not be adjusted without resolving conversion,
sampling and cache behavior.

Reviewed driver/binding/backend compatibility: tach-ch is an 8-bit channel
array, tach0 pin group exists, only channel 0 is made visible, AspeedFan
Index 0 matches fan1_input, and the existing kernel uses two pulses per
revolution, matching recovered vendor setup. No Connector means FanSensor
creates no PWM control object for this entry. The selected kernel driver
registers a PWM provider but does not apply a PWM duty in its tach probe;
it deasserts a shared reset and asserts it on removal/failure cleanup.
Do not claim this constitutes a validated startup or failsafe cooling policy.

The operator's last custom image still had the controller disabled and no
AspeedFan entry, so no custom fan-RPM validation has occurred yet. Before
flashing the next image, verify the generated DTS has controller okay and
tach0 pinctrl, and the generated rootfs JSON has FAN1/AspeedFan/Index 0.
After boot observe fan rotation, kernel RPM, D-Bus FAN1 and UI, then test
host-off/on availability. No broad driver change is needed for discovery.
