# Building a Toy Slurm Cluster

In this project we will be using virtual machines to assemble a basic demonstration of a Slurm cluster

## Before You Begin

### Prerequisites

The following software environments are assumed to be present and functional within your local compute environment to enable this deployment: 

* Host Machine - will be responsible for hosting the provisioned VMs
    * Proxmox VE (tested against v8.2.4, but may work with prior 8.x versions)
* Operator Machine - will be responsible for sending deployment instructions to the host machine and the guest VMs we deploy on it
    * Terraform
    * Python3.11

#### Installing prerequisites

##### Host Machine

You can follow the installation guide for Proxmox VE [on their wiki](https://pve.proxmox.com/wiki/Installation).  It is largely akin to your typical Debian system install.  Instructions/automation for installing this host are not within scope of this project.

The host must meet the following requirements:
* CPU
    * 4 physical cores or more
    * Virtualization extensions
* Disk
    * 100GiB available disk space (SSD preferred)
* Network
    * One virtual bridge exclusively for the VMs being deployed today
    * An additional virtual bridge allowing one to-be-deployed VM to register one static IPv4 address to communicate with the operator machine and a WAN-interfacing default gateway

##### Operator Machine

We assume that the operator machine is to some degree akin to a typical Rocky Linux 9.4 installation-- any operating system that can run `python3.11`, `terraform`, and a `bash`-like shell should suffice, but the instructions provided for installing requirements on this host will assume at least that you are on a modern `dnf`-managed system with repositories providing `python3.11` packages enabled.

###### Python3.11 Installation

```bash
sudo dnf install -y python3.11 python3.11-venv
```
Next, initialize your virtualenv in the root of this project:
```bash
python3.11 -m venv venv
source venv/bin/activate
pip install --require-virtualenv -r requirements.txt
```

###### Terraform Installation

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

## Getting Started

### Prepare VM template

Acquire an interactive terminal session to your Host Machine, with appropriate access to the `qm` utility (`root` by default)

Please note that the `${localdisk}` is for illustrative purposes and should be replaced by the name of the storage pool of your choice on the Host Machine.

```bash
wget https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base-9.4-20240609.1.x86_64.qcow2 /tmp/rocky9-base.qcow2
qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm set 9000 --scsi0 ${localdisk}:0,import-from=/tmp/rocky9-base.qcow2
qm set 9000 --ide2 ${localdisk}:cloudinit
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```
Next, locate VM 9000 in the Proxmox VE webUI, and under "Cloud-Init" set "Upgrade packages" to "No".  Then, go to "Options" and change the template's name to "rocky9-base"

### Create Proxmox API token

Log into the Proxmox VE webui on port 8006 of your Host Machine and perform the following:

* When in "Server View", click on "Datacenter" at the top of the left pane
* In the view container to the right, locate the "API Tokens" tab under "Permissions" in the left pane
* Click "Add" and select a user with appropriate privileges to create, clone and manage VMs (root by default)
* Choose any name for "Token ID", for example the name of your virtual cluster
* Hit add and note the Token ID and Secret shown on the next screen.  These will need to be put into variable files in the next section.

### Define variables

Run the following commands from the root of the project

```bash
cp terraform/vars.tf.example terraform/vars.tf
cp ansible/vars.yml.example ansible/vars.yml
```

Navigate to the files created and ensure they contain the correct values specific to your installation (API key, subnet, cluster_ip, name, etc).

**You will also need to update the following line in `ansible/sshconfig` to match your chosen cluster_ip**

### Creating the virtual cluster

**The following command blocks in child sections are expected to be executed at the root of this project**

#### Provision VM infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Once Terraform has completed its tasks and returned to the shell, take a quick coffee break so that the first VM has a chance to boot up and get situated before running the Ansible playbook in the next section.

#### Deploy cluster software

```bash
source venv/bin/activate
cd ansible
ansible-galaxy collection install community.general
ansible-playbook plays/cluster-init.yml
```

If the playbook returns an error saying it couldn't connect to the target in the "Allow IPv4 forwarding" task, the networking VM (which boots when the Terraform provisioning is finished) has not yet become ready for connections, in which case you should take a coffee break before attempting to run the playbook again.

## Accessing the virtual cluster

The following command will land you on a login node inside the virtual cluster 
```bash
ssh -F ansible/sshconfig cluster_login
```

## Cluster file storage

The virtual cluster has three mountpoints shared between nodes:
* `/pkgs` - unused, for distributing packages from a build node
* `/apps` - unused, for housing centrally-installed applications
* `/misc` - general storage for job data and miscellaneous

When submitting a job, it is recommended that you use `/misc` to store your job scripts and data.

## Wrapping up

To tear down the virtual cluster, run the following:

```bash
cd terraform
terraform destroy
```

## Future Considerations

A continuation of this "toy slurm cluster" exercise may optionally involve the following enchancements:

* Distributed `/home`
* EasyBuild & Lmod central `/apps`
* QEMU/libvirt Terraform provider option
* NAT-less networking option
* DNS
* stateless PXE boot
* LDAP
* Foreign networked storage
* Metrics & Monitoring
* DCIM