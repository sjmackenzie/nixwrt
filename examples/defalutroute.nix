# Status May 2019: builds, but missing some needed packages

{ targetBoard ? "ar750"
, ssid
, psk
, loghost ? "loghost"
, myKeys ? "ssh-rsa AAAAATESTFOOBAR dan@example.org"
, sshHostKey ? "----NOT A REAL RSA PRIVATE KEY---" }:
let nixwrt = (import <nixwrt>) { inherit targetBoard; }; in
with nixwrt.nixpkgs;
let
    baseConfiguration = {
      hostname = "defalutroute";
      webadmin = { allow = ["localhost" "192.168.8.0/24"]; };
      interfaces = {
        "eth0" = { } ;          # WAN
        "eth1" = { } ;
        "eth1.1" = {
          type = "vlan"; id = 2; parent = "eth1"; depends = []; # lan
          memberOf = "br0";
        };
        "wlan0" = {
          type = "hostap";
          ssid = "telent1";
          country_code = "US";
          channel = 9;
          wpa_psk = psk;
          hw_mode = "g";
          memberOf = "br0";
        };
        "wlan1" = {
          type = "hostap";
          ssid = "telent1";
          country_code = "US";
          channel = 36;
          wpa_psk = psk;
          hw_mode = "a";
#          debug = true;
#          logger_stdout = "-1";
#          logger_stdout_level = "2";
          memberOf = "br0";
        };
        "br0" = {
          type = "bridge";
          ipv4Address = "192.168.1.4/24";
        };
        lo = { ipv4Address = "127.0.0.1/8"; };
      };
      etc = { };
      users = [
        {name="root"; uid=0; gid=0; gecos="Super User"; dir="/root";
         shell="/bin/sh"; authorizedKeys = (stdenv.lib.splitString "\n" myKeys);}
      ];
      packages = [ ];
      filesystems = {} ;
    };

    wantedModules = with nixwrt.modules;
      [(_ : _ : _ : baseConfiguration)
       nixwrt.device.hwModule
       (sshd { hostkey = sshHostKey ; })
       busybox
       kernelMtd
       (switchconfig {
         name = "switch0";
         interface = "eth1";
         vlans = {
	         "1" = "0t 1 2 3 4";           # lan (0 is cpu)
	       };
       })
       haveged
#       (pppoe { options = { debug = ""; }; auth = "* * mysecret\n"; })
#       (syslog { inherit loghost; })
#       (ntpd { host = "pool.ntp.org"; })
#       (dhcpClient { interface = "eth0.2"; })
    ];

    in {
      firmware = nixwrt.firmware (nixwrt.mergeModules wantedModules);

      # phramware generates an image which boots from the "fake" phram mtd
      # device - required if you want to boot from u-boot without
      # writing the image to flash first
      phramware =
        let phram_ = (nixwrt.modules.phram {
              offset = "0xa00000"; sizeMB = "5";
            });
            m = wantedModules ++ [phram_];
        in nixwrt.firmware (nixwrt.mergeModules m);
    }
