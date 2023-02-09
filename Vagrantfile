# Vagrant.configure("2") do |config|
#   config.vm.provider "virtualbox" do |v|
#     v.memory = 4096
#     v.cpus = 2
#     v.name = 'vagrant-microk8s'
#   end
#   config.vm.network "private_network", ip: "192.168.1.4"
#   config.vm.box = "generic/ubuntu2004"
#   config.vm.synced_folder "certs/", "/certs"
#   config.vm.provision "file", source: "#{File.dirname(__FILE__)}/.bash_aliases", destination: "~/.bash_aliases"
#   config.vm.provision :shell, path: "#{File.dirname(__FILE__)}/bin/bootstrap.sh"
#   config.ssh.username = "vagrant"
#   config.ssh.password = "vagrant"
# end

Vagrant.configure('2') do |config|
  config.vm.box = 'bento/ubuntu-22.04'

  ### cluster name configuration
  cluster_name="microk8-vag-01"

  # below are scripts based on https://github.com/cloud-hero/vagrant-microk8s
  config.vm.synced_folder "certs/", "/certs"
  config.vm.provision "file", source: "#{File.dirname(__FILE__)}/.bash_aliases", destination: "~/.bash_aliases"
  config.vm.provision :shell, path: "#{File.dirname(__FILE__)}/bin/bootstrap.sh"
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"

  cluster_network = "192.168.1"
  config.vm.network "public_network", bridge: "wlp2s0: Wi-Fi (AirPort)", auto_config: true

  # below are script based on earlier work on vagrant and setting up ssh
  $common_installations = <<-'SCRIPT'
  echo "192.168.1.10 microk8-vag-01-node-0" >> /etc/hosts
  echo "192.168.1.11 microk8-vag-01-node-1" >> /etc/hosts
  echo "192.168.1.12 microk8-vag-01-node-2" >> /etc/hosts
  sudo apt-get update -y
  sudo apt-get install git net-tools openssh-server sshpass tree fish jq lvm2 xfsprogs -y
  sudo service ssh restart
  sudo ufw allow from 192.168.1.0/24 to any port 22
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
  sudo sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sudo sed -i -E 's/#?ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  sudo sed -i -E 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  sudo sed -i -E 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
  ssh-keygen -t rsa -b 2048 -f /home/vagrant/.ssh/id_rsa -q -N ""
  sudo systemctl restart ssh
  SCRIPT

  #  -----------------------------------------------------------------------------------
  (0..2).each do |i|
    config.vm.define "#{cluster_name}-node-#{i}" do |node|
      node.vm.hostname = "#{cluster_name}-node-#{i}"
      node.vm.network :public_network, ip: "#{cluster_network}.1#{i}"
      node.vm.provision 'shell', inline: $common_installations

      node.vm.provider 'virtualbox' do |vb|
        # vb.hostname = "#{cluster_name}-node-#{i}"
        vb.memory = 4096
        vb.cpus = 4
        vb.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
        vb.customize ['modifyvm', :id, '--nested-hw-virt', 'on']

        unless File.exist?("./#{cluster_name}-node-#{i}-disk-02.vdi")
          vb.customize ['createhd', '--filename', "./#{cluster_name}-node-#{i}-disk-02.vdi", '--variant', 'Standard', '--size', 100 * 1024]
        end

        vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "./#{cluster_name}-node-#{i}-disk-02.vdi"]
      end
    end
  end

end

