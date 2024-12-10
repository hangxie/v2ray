Name:           v2ray
Version:        CHANGEME
Release:        1%{?dist}
Summary:        Utility to deal with Parquet data
License:        BSD
Provides:       %{name} = %{version}
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  systemd-rpm-macros

%description
v2ray server https://github.com/hangxie/v2ray

%global debug_package %{nil}

%prep
%autosetup

%build

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}
install -Dpm 0644 config.json %{buildroot}/%{_sysconfdir}/v2ray/config.json
install -Dpm 0644 %{name}.service %{buildroot}/%{_unitdir}/%{name}.service

%files
%{_bindir}/%{name}
%{_unitdir}/%{name}.service
%config(noreplace) %{_sysconfdir}/v2ray/config.json
