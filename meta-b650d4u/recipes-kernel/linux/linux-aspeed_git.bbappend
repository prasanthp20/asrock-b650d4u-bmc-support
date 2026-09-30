FILESEXTRAPATHS:prepend := "${THISDIR}/linux-aspeed:"

SRC_URI:append:b650d4u = " \
    file://aspeed-bmc-asrock-b650d4u.dts \
    file://aspeed-bmc-asrock-b650d4u-common.dtsi \
"

do_configure:append:b650d4u() {
    install -m 0644 ${UNPACKDIR}/aspeed-bmc-asrock-b650d4u.dts \
        ${S}/arch/arm/boot/dts/aspeed/

    install -m 0644 ${UNPACKDIR}/aspeed-bmc-asrock-b650d4u-common.dtsi \
        ${S}/arch/arm/boot/dts/aspeed/
}
