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


## Real Example (using vagrant box 0.2)
### Vagrant custom configuration
```
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
  :mem     => 6144,
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
```

### Virtualbox files
```
luc@ludo:~/VirtualBox VMs$ find raclab | grep -v .git | grep -v .vagrant | sort
raclab
raclab/alpha
raclab/alpha/alpha01
raclab/alpha/alpha01/alpha01.vbox
raclab/alpha/alpha01/alpha01.vbox-prev
raclab/alpha/alpha01/box-disk001.vmdk
raclab/alpha/alpha01/Logs
raclab/alpha/alpha01/Logs/VBox.log
raclab/alpha/alpha02
raclab/alpha/alpha02/alpha02.vbox
raclab/alpha/alpha02/alpha02.vbox-prev
raclab/alpha/alpha02/box-disk001.vmdk
raclab/alpha/alpha02/Logs
raclab/alpha/alpha02/Logs/VBox.log
raclab/alpha/alpha-shared-disk01.vdi
raclab/alpha/alpha-shared-disk02.vdi
raclab/alpha/alpha-shared-disk03.vdi
raclab/alpha/alpha-shared-disk04.vdi
raclab/alpha/alpha-shared-disk05.vdi
raclab/alpha/alpha-shared-disk06.vdi
raclab/asm.sh
raclab/LICENSE
raclab/README.md
raclab/Vagrantfile
```

### The machines
```
### Connection: 
luc@ludo:~/VirtualBox VMs/raclab$ vagrant ssh alpha01
Last login: Tue Jul 25 20:56:05 2017 from 10.0.2.2

### Automatic DNS Setup!
[root@alpha01 ~]# dig alpha-scan.trivadistraining.com @192.168.56.51

; <<>> DiG 9.9.4-RedHat-9.9.4-50.el7_3.1 <<>> alpha-scan.trivadistraining.com @192.168.56.51
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64363
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;alpha-scan.trivadistraining.com. IN    A

;; ANSWER SECTION:
alpha-scan.trivadistraining.com. 10800 IN A     192.168.56.72
alpha-scan.trivadistraining.com. 10800 IN A     192.168.56.71
alpha-scan.trivadistraining.com. 10800 IN A     192.168.56.73

;; AUTHORITY SECTION:
trivadistraining.com.   10800   IN      NS      alpha02.trivadistraining.com.
trivadistraining.com.   10800   IN      NS      alpha01.trivadistraining.com.

;; ADDITIONAL SECTION:
alpha01.trivadistraining.com. 10800 IN  A       192.168.56.51
alpha02.trivadistraining.com. 10800 IN  A       192.168.56.52

;; Query time: 0 msec
;; SERVER: 192.168.56.51#53(192.168.56.51)
;; WHEN: Die Jul 25 21:05:34 CEST 2017
;; MSG SIZE  rcvd: 184

### Usernames and groups
[root@alpha01 ~]# id oracle
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),995(vboxsf),54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54327(racdba)
[root@alpha01 ~]# id grid
uid=54320(grid) gid=54321(oinstall) groups=54321(oinstall),54322(dba),995(vboxsf),54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54327(racdba)

### Preinstall package:
[root@alpha01 ~]# rpm -qa | grep oracle-database
oracle-database-server-12cR2-preinstall-1.0-2.el7.x86_64

### Shared disks!
[root@alpha01 ~]# ls -l /dev/asm*
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk1 -> sdb1
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk2 -> sdc1
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk3 -> sdd1
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk4 -> sde1
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk5 -> sdf1
lrwxrwxrwx. 1 root root 4 25. Jul 20:55 /dev/asm-disk6 -> sdg1

### (almost there:) user equivalence:
# [ oracle@alpha01:/home/oracle/.ssh [21:10:09] [OH not set SID="not set"] 0 ] #
# ssh alpha02
The authenticity of host 'alpha02 (192.168.56.52)' can't be established.
ECDSA key fingerprint is 32:b4:f7:cb:3a:28:2a:53:37:8c:15:4d:4d:b9:3e:26.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'alpha02,192.168.56.52' (ECDSA) to the list of known hosts.
Last login: Tue Jul 25 21:09:55 2017 from 192.168.56.51
```
