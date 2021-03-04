#!/bin/sh -eux

version=$(grep ^VERSION_ID= /etc/os-release | cut -f2 -d\" | cut -f1 -d\ )

zypper removerepo "openSUSE-${version}-0"

zypper ar -f http://download.opensuse.org/tumbleweed/repo/oss/ openSUSE-MicroOS-${version}-OSS
zypper ar -f http://download.opensuse.org/update/tumbleweed/ openSUSE-MicroOS-Update
zypper ar -f http://download.opensuse.org/tumbleweed/repo/non-oss/ openSUSE-MicroOS-non-OSS
zypper ar -d http://download.opensuse.org/debug/tumbleweed/repo/oss/ openSUSE-MicroOS-Debug-OSS
zypper ar -d http://download.opensuse.org/source/tumbleweed/repo/oss/ openSUSE-MicroOS-Source
