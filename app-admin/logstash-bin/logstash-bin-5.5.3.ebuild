# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user

MY_PN="${PN%-bin}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Tool for managing events and logs"
HOMEPAGE="https://www.elastic.co/products/logstash"
SRC_URI="https://artifacts.elastic.co/downloads/${MY_PN}/${MY_P}.zip"

# source: LICENSE.txt and NOTICE.txt
LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"
QA_PREBUILT="opt/logstash/vendor/jruby/lib/jni/*/libjffi*.so"

RDEPEND="virtual/jre:1.8"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	enewgroup ${MY_PN}
	enewuser ${MY_PN} -1 -1 /var/lib/${MY_PN} ${MY_PN}
}

src_install() {
	keepdir /etc/"${MY_PN}"/{conf.d,patterns,plugins}
	keepdir "/var/lib/${MY_PN}"
	keepdir "/var/log/${MY_PN}"

	insinto "/usr/share/${MY_PN}"
	newins "${FILESDIR}/agent.conf.sample" agent.conf

	insinto "/opt/${MY_PN}"
	doins -r .
	fperms 0755 "/opt/${MY_PN}/bin/${MY_PN}" "/opt/${MY_PN}/vendor/jruby/bin/jruby" "/opt/${MY_PN}/bin/logstash-plugin"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${MY_PN}.logrotate" "${MY_PN}"

	newconfd "${FILESDIR}/${MY_PN}.confd" "${MY_PN}"
	newinitd "${FILESDIR}/${MY_PN}.initd" "${MY_PN}"

	insinto /usr/share/eselect/modules
	doins "${FILESDIR}"/logstash-plugin.eselect
}

pkg_postinst() {
	ewarn "The default pidfile directory has been changed from /run/logstash to /run."
	ewarn "Please ensure any running logstash processes are shut down cleanly."
	ewarn
	ewarn "The default data directory has been moved from /opt/logstash/data to"
	ewarn "/var/lib/logstash/data. Please check and move its contents as necessary."
	ewarn
	ewarn "Self installed plugins are removed during Logstash upgrades (Bug #622602)"
	ewarn "Install the plugins via eselect module that will automatically re-install"
	ewarn "all self installed plugins after Logstash upgrades."
	einfo
	einfo "Installing plugins:"
	einfo "eselect logstash-plugin install logstash-output-gelf"
	einfo

	einfo "Reinstalling self installed plugins (installed via eselect module):"
	eselect logstash-plugin reinstall

	einfo
	einfo "Sample configuration:"
	einfo "${EROOT%/}/usr/share/${MY_PN}"
}
