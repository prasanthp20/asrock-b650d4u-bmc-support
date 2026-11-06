# Experiment 03: Aspeed pinctrl registration lifetime under KASAN

## Purpose and exact source

Validate controller teardown with the shared helper changed from `pinctrl_register()` to `devm_pinctrl_register()`. The controller must unregister before earlier devres allocations, including G6 callback data, are freed.

Base: Linux v7.4-rc1, `6628e7d4c6b25c8d18f1345e3a20d21829aae7e4`.
Tested source HEAD: `47bf7a9d72aeab67d960c291bbfd86450903cff5` (GPIOP handover candidate), plus the uncommitted change saved in `reproduce/lifecycle-fix.diff`. The running kernel therefore reports `-dirty`. This is a test snapshot, not an accepted upstream release.

## Results

- QEMU AST2600 EVB: one completed fixed-kernel unbind/rebind cycle; controller entries removed and restored; post-rebind pins read succeeded; no KASAN error observed in the supplied transcript.
- Physical ASRock Rack B650D4U, 2026-11-06 IST: one completed fixed-kernel unbind/rebind cycle. Both operations returned zero. The controller disappeared from debugfs and pinctrl-devices, returned on rebind, and its pins file could be read successfully. Watchdog remained active. The recorded error scan returned no matches.
- Generic KASAN initialization is recorded in both boot logs.

These results cover these specific cycles only. The unfixed control comparison has not been performed. Host power operation in this minimal environment, concurrent debugfs access during removal, probe-failure injection, and electrical continuity are not validated by this test.

## Evidence

`logs/` contains byte-for-byte copies of the original serial captures, including escape sequences, paste interleaving and unsuccessful setup attempts. Do not interpret echoed error-search patterns as actual kernel reports. Hardware capture includes the real unbind and rebind results. QEMU capture includes an initial skipped-unbind attempt before the successful cycle.

`reproduce/` contains the exact kernel config, lifetime diff, test DTS, init script, ramdisk FIT source and original binary checksums. Firmware binaries and third-party datasheets are not included. Private LAN IP addresses and local paths are present in the original logs; no credential-like text was found by the initial keyword scan. Review logs before publishing.

## Build and boot procedure

1. Check out the source HEAD above on v7.4-rc1 and apply lifecycle-fix.diff. Use kernel.config for an out-of-tree ARM build with arm-linux-gnueabihf GCC 14.2.0. Build zImage. The KASAN and G6 options must remain enabled after olddefconfig.
2. Prepare static ARM BusyBox 1.37.0 (Debian armhf 1:1.37.0-6+b9). Place it at /bin/busybox in a minimal initramfs. Provide sh, mount, cat, ls, grep, dmesg, sleep and readlink applet links. Install the saved init script as executable /init. Package using newc CPIO.
3. Preprocess the saved DTS against the same kernel aspeed-g6.dtsi and dt-bindings, then compile with dtc. RAM is 0x80000000..0x9effffff (496 MiB), excluding the upper VGA reservation. Duplicate LPC unit-address warnings were observed from the inherited SoC description.
4. QEMU used ast2600-evb with 1024 MiB, its EVB DTB, zImage and raw initramfs. Kernel command line: console=ttyS4,115200 rdinit=/init kasan_multi_shot.
5. Hardware used U-Boot 2026.04-b650d4u. With host shut down, interrupt boot and transfer zImage to 0x83000000, the saved board DTB to 0x85000000, and the FIT ramdisk to 0x88000000. Build ramdisk.itb with `mkimage -f ramdisk.its ramdisk.itb` alongside initramfs.cpio. Raw CPIO and legacy uInitrd were rejected by this U-Boot; FIT SHA-256 verification passed.
6. Set temporary bootargs to `console=ttyS4,115200n8 rdinit=/init kasan_multi_shot`, then `bootz 0x83000000 0x88000000 0x85000000`. No saveenv or SPI write was used. Confirm generic KASAN, running watchdog process, active watchdog0 (60 seconds), and bound pinctrl before removal.

## Lifecycle commands (test environment only)

```sh
driver=/sys/bus/platform/drivers/aspeed-g6-pinctrl
device=1e6e2000.syscon:pinctrl
debug=/sys/kernel/debug/pinctrl/1e6e2000.syscon:pinctrl-aspeed-g6-pinctrl
cat "$debug/pins" > /dev/null
echo "$device" > "$driver/unbind"
echo "unbind status=$?"
ls "$driver/"
ls /sys/kernel/debug/pinctrl/
cat /sys/kernel/debug/pinctrl/pinctrl-devices
echo "$device" > "$driver/bind"
echo "bind status=$?"
cat /sys/kernel/debug/pinctrl/pinctrl-devices
cat "$debug/pins" > /dev/null
echo "debugfs read status=$?"
cat /sys/class/watchdog/watchdog0/state
dmesg | grep -iE 'BUG: KASAN|use-after-free|Oops:|WARNING:|Kernel panic'
```

## Upstream reporting

Include a concise test statement in the patch email and link to this directory at an immutable GitHub commit for additional logs. The email patch must remain self-contained; a repository link does not replace the patch or validation summary.
