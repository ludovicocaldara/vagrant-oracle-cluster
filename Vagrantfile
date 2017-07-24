## -*- mode: ruby -*-
## vi: set ft=ruby :

require 'ipaddr'

###############################
# CUSTOM CONFIGURATION START
###############################

# lab_name is the name of the lab where all the files will be organized.
lab_name = "raclab"

oracle_sw_path  = "/home/luc/Downloads/Software/Oracle/12cR2"

clusters = [
  {
  :prefix  => "alpha",
  :domain  => "trivadistraining.com",
  :box     => "ludodba/ol7.3-base",
  #:box_version => "0.1",
  :nodes   => 2,
  :cpu     => 1,
  :mem     => 2048,
  :publan  => IPAddr.new("192.168.56.0/24"),
  :publan_start => 51,
  :pubvip_start => 61,
  :pubscan_start => 71,
  :prvlan  => IPAddr.new("172.18.100.0/24"),
  :prvlan_start => 51,
  :hd_num  => 6,
  :hd_mb   => 4096,
  :grid   => "yes" # configure additionally the DNS, cvuqdisk, etc.
  }
]

###############################
# CUSTOM CONFIGURATION END
###############################

# Begin of functions.
# For main Vagrant... search MAIN


######################################################
# Extending Class IPAddr to add the CIDR to the lan
class IPAddr
  def to_cidr_s
    if @addr
      mask = @mask_addr.to_s(2).count('1')
      "#{to_s}/#{mask}"
    else
      nil
    end
  end
end # extend class IPAddr



###################################################
# Function f_in_arpa
# This function returns the command to rewrite the in.arpa file
# of the DNS (/var/named/in.arpa). ONLY FOR THE DNS MASTER
# arguments
#   clu : the cluster object
def f_in_arpa (clu)

  hostmaster="#{clu[:prefix]}01"

  zone_file = <<ZONEFILE
echo '$TTL 3H
@       IN SOA  #{hostmaster}.#{clu[:domain]}.        hostmaster.#{clu[:domain]}.      (
                                        101   ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
ZONEFILE

  # adding name servers
  (1..(clu[:nodes])).each do |nid|
    zone_file += "\n      NS      #{clu[:prefix]}%02d.#{clu[:domain]}." % nid
  end # loop nodes

  # adding A records
  (1..(clu[:nodes])).each do |nid|
    zone_file += "\n%s    PTR     #{clu[:prefix]}%02d.#{clu[:domain]}." % [clu[:publan].|(clu[:publan_start]+nid-1).reverse.chomp('.in-addr.arpa') , nid]
    zone_file += "\n%s    PTR     #{clu[:prefix]}%02d-vip.#{clu[:domain]}."  % [clu[:publan].|(clu[:pubvip_start]+nid-1).reverse.chomp('.in-addr.arpa')  , nid]
    zone_file += "\n%s    PTR     #{clu[:prefix]}%02d-priv.#{clu[:domain]}."  % [clu[:prvlan].|(clu[:prvlan_start]+nid-1).reverse.chomp('.in-addr.arpa')  , nid]
  end # loop nodes

  # adding scans
  (1..3).each do |scanid|
    zone_file += "\n%s    PTR     #{clu[:prefix]}-scan.#{clu[:domain]}."  % clu[:publan].|(clu[:pubscan_start]+scanid-1).reverse.chomp('.in-addr.arpa')
  end # loop nodes

  # ending the command
  zone_file += <<ZONEFILE

' > /var/named/in-addr.arpa
ZONEFILE
end #f_in_arpa



###################################################
# Function f_zone_file
# This function returns the command to rewrite the zone file
# of the DNS (/var/named/#{domain}). ONLY FOR THE DNS MASTER
# arguments
#   clu : the cluster object
def f_zone_file (clu)

  hostmaster="#{clu[:prefix]}01"

  zone_file = <<ZONEFILE
echo '$TTL 3H
@       IN SOA  #{hostmaster}        hostmaster      (
                                        101   ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
ZONEFILE

  # adding name servers
  (1..(clu[:nodes])).each do |nid|
    zone_file += "\n      NS      #{clu[:prefix]}%02d" % nid
  end # loop nodes

  # adding A records
  (1..(clu[:nodes])).each do |nid|
    zone_file += "\n#{clu[:prefix]}%02d         A      %s" % [nid, clu[:publan].|(clu[:publan_start]+nid-1).to_s ]
    zone_file += "\n#{clu[:prefix]}%02d-vip     A      %s" % [nid, clu[:publan].|(clu[:pubvip_start]+nid-1).to_s ]
    zone_file += "\n#{clu[:prefix]}%02d-priv    A      %s" % [nid, clu[:prvlan].|(clu[:prvlan_start]+nid-1).to_s ]
  end # loop nodes

  # adding scans
  (1..3).each do |scanid|
    zone_file += "\n#{clu[:prefix]}-scan        A      %s" % clu[:publan].|(clu[:pubscan_start]+scanid-1).to_s
  end # loop nodes

  # ending the command
  zone_file += <<ZONEFILE

localhost       A       127.0.0.1
' > /var/named/#{clu[:domain]}


ZONEFILE
end #zone_file


###################################################
# Function f_named_config
# This function returns the command to rewrite the named.conf
# FOR MASTER AND SLAVES
# arguments
#   clu : the cluster object
#   nid : the id of the node in the cluster (1..clu[:nodes])
#
def f_named_config (clu, nid)
  if nid == 1 then
    dns_type = "master"
    dns_masters = ""
  else
    dns_type = "slave"
    dns_masters = "masters { #{clu[:publan].|(clu[:publan_start]).to_s}; };"
  end
  #@ puts "    #{dns_type.capitalize} Named Config"

  ## here starts the HEREDOC
  named_conf = <<NAMEDCONF
systemctl enable named.service
touch /var/named/#{clu[:domain]}
chgrp named /var/named/#{clu[:domain]}
chmod 664 /var/named/#{clu[:domain]}
chmod g+w /var/named

echo '
options {
       listen-on port 53 { #{clu[:publan].|(clu[:publan_start]+nid-1).to_s}; };
       listen-on-v6 port 53 { ::1; };
       directory       "/var/named";
       dump-file       "/var/named/data/cache_dump.db";
       statistics-file "/var/named/data/named_stats.txt";
       memstatistics-file "/var/named/data/named_mem_stats.txt";
       allow-query     { #{clu[:publan].to_cidr_s}; localhost; };
       allow-transfer  { #{clu[:publan].to_cidr_s}; };
       recursion yes;

       dnssec-enable yes;
       dnssec-validation yes;
       dnssec-lookaside auto;

       /* Path to ISC DLV key */
       bindkeys-file "/etc/named.iscdlv.key";

       managed-keys-directory "/var/named/dynamic";
};

logging {
       channel default_debug {
               file "data/named.run";
               severity dynamic;
       };
};

zone "." IN {
       type hint;
       file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "#{clu[:domain]}" {
 type #{dns_type};
 #{dns_masters}
 file "#{clu[:domain]}";
};

zone "in-addr.arpa" {
 type #{dns_type};
 #{dns_masters}
 file "in-addr.arpa";
};
' > /etc/named.conf

rndc-confgen -a -r /dev/urandom
chgrp named /etc/rndc.key
chmod g+r /etc/rndc.key


NAMEDCONF
  ## END OF THE HEREDOC

  named_conf ## used to return the value
end # def f_named_config


###################################################
# Function f_resolv
# This function returns the command to rewrite the resolv.conf
# FOR MASTER AND SLAVES
# arguments
#   clu : the cluster object
def f_resolv (clu)

  resolv_file = <<RESOLV
echo 'search #{clu[:domain]}
RESOLV

  # adding name servers
  (1..(clu[:nodes])).each do |nid|
	  resolv_file += "\nnameserver #{clu[:publan].|(clu[:publan_start]+nid-1).to_s}"
  end # loop nodes

  resolv_file += <<RESOLV

' > /etc/resolv.conf

sed -i -e 's/PEERDNS="yes"/PEERDNS="no"/' /etc/sysconfig/network-scripts/ifcfg-e*
sed -i -e 's/\\[main\\]/\\[main\\]\\ndns=none/'   /etc/NetworkManager/NetworkManager.conf

systemctl restart network

echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
' > /etc/hosts

systemctl start named.service
RESOLV
end #f_resolv

########
# MAIN #
########

Vagrant.configure(2) do |config|

  config.ssh.username = "root"
  config.ssh.password = "vagrant"
  #config.vm.box_url = vagrant_box_url
  #config.vm.graceful_halt_timeout = 360

  if File.directory?(oracle_sw_path)
    # our shared folder for oracle 12c installation files (uid 54320 is grid, uid 54321 is oracle)
    config.vm.synced_folder oracle_sw_path, "/media/sw", :mount_options => ["dmode=775","fmode=775","uid=54321","gid=54321"]
  end


  # looping through each cluster
  (0..(clusters.length-1)).each do |cluid|

    # assign variable clu to current cluster, for convenience
    clu = clusters[cluid]
    config.vm.box = clu[:box]
    if (clu[:box_version]) then
      config.vm.box_version = clu[:box_version]
    end #if

    # looping through each node in the cluster
    (1..(clu[:nodes])).each do |nid|

      # let's start from the last node :-)
      nid = clu[:nodes]+1-nid

      config.vm.define vm_name = "#{clu[:prefix]}%02d" % nid do |config|

        vm_name = "#{clu[:prefix]}%02d" % nid

        fqdn = "#{vm_name}.#{clu[:domain]}"
        config.vm.hostname = "#{fqdn}"

        pubip = clu[:publan].|(clu[:publan_start]+nid-1).to_s

        prvip = clu[:prvlan].|(clu[:prvlan_start]+nid-1).to_s

        config.vm.provider :virtualbox do |vb|
          #vb.linked_clone = true
          vb.name = vm_name
          vb.gui = true
          vb.customize ["modifyvm", :id, "--memory", clu[:mem]]
          vb.customize ["modifyvm", :id, "--cpus",   clu[:cpu]]
          vb.customize ["modifyvm", :id, "--groups", "/#{lab_name}/#{clu[:prefix]}"]

          #port=1
          if clu[:hd_num] > 0  then
            (1..(clu[:hd_num])).each do |disk|
              file_to_dbdisk = "#{clu[:prefix]}/#{clu[:prefix]}-shared-disk%02d.vdi" % disk

              # checking file creation: if it does not exist and we are at the higest (first) node, we create it
              if !File.exist?(file_to_dbdisk) and clu[:nodes]==nid then
                vb.customize ['createhd', '--filename', file_to_dbdisk, '--size', clu[:hd_mb].floor, '--variant', 'fixed']
                vb.customize ['modifyhd', file_to_dbdisk, '--type', 'shareable']
              end #file exixts
              vb.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', disk, '--device', 0, '--type', 'hdd', '--medium', file_to_dbdisk]
              #port=port+1
            end #each disk
          else
            #  No Shared disks
          end # hd > 0

        end #config.vm.provider
        # Configuring virtualbox networks for #{pubip} and #{prvip}
        config.vm.network :private_network, ip: pubip
        config.vm.network :private_network, ip: prvip
        # Configuring ASM Disks
        config.vm.provision "Configure ASM disks", :type => "shell", :inline => "sh /media/vagrant/asm.sh #{clu[:hd_num]} oracle oinstall"

        if clu[:grid] == "yes" then
	  config.vm.provision "Configure named.conf", :type => "shell", :inline => "#{f_named_config clu, nid}"
          if nid == 1
	    config.vm.provision "Configure DNS zonefile", :type => "shell", :inline => "#{f_zone_file clu}"
	    config.vm.provision "Configure DNS reverse", :type => "shell", :inline => "#{f_in_arpa clu}"
          end
	  config.vm.provision "Finishing Network setup", :type => "shell", :inline => "#{f_resolv clu}"
        end
      end #config.vm.define
    end #loop nodes
  end  #loop clusters
end #Vagrant.configure
