{ hostname, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/workstation.nix
  ];

  networking.hostName = hostname;

  # Valor inicial heredado del proyecto de origen; revisar antes de la primera
  # instalación. Una vez instalado, no cambiar por actualizar nixpkgs.
  system.stateVersion = "25.11";

  services.openssh = {
    # Acceso remoto opt-in: configurar una clave antes de habilitarlo.
    enable = false;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # No importar gpu-amd ni el disco de Victus: pertenecen a otra máquina.
}
