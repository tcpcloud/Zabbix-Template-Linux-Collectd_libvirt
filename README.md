# Zabbix Template Linux Collectd_libvirt 

A Zabbix templates for libvirt stats

Tested on:
Ubuntu 12.04 x86_64 with KVM (kernel 3.5.0-44), zabbix-agent 2.0.10 - 2.0.12, collectd 4.10

### Authors
* Patrik Majer <patrik.majer.pisek@gmail.com>


### installation

* install a configure zabbix-agent

* copy file "zabbix-collectd.conf" into your zabbix include folder

* install collectd package(s) and perl modules
    apt-get install collectd
    apt-get install libregexp-common-perl

* copy collectd config file (collectd.conf)

* copy script "collect-libvirt-handler.pl" into /etc/zabbix/scripts/collectd-libvirt folder (with 755 perms)

* reboot collectd service

* reboot zabbix-agent service


### Monitored items

* virt-cpu-total - on all libvirt guests

* disk operations READ - on all libvirt guests

* disk operations WRITE - on all libvirt guests

* disk octets READ - on all libvirt guests

* disk octets WRITE - on all libvirt guests

* network interface packets TR/RX - on all libvirt guests

* network interface octets TR/RX - on all libvirt guests
