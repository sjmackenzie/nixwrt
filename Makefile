# WARNING: This Makefile is my personal attempt to make building
# my personal NixWRT images more personally convenient for me (personally).
# It does not attempt to address the general questions of
# "where should we keep secrets and how do we get them into nix-build attributes"
# and should not be considered good practice, except perhaps[*] by accident


# [*] even that's unlikely

image?=phramware
SSID?=telent1
ssh_public_key_file?=/etc/ssh/authorized_keys.d/$(USER)
NIX_BUILD=nix-build --show-trace \
 -I nixpkgs=../nixpkgs -I nixwrt=./nixwrt -A $(image)

# ssh host keys are generated on the build system and then copied to
# the target.  Unless you want to be confronted with "Host key
# verification failed" messages from ssh every time you reflash, you
# probably shouldn't be deleting them

# From a security POV this is suboptimal as it means the device's secret
# keys are all compromised as soon as the build machine is, and we
# would be better to try and generate a host key on first boot then somehow
# notify that OOB to the connecting user, but as we don't in general
# know of any provision/channel for doing that, this is not a problem
# I have yet confronted.

.PRECIOUS: %-host-key

%-host-key:
	ssh-keygen -P '' -t rsa -f $@ -b 2048

extensino/phramware.bin: ATTRS=--argstr ssid $(SSID) --argstr psk $(PSK) 

%/phramware.bin: examples/%.nix %-host-key 
	$(NIX_BUILD) \
	 $(ATTRS) \
	 --argstr myKeys "`cat $(ssh_public_key_file) `" \
	 --argstr sshHostKey "`cat $(@D)-host-key`" \
	 $< -o $(@D)

%/firmware.bin: image=firmware
%/firmware.bin: examples/%.nix %-host-key 
	$(NIX_BUILD) \
	 $(ATTRS) \
	 --argstr myKeys "`cat $(ssh_public_key_file) `" \
	 --argstr sshHostKey "`cat $(@D)-host-key`" \
	 $< -o $(@D)
