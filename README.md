# vagrant-oracle-cluster
Vagrant project aimed to automate cluster setup for Oracle Grid Infrastructure installation.

# Basic usage
The first step is to install VirtualBox. https://www.virtualbox.org/wiki/Downloads

## VirtualBox base path
Ensure that in Virtualbox -> Preferences -> General -> Default Machine Molder
you configure a path with enough space and that you note it. In my case it is "/home/luc/VirtualBox VMs".

## Download this GitHub Project
Go to the default machine path (e.g. "/home/luc/VirtualBox VMs" and create a directory with the name for your lab:
```
 $ mkdir raclab
 $ cd raclab
```
Clone the GitHub Project:
 ```
 $ git clone https://github.com/ludovicocaldara/vagrant-oracle-cluster/ .
 ```

## Modify the Vagrantfile
Unless you REALLY need to modify the Vagrantfile structure, just change the configuration between
  ```
  CUSTOM CONFIGURATION START
  ```
  and
   ```
   CUSTOM CONFIGURATION END
   ```
   
Make sure that
```
lab_name = "raclab"
```
Matches the name of the directory that you created. This will assure that **ALL** the files (virtual machines, shared disks, etc.)
will reside inside the very same directory.

The Array _Clusters_ can contain one to many cluster configurations.

Each cluster configuration has the following parameters:
 ```
 :prefix  => "alpha",  # all the nodes in the cluster will have this previx followed by 01, 02, etc. It is also the cluster name. The SCAN will have the same prefix followed by _scan
  :domain  => "trivadistraining.com", # the name of the domain
  :box     => "ludodba/ol7.3-base", # the name of the vagrant box. Don't change it unless you know what you are doing!
  #:box_version => "0.1",  # the version of the vagrant box. Again, don't change it!
  :nodes   => 2, # the nomber of the nodes in the cluster
  :cpu     => 1,  # the number of CPUs for each node
  :mem     => 2048, # The memory (in MB) for each node. Make sure you have enough memory on your host!
  :publan  => IPAddr.new("192.168.56.0/24"), # the ip network of the public addresses (this is the VirtualBox default, make sure to change it depenging on your needs) 
  :publan_start => 51, # the first public ip of the cluster will end with 51 (first node)
  :pubvip_start => 61, # the first public VIP of the cluster will end with 61 (first node)
  :pubscan_start => 71, # the first scan address configured in the DNS will have .71 (71..73)
  :prvlan  => IPAddr.new("172.18.100.0/24"), # the ip network of the private lan (in this version only Private + ASM works)
  :prvlan_start => 51, # the first private ip of the cluster will end with .51
  :hd_num  => 2,  # number of shared disks among the cluster
  :hd_mb   => 2048,  # size of each disk, in MB. Pay attention: shared disks have fixed size so make sure you have enough space. Attention! Oracle Grid Infrastructure 12cR2 requires much MORE than this!!
  :grid   => "yes" # configure additionally the DNS, resolv.conf, hosts, etc. to be installation ready
 ```

Configure as many clusters and nodes as you want.

## Run vagrant!
 ```
 $ vagrant up
  ```
The vagrant box will automatically be downloaded by vagrant and set up.
At the end you will have your cluster(s) ready to be installed.
