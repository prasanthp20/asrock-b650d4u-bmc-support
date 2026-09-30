FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://power-config-host0.json \
    file://0001-power-control-allow-missing-power-button.patch \
    file://0001-Add-B650D4U-Power-passThrough-Sequencing.patch \
"

EXTRA_OEMESON:append = " \
    -Dbutton-passthrough=enabled \
"

do_install:append() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${UNPACKDIR}/power-config-host0.json \
        ${D}${datadir}/${PN}
}
