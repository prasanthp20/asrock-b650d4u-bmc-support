FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-aspeed-sdk/files:"

SRC_URI += " \
    file://b650d4u_defconfig \
    file://ast2600-b650d4u.dts \
"

do_configure:prepend() {
    install -m 0644 ${UNPACKDIR}/b650d4u_defconfig ${S}/configs/b650d4u_defconfig
    install -m 0644 ${UNPACKDIR}/ast2600-b650d4u.dts ${S}/arch/arm/dts/ast2600-b650d4u.dts

    sed -i '/ast2600a1-evb.dtb/a dtb-$(CONFIG_ASPEED_AST2600) += ast2600-b650d4u.dtb' \
        ${S}/arch/arm/dts/Makefile
}
