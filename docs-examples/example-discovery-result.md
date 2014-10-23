
[root@test collectd-libvirt]# ./collect-libvirt-handler.pl /var/run/collectd-unixsock LISTVAL LIBVIRT-CPU

```
{
        "data":[
                {
                        "{#NAME}":"instance-00000113-virt_cpu_total"},
                {
                        "{#NAME}":"instance-00000112-virt_cpu_total"},
                {
                        "{#NAME}":"instance-00000111-virt_cpu_total"},
        ]
}
```

[root@test collectd-libvirt]# ./collect-libvirt-handler.pl /var/run/collectd-unixsock LISTVAL LIBVIRT-DISK

```
{
        "data":[
                {
                        "{#NAME}":"instance-00000113-disk-vda"},
                {
                        "{#NAME}":"instance-00000112-disk-vda"},
                {
                        "{#NAME}":"instance-00000111-disk-vda"},
        ]
}
```

[root@test collectd-libvirt]# ./collect-libvirt-handler.pl /var/run/collectd-unixsock LISTVAL LIBVIRT-NET

```
{
        "data":[
                {
                        "{#NAME}":"instance-00000113-if-tap620bc156-19"},
                {
                        "{#NAME}":"instance-00000112-if-tap50269e65-06"},
                {
                        "{#NAME}":"instance-00000111-if-tap869d29b8-08"},
        ]
}
```


