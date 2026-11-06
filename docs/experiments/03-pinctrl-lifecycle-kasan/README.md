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

## Hardware console transcript

The pasted transcript below includes failed ramdisk-format attempts followed by the successful FIT boot and one unbind/rebind cycle. The original capture is preserved separately in [the raw UART log](logs/hardware-fixed-uart.raw.log).

```text
=> tftpboot 0x84000000 uInitrd
ftgmac@1e660000: link up, 1000 Mbps full-duplex mac:1e:9c:2e:f5:d3:5c
Using ftgmac@1e660000 device
TFTP from server 192.168.0.119; our IP address is 192.168.0.112
Filename 'uInitrd'.
Load address: 0x84000000
Loading: #################################################################
	 ##############################
	 5.7 MiB/s
done
Bytes transferred = 1384512 (152040 hex)
=> iminfo 0x84000000
Unknown command 'iminfo' - try 'help'
=> setenv bootargs console=ttyS4,115200n8 rdinit=/init kasan_multi_shot
=> bootz 0x83000000 0x84000000 0x85000000
Kernel image @ 0x83000000 [ 0x000000 - 0x6911b0 ]
Wrong Ramdisk Image Format
Ramdisk image is corrupt or invalid
=> tftpboot 0x88000000 ramdisk.itb
ftgmac@1e660000: link up, 1000 Mbps full-duplex mac:1e:9c:2e:f5:d3:5c
Using ftgmac@1e660000 device
TFTP from server 192.168.0.119; our IP address is 192.168.0.112
Filename 'ramdisk.itb'.
Load address: 0x88000000
Loading: #################################################################
	 ##############################
	 5.7 MiB/s
done
Bytes transferred = 1385998 (15260e hex)
=> setenv bootargs console=ttyS4,115200n8 rdinit=/init kasan_multi_shot
=> bootz 0x83000000 0x88000000 0x85000000
Kernel image @ 0x83000000 [ 0x000000 - 0x6911b0 ]
## Loading ramdisk (any) from FIT Image at 88000000 ...
   Using 'conf' configuration
   Verifying Hash Integrity ... OK
   Trying 'ramdisk' ramdisk subimage
     Description:  Minimal lifecycle test userspace
     Type:         RAMDisk Image
     Compression:  uncompressed
     Data Start:   0x880000dc
     Data Size:    1384448 Bytes = 1.3 MiB
     Architecture: ARM
     OS:           Linux
     Load Address: unavailable
     Entry Point:  unavailable
     Hash algo:    sha256
     Hash value:   d97a1bb485a1ae165b220180527c4178f67d927e010279b143b376fd051e0eab
   Verifying Hash Integrity ... sha256+ OK
## Flattened Device Tree blob at 85000000
   Booting using the fdt blob at 0x85000000
Working FDT set to 85000000
   Loading Ramdisk to 9be0c000, end 9bf5e000 ... OK
   Loading Device Tree to 9bdff000, end 9be0b6fa ... OK
Working FDT set to 9bdff000

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0xf00
[    0.000000] Linux version 7.4.0-rc1-00001-g47bf7a9d72ae-dirty (prasanth@debian) (arm-linux-gnueabihf-gcc (Debian 14.2.0-19) 14.2.0, GNU ld (GNU Binutils for Debian) 2.44) #1 SMP Thu Nov  5 23:15:19 IST 2026
[    0.000000] CPU: ARMv7 Processor [410fc075] revision 5 (ARMv7), cr=10c5387d
[    0.000000] CPU: div instructions available: patching division code
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: ASRock Rack B650D4U lifecycle test
[    0.000000] Memory policy: Data cache writealloc
[    0.000000] cma: Reserved 16 MiB at 0x9e000000
[    0.000000] kasan: Mapping kernel virtual memory block: 80000000-9f000000 at shadow: 6f000000-72e00000
[    0.000000] kasan: Mapping kernel virtual memory block: 7fe00000-80000000 at shadow: 6efc0000-6f000000
[    0.000000] KernelAddressSanitizer initialized (generic)
[    0.000000] OF: reserved mem: Reserved memory: No reserved-memory node in the DT
[    0.000000] Zone ranges:
[    0.000000]   Normal   [mem 0x0000000080000000-0x000000009effffff]
[    0.000000]   HighMem  empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x000000009effffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x000000009effffff]
[    0.000000] percpu: Embedded 17 pages/cpu s47052 r0 d22580 u69632
[    0.000000] Kernel command line: console=ttyS4,115200n8 rdinit=/init kasan_multi_shot
[    0.000000] printk: log buffer data + meta data: 65536 + 204800 = 270336 bytes
[    0.000000] Dentry cache hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 32768 (order: 5, 131072 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 126976
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] stackdepot: allocating hash table via alloc_large_system_hash
[    0.000000] stackdepot hash table entries: 1048576 (order: 11, 8388608 bytes, linear)
[    0.000000] stackdepot: allocating space for 8192 stack pools via memblock
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=2, Nodes=1
[    0.000000] ftrace: allocating 35534 entries in 70 pages
[    0.000000] ftrace: allocated 70 pages with 3 groups
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu: 	RCU event tracing is enabled.
[    0.000000] 	Rude variant of Tasks RCU enabled.
[    0.000000] 	Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] RCU Tasks Rude: Setting shift to 1 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=2.
[    0.000000] NR_IRQS: 16, nr_irqs: 16, preallocated irqs: 16
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.000000] arch_timer: cp15 timer running at 1200.00MHz (sec-phys).
[    0.000000] clocksource: arch_sys_counter: mask: 0x1fffffffffffffff max_cycles: 0x114c1bbbeec, max_idle_ns: 440795229572 ns
[    0.000002] sched_clock: 61 bits at 1200MHz, resolution 0ns, wraps every 2199023255551ns
[    0.000031] Switching to timer-based delay loop, resolution 0ns
[    0.004030] Calibrating delay loop (skipped), value calculated using timer frequency.. 2400.00 BogoMIPS (lpj=12000000)
[    0.004085] CPU: Testing write buffer coherency: ok
[    0.004282] pid_max: default: 32768 minimum: 301
[    0.016454] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.016506] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.021214] VFS: Finished mounting rootfs on nullfs
[    0.038102] Setting up static identity map for 0x80100000 - 0x80100078
[    0.038881] rcu: Hierarchical SRCU implementation.
[    0.038905] rcu: 	Max phase no-delay instances is 1000.
[    0.040318] Timer migration: 1 hierarchy levels; 8 children per group; 1 crossnode level
[    0.046274] ASPEED AST2600 rev A3 (05030303)
[    0.047306] smp: Bringing up secondary CPUs ...
[    0.051055] smp: Brought up 1 node, 2 CPUs
[    0.051103] SMP: Total of 2 processors activated (4800.00 BogoMIPS).
[    0.051127] CPU: All CPU(s) started in SVC mode.
[    0.054012] Memory: 381548K/507904K available (16384K kernel code, 3773K rwdata, 6176K rodata, 1024K init, 321K bss, 106864K reserved, 16384K cma-reserved, 0K highmem)
[    0.058059] devtmpfs: initialized
[    0.255880] VFP support v0.3: implementor 41 architecture 2 part 30 variant 7 rev 5
[    0.259287] posixtimers hash table entries: 1024 (order: 1, 8192 bytes, linear)
[    0.259457] futex hash table entries: 512 (32768 bytes on 1 NUMA nodes, total 32 KiB, linear).
[    0.280783] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.284081] DMA: preallocated 256 KiB pool for atomic coherent allocations
[    0.298466] hw-breakpoint: found 5 (+1 reserved) breakpoint and 4 watchpoint registers.
[    0.298512] hw-breakpoint: maximum watchpoint size is 8 bytes.
[    0.312431] /ahb/interrupt-controller@40461000: Fixed dependency cycle(s) with /ahb/interrupt-controller@40461000
[    0.414058] SCSI subsystem initialized
[    0.416326] usbcore: registered new interface driver usbfs
[    0.416735] usbcore: registered new interface driver hub
[    0.417348] usbcore: registered new device driver usb
[    0.418770] mc: Linux media interface: v0.10
[    0.419156] videodev: Linux video capture interface: v2.00
[    0.419617] pps_core: LinuxPPS API ver. 1 registered
[    0.419635] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.419819] PTP clock support registered
[    0.420089] EDAC MC: Ver: 3.0.0
[    0.443536] mctp: management component transport protocol core
[    0.443570] NET: Registered PF_MCTP protocol family
[    0.456437] clocksource: Switched to clocksource arch_sys_counter
[    0.494032] NET: Registered PF_INET protocol family
[    0.494745] IP idents hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.502942] tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.503047] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.504397] TCP established hash table entries: 4096 (order: 2, 16384 bytes, linear)
[    0.504628] TCP bind hash table entries: 4096 (order: 4, 65536 bytes, linear)
[    0.504964] TCP: Hash tables configured (established 4096 bind 4096)
[    0.505575] UDP hash table entries: 256 (order: 2, 14336 bytes, linear)
[    0.507765] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.510356] NET: Registered PF_INET6 protocol family
[    0.520213] Segment Routing with IPv6
[    0.520855] In-situ OAM (IOAM) with IPv6
[    0.530123] Unpacking initramfs...
[    0.546898] workingset: timestamp_bits=30 (anon: 25) max_order=17 bucket_order=0 (anon: 0)
[    0.565789] Freeing initrd memory: 1352K
[    0.588337] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    0.589947] jffs2: version 2.2. (SUMMARY)  © 2001-2006 Red Hat, Inc.
[    0.602781] NET: Registered PF_ALG protocol family
[    0.603469] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    0.604417] io scheduler bfq registered
[    0.657684] Serial: 8250/16550 driver, 6 ports, IRQ sharing enabled
[    0.698561] printk: console [ttyS4] disabled
[    0.716988] 1e784000.serial: ttyS4 MMIO:0x1e784000 (irq = 33, base_baud = 115384) is a 16550A
[    0.717825] printk: console [ttyS4] enabled
[    0.765361] timeriomem_rng 1e6e2524.hwrng: 32bits from 0x(ptrval) @ 1us
[    0.768779] random: crng init done
[    1.037268] loop: module loaded
[    1.226652] MCTP I2C interface driver
[    1.227988] usbcore: registered new interface driver usb-storage
[    1.230210] usbcore: registered new interface driver pl2303
[    1.230476] usbserial: USB Serial support registered for pl2303
[    1.234160] i2c_dev: i2c /dev entries driver
[    1.236345] Driver for 1-wire Dallas network protocol.
[    1.244683] aspeed-edac 1e6e0000.sdram: ECC mode is not configured in u-boot
[    1.244729] aspeed-edac 1e6e0000.sdram: probe with driver aspeed-edac failed with error -1
[    1.250284] usbcore: registered new interface driver usbhid
[    1.250319] usbhid: USB HID core driver
[    1.262507] NET: Registered PF_PACKET protocol family
[    1.262548] 8021q: 802.1Q VLAN Support v1.8
[    1.263013] Registering SWP/SWPB emulation handler
[    1.641082] netconsole: network logging started
[    1.643147] clk: Disabling unused clocks
[    1.683101] Freeing unused kernel image (initmem) memory: 1024K
[    1.698272] Checked W+X mappings: passed, no W+X pages found
[    1.698367] Run /init as init process
=== B650D4U KASAN lifecycle test ===
Watchdog service started: PID=72


BusyBox v1.37.0 (Debian 1:1.37.0-6+b9) built-in shell (ash)
Enter 'help' for a list of built-in commands.

/bin/sh: can't access tty; job control turned off
~ #
~ #
~ # ip r
~ # dmesg | grep -iE 'BUG:|KASAN:|use-after-free|Oops:|WARNING:'
[    0.000000] kasan: Mapping kernel virtual memory block: 80000000-9f000000 at shadow: 6f000000-72e00000
[    0.000000] kasan: Mapping kernel virtual memory block: 7fe00000-80000000 at shadow: 6efc0000-6f000000
~ #
~ #
~ # /bin/busybox ps
PID   USER     COMMAND
    1 0        /bin/sh
    2 0        [kthreadd]
    3 0        [pool_workqueue_]
    4 0        [kworker/R-rcu_g]
    5 0        [kworker/R-sync_]
    6 0        [kworker/R-kvfre]
    7 0        [kworker/R-slub_]
    8 0        [kworker/R-netns]
    9 0        [kworker/0:0-eve]
   10 0        [kworker/0:1-eve]
   11 0        [kworker/0:0H]
   12 0        [kworker/u8:0-ip]
   13 0        [kworker/R-mm_pe]
   14 0        [ksoftirqd/0]
   15 0        [rcu_sched]
   16 0        [rcu_exp_par_gp_]
   17 0        [rcu_exp_gp_kthr]
   18 0        [migration/0]
   19 0        [cpuhp/0]
   20 0        [cpuhp/1]
   21 0        [migration/1]
   22 0        [ksoftirqd/1]
   23 0        [kworker/1:0-eve]
   24 0        [kworker/1:0H]
   25 0        [kworker/u9:0-pm]
   26 0        [kworker/u10:0-e]
   27 0        [kdevtmpfs]
   28 0        [kworker/R-inet_]
   29 0        [rcu_tasks_rude_]
   30 0        [khungtaskd]
   31 0        [oom_reaper]
   32 0        [kworker/u9:1-tt]
   33 0        [kworker/R-write]
   34 0        [kworker/R-bio_c]
   35 0        [kworker/R-kbloc]
   36 0        [kworker/R-tpm_d]
   37 0        [kworker/R-edac-]
   38 0        [watchdogd]
   39 0        [kworker/u10:1-p]
   41 0        [kworker/R-mld]
   42 0        [kworker/R-ipv6_]
   44 0        [kworker/u8:1-ip]
   45 0        [kswapd0]
   46 0        [kworker/u11:0]
   47 0        [kworker/1:2]
   48 0        [pr/ttyS4]
   49 0        [hwrng]
   50 0        [kworker/u12:0]
   51 0        [kworker/u13:0]
   52 0        [kworker/R-nbd0-]
   53 0        [kworker/R-nbd1-]
   54 0        [kworker/R-nbd2-]
   55 0        [kworker/R-nbd3-]
   56 0        [kworker/R-nbd4-]
   57 0        [kworker/R-nbd5-]
   58 0        [kworker/R-nbd6-]
   59 0        [kworker/R-nbd7-]
   60 0        [kworker/R-nbd8-]
   61 0        [kworker/R-nbd9-]
   62 0        [kworker/R-nbd10]
   63 0        [kworker/R-nbd11]
   64 0        [kworker/R-nbd12]
   65 0        [kworker/R-nbd13]
   66 0        [kworker/R-nbd14]
   67 0        [kworker/R-nbd15]
   72 0        /bin/busybox watchdog -F -T 60 -t 5 /dev/watchdog0
   73 0        [kworker/u9:2-pm]
   77 0        /bin/busybox ps
~ #
~ #
~ # ls /sys/class/watchdog/
watchdog0
~ # cat /sys/class/watchdog/watchdog0/state
active
~ # cat /sys/class/watchdog/watchdog0/timeout
60
~ # ls /sys/bus/platform/drivers/aspeed-g6-pinctrl/
1e6e2000.syscon:pinctrl  uevent
bind                     unbind
~ # ls /sys/kernel/debug/pinctrl/
1e6e2000.syscon:pinctrl-aspeed-g6-pinctrl
pinctrl-devices
pinctrl-handles
pinctrl-maps
~ # cat /sys/kernel/debug/pinctrl/pinctrl-devices
name [pinmux] [pinconf]
aspeed-g6-pinctrl yes yes
~ # dmesg | grep -iE 'BUG:|KASAN:|use-after-free|Oops:|WARNING:'
[    0.000000] kasan: Mapping kernel virtual memory block: 80000000-9f000000 at shadow: 6f000000-72e00000
[    0.000000] kasan: Mapping kernel virtual memory block: 7fe00000-80000000 at shadow: 6efc0000-6f000000
~ #
~ #
~ # driver=/sys/bus/platform/drivers/aspeed-g6-pinctrl
~ # device=1e6e2000.syscon:pinctrl
~ # debug=/sys/kernel/debug/pinctrl/1e6e2000.syscon:pinctrl-aspeed-g6-pinctrl
~ #
~ #
~ # echo "=== Hardware: before unbind ==="
at "$de=== Hardware: before unbind ===
~ # cat "$debug/pins" > /dev/null
debugfs read status=$?"~ # echo "debugfs read status=$?"
debugfs read status=0
~ #
~ #
~ # echo "=== Hardware: unbind ==="
=== Hardware: unbind ===
$d~ # echo "$device" > "$driver/unbind"
 status=$?"~ # echo "unbind status=$?"
unbind status=0
~ #
~ #
~ # ls "$driver/"
bind    uevent  unbind
~ #
~ # ls /sys/kernel/debug/pinctrl/
pinctrl-devices  pinctrl-handles  pinctrl-maps
~ #
~ # cat /sys/kernel/debug/pinctrl/pinctrl-devices
name [pinmux] [pinconf]
~ #
~ # dmesg | grep -iE 'BUG: KASAN|use-after-free|Oops:|WARNING:|Kernel panic'
~ #
~ # echo "=== Hardware: rebind ==="
=== Hardware: rebind ===
ver~ # echo "$device" > "$driver/bind"
$?"~ # echo "bind status=$?"
bind status=0
~ #
~ #
~ # ls "$driver/"
ebug/pinctrl/
cat /1e6e2000.syscon:pinctrl  uevent
bind                     unbind
sys/kernel/debug/pinctrl/pinctrl-devices~ # ls /sys/kernel/debug/pinctrl/
1e6e2000.syscon:pinctrl-aspeed-g6-pinctrl
pinctrl-devices
pinctrl-handles
pinctrl-maps
~ # cat /sys/kernel/debug/pinctrl/pinctrl-devices
name [pinmux] [pinconf]
aspeed-g6-pinctrl yes yes
~ #
~ #
~ # cat "$debug/pins" > /dev/null
 status=$?"~ # echo "debugfs read status=$?"
debugfs read status=0
~ #
~ #
~ # cat /sys/class/watchdog/watchdog0/state
active
~ #
~ #
~ # dmesg | grep -iE 'BUG: KASAN|use-after-free|Oops:|WARNING:|Kernel panic'
~ #
~ #
~ #
```
