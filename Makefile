# Disable builtin rules and variables since they aren't used
# This makes the output of "make -d" much easier to follow and speeds up evaluation
# NB you can use make --print-data-base --dry-run to troubleshoot this Makefile.
MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --no-builtin-variables

# Normal (libvirt and VirtualBox) images
IMAGES+= windows-2019
IMAGES+= windows-2019-uefi
IMAGES+= windows-2022
IMAGES+= windows-2022-uefi
IMAGES+= windows-10-1809
IMAGES+= windows-10-20h2
IMAGES+= windows-11-21h2
IMAGES+= windows-11-21h2-uefi

# Images supporting Hyper-V
HYPERV_IMAGES+= windows-2019
HYPERV_IMAGES+= windows-2022
HYPERV_IMAGES+= windows-10-1809
HYPERV_IMAGES+= windows-10-20h2
HYPERV_IMAGES+= windows-11-21h2

# Images supporting vSphere
VSPHERE_IMAGES+= windows-2019
VSPHERE_IMAGES+= windows-2019-uefi
VSPHERE_IMAGES+= windows-2022
VSPHERE_IMAGES+= windows-2022-uefi
VSPHERE_IMAGES+= windows-10-1809

# Generate build-* targets
VIRTUALBOX_BUILDS= $(addsuffix -virtualbox,$(addprefix build-,$(IMAGES)))
LIBVIRT_BUILDS= $(addsuffix -libvirt,$(addprefix build-,$(IMAGES)))
HYPERV_BUILDS= $(addsuffix -hyperv,$(addprefix build-,$(HYPERV_IMAGES)))
VSPHERE_BUILDS= $(addsuffix -vsphere,$(addprefix build-,$(VSPHERE_IMAGES)))

.PHONY: help $(VIRTUALBOX_BUILDS) $(LIBVIRT_BUILDS) $(VSPHERE_BUILDS)

help:
	@echo Type one of the following commands to build a specific windows box.
	@echo
	@echo VirtualBox Targets:
	@$(addprefix echo make ,$(addsuffix ;,$(VIRTUALBOX_BUILDS)))
	@echo
	@echo libvirt Targets:
	@$(addprefix echo make ,$(addsuffix ;,$(LIBVIRT_BUILDS)))
	@echo
	@echo Hyper-V Targets:
	@$(addprefix echo make ,$(addsuffix ;,$(HYPERV_BUILDS)))
	@echo
	@echo vSphere Targets:
	@$(addprefix echo make ,$(addsuffix ;,$(VSPHERE_BUILDS)))

# Target specific pattern rules for build-* targets
$(VIRTUALBOX_BUILDS): build-%-virtualbox: %-amd64-virtualbox.box
$(LIBVIRT_BUILDS): build-%-libvirt: %-amd64-libvirt.box
$(HYPERV_BUILDS): build-%-hyperv: %-amd64-hyperv.box
$(VSPHERE_BUILDS): build-%-vsphere: %-amd64-vsphere.box

%-amd64-virtualbox.box: %.pkr.hcl %/autounattend.xml Vagrantfile.template *.ps1 drivers
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-virtualbox-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-virtualbox-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=virtualbox-iso.$*-amd64 -on-error=abort $*.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-amd64-virtualbox-packer.log \
		>$*-amd64-virtualbox-windows-updates.log
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-amd64 $@

%-amd64-libvirt.box: %.pkr.hcl %/autounattend.xml Vagrantfile.template *.ps1 drivers
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-libvirt-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-libvirt-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.$*-amd64 -on-error=abort $*.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-amd64-libvirt-packer.log \
		>$*-amd64-libvirt-windows-updates.log
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-amd64 $@

%-amd64-hyperv.box: %.pkr.hcl Vagrantfile.template *.ps1
	rm -f $@
	mkdir -p tmp
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-hyperv-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-hyperv-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.$*-amd64 -on-error=abort $*.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-amd64-hyperv-packer.log \
		>$*-amd64-hyperv-windows-updates.log
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-amd64 $@

%-uefi-amd64-virtualbox.box: %-uefi.pkr.hcl %-uefi/autounattend.xml Vagrantfile-uefi.template *.ps1 drivers
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-virtualbox-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-virtualbox-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=virtualbox-iso.$*-uefi-amd64 -on-error=abort $*-uefi.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-uefi-amd64-virtualbox-packer.log \
		>$*-uefi-amd64-virtualbox-windows-updates.log
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-uefi-amd64 $@

%-uefi-amd64-libvirt.box: %-uefi.pkr.hcl %-uefi/autounattend.xml Vagrantfile-uefi.template *.ps1 drivers
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-libvirt-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-libvirt-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.$*-uefi-amd64 -on-error=abort $*-uefi.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-uefi-amd64-libvirt-packer.log \
		>$*-uefi-amd64-libvirt-windows-updates.log
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-uefi-amd64 $@

tmp/windows-10-%-vsphere/autounattend.xml: windows-10/autounattend.xml
	mkdir -p "$$(dirname $@)"
	@# add the vmware tools iso to the drivers search path.
	@# NB we cannot have this in the main autounattend.xml because windows
	@#    will fail to install when the virtualbox guest additions iso is in E:
	@#    with the error message:
	@#        Windows Setup could not install one or more boot-critical drivers.
	@#        To install Windows, make sure that the drivers are valid, and
	@#        restart the installation.
	sed -E 's,(.+)</DriverPaths>,\1    <PathAndCredentials wcm:action="add" wcm:keyValue="2"><Path>E:\\</Path></PathAndCredentials>\n\0,g' $< >$@

tmp/%-vsphere/autounattend.xml: %/autounattend.xml
	mkdir -p "$$(dirname $@)"
	@# add the vmware tools iso to the drivers search path.
	@# NB we cannot have this in the main autounattend.xml because windows
	@#    will fail to install when the virtualbox guest additions iso is in E:
	@#    with the error message:
	@#        Windows Setup could not install one or more boot-critical drivers.
	@#        To install Windows, make sure that the drivers are valid, and
	@#        restart the installation.
	sed -E 's,(.+)</DriverPaths>,\1    <PathAndCredentials wcm:action="add" wcm:keyValue="2"><Path>E:\\</Path></PathAndCredentials>\n\0,g' $< >$@

%-amd64-vsphere.box: %-vsphere.pkr.hcl tmp/%-vsphere/autounattend.xml Vagrantfile.template *.ps1
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-vsphere-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-amd64-vsphere-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.$*-amd64 -on-error=abort $*-vsphere.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-amd64-vsphere-packer.log \
		>$*-amd64-vsphere-windows-updates.log
	@echo 'Removing all cd-roms (except the first)...'
	govc device.ls "-vm.ipath=$$VSPHERE_TEMPLATE_IPATH" \
		| grep ^cdrom- \
		| tail -n+2 \
		| awk '{print $$1}' \
		| xargs -L1 govc device.remove "-vm.ipath=$$VSPHERE_TEMPLATE_IPATH"
	@echo 'Converting to template...'
	govc vm.markastemplate "$$VSPHERE_TEMPLATE_IPATH"
	@echo 'Creating the local box file...'
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-amd64 $@

%-uefi-amd64-vsphere.box: %-uefi-vsphere.pkr.hcl tmp/%-uefi-vsphere/autounattend.xml Vagrantfile-uefi.template *.ps1
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-vsphere-packer-init.log \
		packer init $*.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$*-uefi-amd64-vsphere-packer.log PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.$*-uefi-amd64 -on-error=abort $*-uefi-vsphere.pkr.hcl
	./get-windows-updates-from-packer-log.sh \
		$*-uefi-amd64-vsphere-packer.log \
		>$*-uefi-amd64-vsphere-windows-updates.log
	@echo 'Removing all cd-roms (except the first)...'
	govc device.ls "-vm.ipath=$$VSPHERE_TEMPLATE_IPATH" \
		| grep ^cdrom- \
		| tail -n+2 \
		| awk '{print $$1}' \
		| xargs -L1 govc device.remove "-vm.ipath=$$VSPHERE_TEMPLATE_IPATH"
	@echo 'Converting to template...'
	govc vm.markastemplate "$$VSPHERE_TEMPLATE_IPATH"
	@echo 'Creating the local box file...'
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f $*-uefi-amd64 $@

# All the Windows 10 versions depend on the same autounattend.xml
# This allows the use of pattern rules by satisfying the prerequisite
.PHONY: \
	windows-10-1809/autounattend.xml \
	windows-10-20h2/autounattend.xml

drivers:
	@# see https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html
	@# see https://github.com/virtio-win/virtio-win-guest-tools-installer
	@# see https://github.com/virtio-win/virtio-win-pkg-scripts
	if [ ! -f drivers/virtio-win-guest-tools.exe ]; then \
	  mkdir -p drivers.tmp; \
	  wget -P drivers.tmp https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.190-1/virtio-win-0.1.190.iso; \
	  7z x -odrivers.tmp drivers.tmp/virtio-win-*.iso; \
	  mv drivers.tmp drivers; \
	fi;
