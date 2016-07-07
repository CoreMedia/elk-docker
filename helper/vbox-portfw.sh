#!/bin/bash -u
# execute this script if you are using OSX
# it will add port forwardings between local ports and docker-machine

FORWARD_PORTS='5601 9200 9300 5000 5044 5001'

for i in ${FORWARD_PORTS}; do
  echo "forward port ${i}"
  VBoxManage controlvm "default" natpf1 tcp-port${i},tcp,,${i},,${i} > /dev/null 2>&1
  VBoxManage controlvm "default" natpf1 udp-port${i},udp,,${i},,${i} > /dev/null 2>&1
done