{
  # Reemplazar por el diseño aprobado de disko tras identificar el disco y verificar
  # el respaldo. No se selecciona ningún dispositivo ni se declara particionado.
  assertions = [
    {
      assertion = false;
      message = "hosts/equipo/disk.nix: falta definir el disco y particionado del equipo destino.";
    }
  ];
}
