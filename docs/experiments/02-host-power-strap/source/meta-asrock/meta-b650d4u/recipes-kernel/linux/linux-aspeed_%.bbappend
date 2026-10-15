FILESEXTRAPATHS:prepend := "${THISDIR}/linux-aspeed:"

SRC_URI:append = " \
    file://aspeed-bmc-asrock-b650d4u.dts \
    file://0006-pinctrl-aspeed-g6-gpio-strap9-candidate.patch \
"

do_configure:prepend() {
    install -m 0644 ${UNPACKDIR}/aspeed-bmc-asrock-b650d4u.dts \
        ${S}/arch/arm/boot/dts/aspeed/aspeed-bmc-asrock-b650d4u.dts
}
