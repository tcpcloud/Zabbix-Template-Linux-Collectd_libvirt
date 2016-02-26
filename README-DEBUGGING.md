# Zabbix Template Linux Collectd_libvirt - DEEP DIVE AND DEBUG MANUAL

## How it works

* zabbix-agent calls collect-libvirt-handler.pl script

* collect-libvirt-handler.pl calls collectd service over unixsocket

* * after transforms zabbix-item's names (keys) to libvirt's names (unixsocket format)

* * after reads values and return data back to zabbix-agent

If you have in zabbix name with key: collectd-libvirt.cpu["instance-00000841-virt_cpu_total"],
zabbix runs external command: sudo /etc/zabbix/scripts/collectd-libvirt/collect-libvirt-handler.pl /var/run/collectd-unixsock GETVAL instance-00000841-virt_cpu_total
and and should return number :)

## Example workflow

* You should be see in zabbix server this items

```
 collectd-libvirt.disk-ops-read[serve.lordcritical-disk-vda]
 collectd-libvirt.disk-ops-write[serve.lordcritical-disk-vda]
 collectd-libvirt.disk-oct-read[serve.lordcritical-disk-vda]
 collectd-libvirt.disk-oct-write[serve.lordcritical-disk-vda]
 collectd-libvirt.cpu[serve.lordcritical-virt_cpu_total]
(and network items...)
```

* after this $command variable should be (...handler.pl):

```
GETVAL serve.lordcritical/libvirt/disk_ops-vda OPS-READ 
GETVAL serve.lordcritical/libvirt/disk_ops-vda OPS-WRITE
GETVAL serve.lordcritical/libvirt/disk_octets-vda OCT-READ
GETVAL serve.lordcritical/libvirt/disk_octets-vda OCT-WRITE
GETVAL serve.lordcritical/libvirt/virt_cpu_total
```

* and into collectd unixsocket arrive queries

```
GETVAL serve.lordcritical/libvirt/disk_ops-vda
GETVAL serve.lordcritical/libvirt/disk_octets-vda
GETVAL serve.lordcritical/libvirt/virt_cpu_total
```

## Example of Discovery results

https://github.com/czhujer/Zabbix-Template-Linux-Collectd_libvirt/blob/master/docs-examples/example-discovery-result.md


## DEBUG

* install template https://github.com/czhujer/Zabbix-Template-Linux-Collectd_libvirt

* check if script collect-libvirt-handler.pl works

* uncomment line 45

  (print "DEBUG: command: " . $command . " val: " . $val . " \n";)

* check results ..


~~~
with zabbix key: 	collectd-libvirt.cpu["instance-00000841-virt_cpu_total"]
debug output shlould by: 
DEBUG: command: GETVAL instance-00000841/libvirt/virt_cpu_total val: instance-00000841/libvirt/virt_cpu_total
2000000
~~~

* if dont have, download exmaple script for collectd unixsocket communication..

```
  [root@localhost]# wget https://raw.githubusercontent.com/collectd/collectd/master/contrib/cussh.pl
```

* run example script

```
  [root@localhost]# ./cussh.pl or ./cussh.pl /var/run/collectd-unixsock
```

* send command from $command value into cussh shel..

```
cussh> GETVAL instance-00000841/libvirt/virt_cpu_total
        ns: 2000000
```

* check if this number is same as returns collect-libvirt-handler.pl


### DEBUG items name

simillar like a DEBUG

* run commnad "LISTVAL" in cussh shel..

```
cussh> LISTVAL

1413985396 instance-00000935/libvirt/disk_octets-vda
1413985396 instance-00000935/libvirt/disk_ops-vda
1413985396 instance-00000935/libvirt/if_dropped-tap869d29b8-08
1413985396 instance-00000935/libvirt/if_errors-tap869d29b8-08
1413985396 instance-00000935/libvirt/if_octets-tap869d29b8-08
1413985396 instance-00000935/libvirt/if_packets-tap869d29b8-08
1413985396 instance-00000935/libvirt/virt_cpu_total
1413985396 instance-00000935/libvirt/virt_vcpu-0
1413985396 instance-00000935/libvirt/virt_vcpu-1
```

* modify script collect-libvirt-handler.pl like that, so print to the same things as you see in LISTVAL part...

LINES 21 - 24 is for "cpu_total"

LINES 25 - 33 is for "disk stats"

LINES 34 - 41 is for "networks stats"
