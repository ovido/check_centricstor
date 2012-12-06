Name:		nagios-plugins-centricstor
Version:	0.1
Release:	1%{?dist}
Summary:	CentricStor monitoring plugin for Nagios/Icinga

Group:		Applications/System
License:	GPLv2+
URL:		https://labs.ovido.at/monitoring
Source0:	check_centricstor-%{version}.tar.gz
BuildRoot:	%{_tmppath}/check_centricstor-%{version}-%{release}-root

%description
This plugin for Icinga/Nagios is used to monitor cache usage
(free and dirty) and slot status of a Fujitsu CentricStor.

%prep
%setup -q -n check_centricstor-%{version}

%build
%configure --prefix=%{_libdir}/nagios/plugins \
	   --with-nagios-user=nagios \
	   --with-nagios-group=nagios \
	   --with-pnp-dir=%{_datadir}/nagios/html/pnp4nagios

make all


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT INSTALL_OPTS=""

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(0755,nagios,nagios)
%{_libdir}/nagios/plugins/check_centricstor
%{_datadir}/nagios/html/pnp4nagios/templates/check_centricstor.php
%doc README INSTALL NEWS ChangeLog COPYING



%changelog
* Thu Dec 6 2012 Rene Koch <r.koch@ovido.at> 0.1-1
- Initial build.

