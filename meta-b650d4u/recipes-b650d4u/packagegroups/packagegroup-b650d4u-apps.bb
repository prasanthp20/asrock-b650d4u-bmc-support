SUMMARY = "OpenBMC for ASRock B650D4U - Applications"
inherit packagegroup
PACKAGES = "${PN}-chassis ${PN}-fans ${PN}-flash ${PN}-system"
PROVIDES = "virtual/obmc-chassis-mgmt virtual/obmc-fan-mgmt virtual/obmc-flash-mgmt virtual/obmc-system-mgmt"
RPROVIDES:${PN}-chassis = "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans = "virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-flash = "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system = "virtual-obmc-system-mgmt"
RDEPENDS:${PN}-chassis = "x86-power-control"
RDEPENDS:${PN}-flash = "phosphor-software-manager"
RDEPENDS:${PN}-system = " \
    bmcweb \
    dbus-tools \
    devmem2 \
    entity-manager \
    ethtool \
    i2c-tools \
    iproute2 \
    iperf3 \
    libgpiod-tools \
    lmsensors-sensors \
    lsof \
    mtd-utils \
    net-tools-mii-tool \
    obmc-console \
    phosphor-host-postd \
    phytool \
    procps \
    strace \
    tcpdump \
    trace-cmd \
    util-linux \
"
