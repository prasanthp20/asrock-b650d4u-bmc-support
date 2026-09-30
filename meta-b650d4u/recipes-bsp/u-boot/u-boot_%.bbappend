FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot:"

SRC_URI = "git:///home/prasanth/u-boot;protocol=file;branch=b650d4u-spl-debug \
           "

SRCREV = "83a7020f083f7a9fc9c0faebcc2cb192794b7295"

PV = "2026.04+git"
UBOOT_LOCALVERSION = "-b650d4u"

UBOOT_BINARY = "u-boot-with-spl.bin"
UBOOT_BINARYNAME = "u-boot"

do_deploy:append() {
    ln -sfn ${UBOOT_IMAGE} ${DEPLOYDIR}/u-boot.${UBOOT_SUFFIX}
}
