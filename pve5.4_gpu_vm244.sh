#!/bin/bash

# Reference guides:
# https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
# https://pve.proxmox.com/wiki/Pci_passthrough
# https://pve.proxmox.com/wiki/Nested_Virtualization

# Remember to turn on SVM in BIOS and disable CSM

# Update packages
sed -i "s/deb/#deb/" /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve stretch pve-no-subscription" >> /etc/apt/sources.list
apt update
apt full-upgrade -y
pveam update

# Loading vfio-pci early
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# Bluescreen at boot since Windows 10 1803
echo "options kvm ignore_msrs=1" >> /etc/modprobe.d/kvm.conf

# Binding vfio-pci via device ID
echo "options vfio-pci ids=10de:1b81,10de:10f0 disable_vga=1" >> /etc/modprobe.d/vfio.conf

# Enable Nested Hardware-assisted Virtualization

#For AMD
#echo "options kvm-amd nested=1" > /etc/modprobe.d/kvm-amd.conf

#FOR INTEL
echo "options kvm-intel nested=Y" > /etc/modprobe.d/kvm-intel.conf


#REBOOT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


#PROVERKA
#modprobe -r kvm_intel
#modprobe kvm_intel  
#cat /sys/module/kvm_intel/parameters/nested
# Y !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Enabling IOMMU
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="amd_iommu=on iommu=pt video=efifb:off"/' /etc/default/grub
update-grub

# Blacklist the driver
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u -k all

cat > /etc/pve/qemu-server/244.conf <<- EOF
agent: 1
args: -cpu 'host,+kvm_pv_unhalt,+kvm_pv_eoi,hv_vendor_id=NV43FIX,kvm=off'
balloon: 0
bios: ovmf
bootdisk: scsi0
cores: 4
cpu: host,hidden=1,flags=+pcid,hv-vendor-id=proxmox
efidisk0: local-lvm:vm-244-disk-1,size=4M
hostpci0: 0a:00,pcie=1
machine: q35,kernel_irqchip=on
memory: 8192
name: test
net0: virtio=9E:93:73:1B:38:0D,bridge=vmbr0,firewall=1,queues=8
numa: 0
onboot: 0
ostype: win10
scsi0: local-lvm:vm-244-disk-0,iothread=1,size=32G
scsihw: virtio-scsi-single
smbios1: uuid=41e2ce8c-9b09-4f57-bb8c-d541c35f8736
sockets: 1
vmgenid: 7386ad26-ff94-458c-bf5f-ab968f8e6947
#hugepages: 2
EOF

reboot
