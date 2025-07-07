terraform {
    required_version = ">= 0.13"
    required_providers {
        proxmox = {
            source = "telmate/proxmox"
            version = "3.0.1-rc3"
        }
    }
}

provider "proxmox" {
    pm_api_url          = "https://192.168.1.42:8006/api2/json"
    pm_api_token_id     = var.proxmox_token_id
    pm_api_token_secret = var.proxmox_token_secret
    pm_tls_insecure     = true
    pm_parallel         = 1
}

resource "proxmox_vm_qemu" "net-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 1
    name    = "${var.cluster_name}-net-${count.index + 1}"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 2048
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusternet"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.254.${count.index + 1}/16"
    ipconfig1 = "ip=${var.cluster_ip},gw=${var.cluster_gw}"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    network {
        model = "virtio"
        bridge = "vmbr0"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "store-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 1
    name    = "${var.cluster_name}-store-${count.index + 1}"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 4
    sockets     = 1
    cpu         = "host"
    memory      = 4096
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusterstore"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.253.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
        virtio {
            virtio0 {
                disk {
                    size = 200
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                    iothread = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "build-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 0
    name    = "${var.cluster_name}-build-${count.index + 1}"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 4
    sockets     = 1
    cpu         = "host"
    memory      = 8192
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusterbuild"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.252.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "dbd-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 1
    name    = "${var.cluster_name}-dbd"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 4096
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusterdbd"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.251.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "head-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 1
    name    = "${var.cluster_name}-head"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 4096
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusterhead"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.250.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "compute-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 4
    name    = "${var.cluster_name}-compute-${count.index + 1}"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 4096
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clustercompute"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.1.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}

resource "proxmox_vm_qemu" "login-vm" {
    target_node = var.proxmox_target_host

    clone = "rocky9-base"

    count   = 1
    name    = "${var.cluster_name}-login-${count.index + 1}"
    
    vm_state = "stopped"

    bios        = "seabios"
    agent       = 1
    os_type     = "cloud-init"
    cores       = 2
    sockets     = 1
    cpu         = "host"
    memory      = 4096
    numa        = true
    hotplug     = "network,disk,cpu,memory,usb"
    scsihw      = "virtio-scsi-pci"
    boot        = "c"
    bootdisk    = "scsi0"
    tags        = "clusterlogin"
    pool        = var.cluster_name

    sshkeys = var.ssh_pubkeys

    ipconfig0 = "ip=10.42.0.${count.index + 1}/16,gw=10.42.254.1"
    nameserver = "1.1.1.1"

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = var.proxmox_storage_pool
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = 10
                    cache = "writeback"
                    storage = var.proxmox_storage_pool
                    discard = true
                }
            }
        }
    }

    network {
        model = "virtio"
        bridge = "vmbr2"
    }

    lifecycle {
        ignore_changes = [
            network,
        ]
    }

    serial {
        id = 0
        type = "socket"
    }

    vga {
        type = "serial0"
    }
}