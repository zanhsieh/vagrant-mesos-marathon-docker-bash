# vagrant-mesos-stack-centos6

Deploy Mesos+Marathon+Docker small cluster (3x master + 3x slaves) on CentOS 6.6 with pure bash script (no puppet/check/anisible/salt...).

Note:

1. Box 'centos66' is a simple CentOS 6.6 minimal Vagrant box created from my [another repository](https://github.com/zanhsieh/packer-vagrant-linux) from Packer. You are welcome to swap to your CentOS 6.6 box.
2. After cluster booting up, you could run 'run-docker-inky.sh' or 'run_docker_Docker.sh' (this required to increase the timeout in each slave or change "echo '5mins' > /etc/mesos-slave/executor_registration_timeout" in Vagrantfile).
