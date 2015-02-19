# -*- mode: ruby -*-
# vi: set ft=ruby :

$IPs = {
  master1: "10.0.40.41",
  master2: "10.0.40.42",
  master3: "10.0.40.43",
  slave1:  "10.0.40.51",
  slave2:  "10.0.40.52",
  slave3:  "10.0.40.53"  
}

$host_check = <<-BLOCK
#{$IPs.map {|k,v|<<-INNERBLOCK
[ ! `grep -q #{v} /etc/hosts` ] && echo '#{v} #{k}' >> /etc/hosts
INNERBLOCK
}.join()}
BLOCK

$zk_config_addrs = Hash[$IPs.first 3].map{|k,v| "server.#{k.to_sym[-1,1]}=#{v}:2888:3888"}.join("\n")+"\n"

$m_zk_config_addrs = Hash[$IPs.first 3].map{|k,v| "#{v}:2181"}.join(",")

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
  
  (1..3).each do |i|
    config.vm.define "master#{i}" do |m|
      m.vm.hostname = "master#{i}"
      m.vm.network "private_network", ip: "10.0.40.4#{i}"
      m.vm.provision "shell", inline:<<-SCRIPT
if [ ! `grep -q '2181' /etc/sysconfig/iptables` ]; then
  echo "Open port 2181, 2888, 3888, 5050, 8080"
  LN=$(iptables -L --line-numbers | grep REJECT | cut -d ' ' -f1 | head -n 1)
  iptables -N allow_services
  iptables -I INPUT $LN -j allow_services
  iptables -A allow_services -p tcp --match multiport --dports 2181,2888,3888,5050,8080 -j ACCEPT
  service iptables save
  service iptables restart
fi
echo "Check host resolution to /etc/hosts"
#{$host_check}

echo "Install mesos repo"
rpm -Uvh http://repos.mesosphere.io/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm

echo "Install zookeeper repo"
rpm -Uvh http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm

echo "Install mesos marathon zookeeper"
yum -y install mesos marathon zookeeper

echo "Initialize zookeeper server id"
zookeeper-server-initialize --myid=#{i}

echo "Configure zookeeper cluster addresses"
echo $'#{$zk_config_addrs}' >> /etc/zookeeper/conf/zoo.cfg

echo "Start zookeeper"
zookeeper-server start

echo "Configure mesos-zookeeper"
sed -i 's|localhost:2181|#{$m_zk_config_addrs}|' /etc/mesos/zk

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

echo "Remove mesos-slave from mesos-master"
rm -fR /etc/mesos-slave/
rm -f /usr/sbin/mesos-slave

echo "Start mesos-master and marathon"
start mesos-master
start marathon

SCRIPT
    end
  end

  (1..3).each do |j|
    config.vm.define "slave#{j}" do |s|
      s.vm.hostname = "slave#{j}"
      s.vm.network "private_network", ip: "10.0.40.5#{j}"
      s.vm.provision "shell", inline:<<-SCRIPT
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
#{$host_check}

echo "Install mesos repo"
rpm -Uvh http://repos.mesosphere.io/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm

echo "Install mesos"
yum -y install mesos

echo "Configure mesos/zk"
sed -i 's|localhost:2181|#{$m_zk_config_addrs}|' /etc/mesos/zk

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

end
