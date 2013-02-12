#!/bin/bash
kvm -drive file=/data/vm/test1/test1.img,if=virtio -smp 2 -m 1024 -vnc :10 -net tap -net nic,model=virtio -daemonize -pidfile /data/vm/test1/pid -monitor unix:/data/vm/test1/socket,server,nowait
