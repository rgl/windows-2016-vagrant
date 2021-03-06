variable "disk_size" {
  type    = string
  default = "61440"
}

variable "iso_url" {
  type    = string
  default = "windows-2022-Windows_InsiderPreview_Server_vNext_en-us_20303.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:7e7c1c5a25f8526decb67b7c162bec2d3dab5cedaf3dfb31d874f5bafdac0029"
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

variable "vagrant_box" {
  type = string
}

source "qemu" "windows-2022-amd64" {
  accelerator = "kvm"
  cpus        = 2
  memory      = 4096
  qemuargs = [
    ["-cpu", "host"],
    ["-soundhw", "hda"],
    ["-usbdevice", "tablet"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  disk_interface = "virtio"
  disk_size      = var.disk_size
  floppy_files = [
    "windows-2022/autounattend.xml",
    "winrm.ps1",
    "drivers/vioserial/2k19/amd64/*.cat",
    "drivers/vioserial/2k19/amd64/*.inf",
    "drivers/vioserial/2k19/amd64/*.sys",
    "drivers/viostor/2k19/amd64/*.cat",
    "drivers/viostor/2k19/amd64/*.inf",
    "drivers/viostor/2k19/amd64/*.sys",
    "drivers/NetKVM/2k19/amd64/*.cat",
    "drivers/NetKVM/2k19/amd64/*.inf",
    "drivers/NetKVM/2k19/amd64/*.sys",
    "drivers/qxldod/2k19/amd64/*.cat",
    "drivers/qxldod/2k19/amd64/*.inf",
    "drivers/qxldod/2k19/amd64/*.sys",
  ]
  format           = "qcow2"
  headless         = true
  http_directory   = "."
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_timeout    = "4h"
}

source "virtualbox-iso" "windows-2022-amd64" {
  cpus      = 2
  memory    = 4096
  disk_size = var.disk_size
  floppy_files = [
    "windows-2022/autounattend.xml",
    "winrm.ps1",
  ]
  guest_additions_interface = "sata"
  guest_additions_mode      = "attach"
  guest_os_type             = "Windows2019_64"
  hard_drive_interface      = "sata"
  headless                  = true
  iso_url                   = var.iso_url
  iso_checksum              = var.iso_checksum
  iso_interface             = "sata"
  shutdown_command          = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  vboxmanage = [
    ["storagectl", "{{ .Name }}", "--name", "IDE Controller", "--remove"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vboxsvga"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--usb", "on"],
    ["modifyvm", "{{ .Name }}", "--mouse", "usbtablet"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype2", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype3", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nictype4", "82540EM"],
  ]
  communicator   = "winrm"
  winrm_username = "vagrant"
  winrm_password = "vagrant"
  winrm_timeout  = "4h"
}

source "hyperv-iso" "windows-2022-amd64" {
  cpus         = 2
  memory       = 4096
  generation   = 2
  boot_command = ["<up><wait><up><wait><up><wait><up><wait><up><wait>"]
  boot_order   = ["SCSI:0:0"]
  boot_wait    = "1s"
  cd_files = [
    "windows-2022-uefi/autounattend.xml",
    "winrm.ps1",
  ]
  disk_size         = var.disk_size
  first_boot_device = "DVD"
  headless          = true
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  switch_name       = var.hyperv_switch_name
  temp_path         = "tmp"
  vlan_id           = var.hyperv_vlan_id
  shutdown_command  = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator      = "winrm"
  winrm_username    = "vagrant"
  winrm_password    = "vagrant"
  winrm_timeout     = "4h"
}

build {
  sources = [
    "source.qemu.windows-2022-amd64",
    "source.virtualbox-iso.windows-2022-amd64",
    "source.hyperv-iso.windows-2022-amd64",
  ]

  provisioner "powershell" {
    script = "disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    inline = ["Uninstall-WindowsFeature Windows-Defender"]
  }

  provisioner "powershell" {
    only   = ["virtualbox-iso.windows-2022-amd64"]
    script = "virtualbox-prevent-vboxsrv-resolution-delay.ps1"
  }

  provisioner "powershell" {
    only   = ["qemu.windows-2022-amd64"]
    script = "provision-guest-tools-qemu-kvm.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "provision.ps1"
  }

  provisioner "windows-update" {
  }

  provisioner "powershell" {
    script = "enable-remote-desktop.ps1"
  }

  provisioner "powershell" {
    script = "provision-openssh.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    script = "provision-cloudbase-init.ps1"
  }

  provisioner "powershell" {
    script = "eject-media.ps1"
  }

  provisioner "powershell" {
    script = "optimize.ps1"
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
