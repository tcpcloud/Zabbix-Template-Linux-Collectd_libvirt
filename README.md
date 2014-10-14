# Zabbix Template Linux Collectd_libvirt 

A Zabbix templates for libvirt stats

Tested on:

 Ubuntu 12.04 x86_64 with KVM (kernel 3.5.0-44), collectd 4.10
 Zabbix 2.0.x

 CentOS 6.x X86_64, Collectd 4.10
 Zabbix 2.0.x

### Authors
* Patrik Majer <patrik.majer.pisek@gmail.com>


### installation - Manual

* install a configure zabbix-agent

* copy file "zabbix-collectd.conf" into your zabbix include folder

* install collectd package(s) and perl modules

    apt-get install collectd
    apt-get install libregexp-common-perl

    yum install collectd collectd-virt perl-Collectd

* copy collectd config file (collectd.conf)

* copy script "collect-libvirt-handler.pl" into /etc/zabbix/scripts/collectd-libvirt folder (with 755 perms)

* reboot collectd service

* reboot zabbix-agent service

### installation - Automated

* use puppet module/manifest [czhujer/puppet-zabbixagent](https://github.com/czhujer/puppet-zabbixagent)

### Monitored items

* virt-cpu-total - on all libvirt guests

* disk operations READ - on all libvirt guests

* disk operations WRITE - on all libvirt guests

* disk octets READ - on all libvirt guests

* disk octets WRITE - on all libvirt guests

* network interface packets TR/RX - on all libvirt guests

* network interface octets TR/RX - on all libvirt guests
