# -*- mode: ruby -*-
# vi: set ft=ruby :

$master1_IP = "10.0.40.41"
$master2_IP = "10.0.40.42"
$master3_IP = "10.0.40.43"
$slave1_IP = "10.0.40.51"
$slave2_IP = "10.0.40.52"
$slave3_IP = "10.0.40.53"

Vagrant.configure(2) do |config|
  config.vm.box = "centos66"
  config.vm.box_check_update = false
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = "box"
    config.cache.synced_folder_opts = {
      type: "nfs",
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end
  config.vm.synced_folder '.', '/vagrant', nfs: true

  (1..3).each do |j|
    config.vm.define "slave#{j}" do |s|
      s.vm.hostname = "slave#{j}"
      s.vm.network "private_network", ip: "10.0.40.5#{j}"
      s.vm.provision "shell", inline:<<SCRIPT
if [ ! `grep -q '5051' /etc/sysconfig/iptables` ]; then
  echo "Open port 5051"
  LN=$(iptables -L --line-numbers | grep REJECT | cut -d ' ' -f1 | head -n 1)
  iptables -N allow_services
  iptables -I INPUT $LN -j allow_services
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 5051 -j ACCEPT
  service iptables save
  service iptables restart
fi
echo "Check host resolution to /etc/hosts"
if [ ! `grep -q 10.0.40.41 /etc/hosts` ]; then
  echo "10.0.40.41  master1" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.42 /etc/hosts` ]; then
  echo "10.0.40.42  master2" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.43 /etc/hosts` ]; then
  echo "10.0.40.43  master3" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.51 /etc/hosts` ]; then
  echo "10.0.40.51  slave1" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.52 /etc/hosts` ]; then
  echo "10.0.40.52  slave2" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.53 /etc/hosts` ]; then
  echo "10.0.40.53  slave3" >> /etc/hosts
fi

echo "Install mesos repo"
rpm -Uvh http://repos.mesosphere.io/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm

echo "Install mesos"
yum -y install mesos

echo "Configure mesos/zk"
sed -i 's|localhost:2181|#{$master1_IP}:2181,#{$master2_IP}:2181,#{$master3_IP}:2181|' /etc/mesos/zk

echo "Configure mesos-slave ip/hostname"
echo "10.0.40.5#{j}" > /etc/mesos-slave/ip
cp /etc/mesos-slave/ip /etc/mesos-slave/hostname

echo "Remove mesos-master from mesos-slave"
rm -fR /etc/mesos-master/
rm -f /usr/sbin/mesos-master

echo "Install epel repo"
yum -y install epel-release

echo "Install docker"
yum -y install docker-io

echo "Turn on docker on-boot"
chkconfig docker on 

echo "Start docker service"
service docker start

echo "Configure marathon with docker"
echo 'docker,mesos' > /etc/mesos-slave/containerizers
echo '5mins' > /etc/mesos-slave/executor_registration_timeout

echo "Start mesos-slave"
start mesos-slave

SCRIPT
    end
  end
  
  (1..3).each do |i|
    config.vm.define "master#{i}" do |m|
      m.vm.hostname = "master#{i}"
      m.vm.network "private_network", ip: "10.0.40.4#{i}"
      m.vm.provision "shell", inline:<<SCRIPT
if [ ! `grep -q '2181' /etc/sysconfig/iptables` ]; then
  echo "Open port 2181, 2888, 3888, 5050, 8080"
  LN=$(iptables -L --line-numbers | grep REJECT | cut -d ' ' -f1 | head -n 1)
  iptables -N allow_services
  iptables -I INPUT $LN -j allow_services
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 2181 -j ACCEPT
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 2888 -j ACCEPT
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 3888 -j ACCEPT
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 5050 -j ACCEPT
  iptables -A allow_services -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
  service iptables save
  service iptables restart
fi
echo "Check host resolution to /etc/hosts"
if [ ! `grep -q 10.0.40.41 /etc/hosts` ]; then
  echo "10.0.40.41  master1" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.42 /etc/hosts` ]; then
  echo "10.0.40.42  master2" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.43 /etc/hosts` ]; then
  echo "10.0.40.43  master3" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.51 /etc/hosts` ]; then
  echo "10.0.40.51  slave1" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.52 /etc/hosts` ]; then
  echo "10.0.40.52  slave2" >> /etc/hosts
fi
if [ ! `grep -q 10.0.40.53 /etc/hosts` ]; then
  echo "10.0.40.53  slave3" >> /etc/hosts
fi

echo "Install mesos repo"
rpm -Uvh http://repos.mesosphere.io/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm

echo "Install zookeeper repo"
rpm -Uvh http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm

echo "Install mesos marathon zookeeper"
yum -y install mesos marathon zookeeper

echo "Initialize zookeeper server id"
zookeeper-server-initialize --myid=#{i}

echo "Configure zookeeper cluster addresses"
echo $'server.1=#{$master1_IP}:2888:3888\nserver.2=#{$master2_IP}:2888:3888\nserver.3=#{$master3_IP}:2888:3888\n' >> /etc/zookeeper/conf/zoo.cfg

echo "Start zookeeper"
zookeeper-server start

echo "Configure mesos-zookeeper"
sed -i 's|localhost:2181|#{$master1_IP}:2181,#{$master2_IP}:2181,#{$master3_IP}:2181|' /etc/mesos/zk

echo "Set mesos-master quorum"
echo '2' > /etc/mesos-master/quorum

echo "Set mesos-master ip/hostname"
echo "10.0.40.4#{i}" > /etc/mesos-master/ip
cp /etc/mesos-master/ip /etc/mesos-master/hostname

echo "Configure marathon"
sudo mkdir -p /etc/marathon/conf
sudo cp /etc/mesos-master/hostname /etc/marathon/conf
sudo cp /etc/mesos/zk /etc/marathon/conf/master
sudo cp /etc/marathon/conf/master /etc/marathon/conf/zk
sed -i 's|mesos|marathon|' /etc/marathon/conf/zk

echo "Restart zookeeper"
zookeeper-server restart

echo "Add Zookeeper to start up service"
if [ ! -f /etc/init.d/zookeeper-server ]; then
  cp `which zookeeper-server` /etc/init.d/zookeeper-server
  sed -i 's|^#!/bin/sh$|#!/bin/sh\n\n# chkconfig: 2345 95 20\n# description: Apache Zookeeper\n# processname: zookeeper-server|' /etc/init.d/zookeeper-server
  chkconfig --add zookeeper-server
  chkconfig zookeeper-server on
fi

echo "Remove mesos-slave from mesos-master"
rm -fR /etc/mesos-slave/
rm -f /usr/sbin/mesos-slave

echo "Start mesos-master and marathon"
start mesos-master
start marathon

SCRIPT
    end
  end
end
