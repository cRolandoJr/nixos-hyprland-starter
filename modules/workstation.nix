# Perfil compartido por los equipos físicos y la VM de laboratorio.
{
  imports = [
    ./base.nix
    ./boot.nix
    ./network.nix
    ./audio.nix
    ./fonts.nix
    ./desktop-hyprland.nix
    ./gaming.nix
    ./virtualisation.nix
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
