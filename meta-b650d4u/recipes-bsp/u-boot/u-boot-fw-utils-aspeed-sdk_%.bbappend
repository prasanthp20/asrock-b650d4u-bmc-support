FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-aspeed-sdk/files:"
SRC_URI += " file://b650d4u_defconfig "
do_configure:prepend() {
    install -m 0644 ${UNPACKDIR}/b650d4u_defconfig ${S}/configs/b650d4u_defconfig
}
