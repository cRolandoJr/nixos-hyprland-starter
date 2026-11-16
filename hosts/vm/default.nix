{
  config,
  lib,
  pkgs,
  modulesPath,
  username,
  starterSource,
  ...
}:

{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
    ../../modules/workstation.nix
  ];

  networking.hostName = "starter-vm";
  system.stateVersion = "25.11";

  # Cuenta pública de laboratorio; no importar este módulo en una máquina real.
  users.users.${username}.initialPassword = "laboratorio";

  virtualisation = {
    memorySize = 4096;
    cores = 2;
    diskSize = 32768;
    diskImage = "./starter-vm.qcow2";
    graphics = true;
    useBootLoader = true;
    useEFIBoot = true;
    forwardPorts = [ ];

    # Solo el store del anfitrión y en lectura. No se comparte su home.
    sharedDirectories = lib.mkForce {
      nix-store = {
        source = builtins.storeDir;
        target = "/nix/.ro-store";
        writable = false;
      };
    };

    qemu.options = [
      "-vga none"
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };

  # El clon de trabajo es una copia del snapshot incluido en el build, no un
  # enlace al directorio del anfitrión. Se conserva en los siguientes arranques.
  system.activationScripts.starterRepo = {
    deps = [ "users" ];
    text =
      let
        home = config.users.users.${username}.home;
        group = config.users.users.${username}.group;
      in
      ''
        if [ ! -e "${home}/projects/nix-config" ]; then
          ${pkgs.coreutils}/bin/mkdir -p "${home}/projects"
          ${pkgs.coreutils}/bin/cp -R ${starterSource}/. "${home}/projects/nix-config"
          ${pkgs.coreutils}/bin/chmod -R u+w "${home}/projects/nix-config"
          ${pkgs.coreutils}/bin/chown -R ${username}:${group} "${home}/projects"
        fi
      '';
  };
}
