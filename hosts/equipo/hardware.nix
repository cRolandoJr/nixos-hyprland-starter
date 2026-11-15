{
  # Reemplazar este módulo por el hardware verificado del equipo destino.
  # La aserción permite consultar opciones, pero impide construir una instalación
  # presentando este borrador como hardware ya configurado.
  assertions = [
    {
      assertion = false;
      message = "hosts/equipo/hardware.nix: falta configurar el hardware del equipo destino.";
    }
  ];
}
