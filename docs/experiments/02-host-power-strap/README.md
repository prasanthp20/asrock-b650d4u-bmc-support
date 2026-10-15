# Experiment 02: B650D4U host power control and AST2600 strap handling

Recorded: 2026-10-15
Status: Hardware-tested candidate; RFC submitted; not upstream accepted.

## Problem

Ordinary GPIO host power-on failed while:
- SCU4BC = 0x00000000
- SCU510 = 0x00000000
- SCU51C = 0x00001e80

The power-control daemon asserted and released GPIO123, but power-good
did not assert and the watchdog expired.

## Isolation

A diagnostic driver cleared only SCU51C bit 9:
0x00001e80 -> 0x00001c80.

Ordinary GPIO power-on then succeeded without per-operation THRU1
switching or an additional userspace delay.

## Tested implementation

The candidate modifies the existing AST2600 pinctrl GPIO request path.
The board-specific diagnostic driver, its DT node, custom sysfs interface
and diagnostic boot parameter were removed.

x86-power-control uses ordinary GPIO operations and software button
forwarding.

## Hardware results

- Remote power-on: power-good asserted.
- Remote graceful power-off: power-good deasserted.
- Physical power-button power-on: passed.
- Physical power-button shutdown: passed.
- Kernel taint reported zero during the supplied test session.

## Upstream record

RFC Message-ID:
20261015035118.9495-1-prasanth.padarthi10@gmail.com

Previous withdrawn RFC:
https://lkml.org/lkml/2026/10/2/507

The exact submitted patch is under submission/.

## Known limitations

- Clearing bit 9 affects all three GPIOP pass-through pairs.
- The candidate rejects requests when SCU510 bit 28 is set.
- Post-mux failure paths require rollback design review.
- Automated review raised these compatibility and error-handling concerns.
- Fresh AC-start repeatability, reset/NMI and mixed-pair forwarding
  validation are not established by the recorded tests.
- BMC NotReady, BootProgress and LPC snoop issues remain separate.
- The untested normalization draft and host-autostart work are excluded.

## Evidence and reproducibility

source/ contains archived board files and patches.
manifest.json records known revisions, hashes and missing information.
These are working-tree snapshots, not a standalone reproducible build.

Serial journals showed an unsynchronized Mar 13 clock; those timestamps
must not be presented as experiment wall-clock dates.

Full raw test transcripts and the exact final candidate firmware checksum
still need to be archived. No datacenter qualification is claimed.
