{ config, libs, pkgs, ... }: {
  imports = [
    <agenix/modules/age.nix>

    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect  
  ];

  system.stateVersion = "23.05";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking.hostName = "hacettepeoyt-vflower";
  networking.domain = "";
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 25565 ];
  networking.firewall.allowedUDPPorts = [ 19132 ];

  programs.mosh.enable = true;
  programs.zsh.enable = true;

  services.openssh.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "hacettepeoyt_letsencrypt@div72.xyz";
  };

  services.nginx = {
    enable = true;

    virtualHosts."wiki.ozguryazilimhacettepe.com" = {
      forceSSL = true;
      enableACME = true;
      root = "/srv/http/wiki.ozguryazilimhacettepe.com";
    };
  };

  systemd.services.minecraft-server = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    startLimitBurst = 3;
    startLimitIntervalSec = 60;

    serviceConfig = {
      ExecStart = "/etc/profiles/per-user/minecraft/bin/minecraft-server";

      Restart = "always";
      WorkingDirectory = "/srv/minecraft";
      User = "minecraft";
      Group = "minecraft";
      Type = "simple";

      LockPersonality = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0007";
    };
  };

  age.secrets = builtins.listToAttrs (map (user: { name = "passwd-${user}"; value = { file = ./secrets/passwd/${user}.age; }; }) (builtins.filter (user: config.users.users."${user}".isNormalUser) (builtins.attrNames config.users.users)));
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [ ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVb2l/23ykDnfhO5VrkCQaycfF9oCo1Jig/JeG86w//'' ];
  users.users = {
    div72 = {
      isNormalUser = true;
      passwordFile = config.age.secrets.passwd-div72.path;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      packages = [ ]; # packages managed by home-manager
      openssh.authorizedKeys.keys = [ ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVb2l/23ykDnfhO5VrkCQaycfF9oCo1Jig/JeG86w//'' ];
    };

    ikolomiko = {
      isNormalUser = true;
      passwordFile = config.age.secrets.passwd-ikolomiko.path;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      packages = [ pkgs.git pkgs.screen pkgs.vim pkgs.eza pkgs.htop ];
      openssh.authorizedKeys.keys = [ ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6fYwAAYEKncSRGjh+xVE8toRB4ztmBFDFX2wShZAPw'' ];
    };

    LinoxGH = {
      isNormalUser = true;
      passwordFile = config.age.secrets.passwd-LinoxGH.path;
      extraGroups = [ "minecraft" ];
      openssh.authorizedKeys.keys = [ ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqibdeU7gLufY1Hs2AG9V1KjbhSDTM1C1Q6zRrB1h5D'' ];
    };

    f1nch = {
      isNormalUser = true;
      passwordFile = config.age.secrets.passwd-f1nch.path;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      packages = [ pkgs.git pkgs.vim ];
      openssh.authorizedKeys.keys = [ ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKjtQ/SbNBCTSWimPetOw4veFxXANwPNdprjFiEQa2O'' ];
    };

    minecraft = {
      isSystemUser = true;
      home = "/srv/minecraft";
      createHome = true;
      homeMode = "770";
      group = "minecraft";
      packages = [ pkgs.papermc ];
    };
  };

  users.groups.minecraft = { };

  security.sudo.extraRules = [
    {
      groups = [ "minecraft" ];
      commands = [
        "/run/current-system/sw/bin/systemctl start minecraft-server"
        "/run/current-system/sw/bin/systemctl stop minecraft-server"
        "/run/current-system/sw/bin/systemctl restart minecraft-server"
        "/run/current-system/sw/bin/journalctl -eu minecraft-server"
      ];
    }
  ];

  nixpkgs.overlays = [
    ( final: prev: {
        papermc = prev.papermc.overrideAttrs (finalAttrs: previousAttrs: {
          version = "1.20.2.234";

          src =
            let
              mcVersion = prev.lib.versions.pad 3 finalAttrs.version;
              buildNum = builtins.elemAt (prev.lib.splitVersion finalAttrs.version) 3;
            in
            prev.fetchurl {
              url = "https://papermc.io/api/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
              hash = "sha256-fR7Dq09iFGVXodQjrS7Hg4NcrKPJbNg0hexU520JC6c=";
            };
        });
    })
  ];
}
