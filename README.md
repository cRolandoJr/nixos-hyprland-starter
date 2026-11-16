# NixOS Hyprland Starter

Una base personalizable de NixOS con Hyprland, Home Manager y dotfiles incluidos.
Preparada a partir de mi escritorio y probada mediante una instalación
manual en VM. Cada persona mantiene su configuración y hardware en su propia copia.

## Instalar

Seguir la **[guía de instalación completa](docs/INSTALACION.md)** desde la ISO:
UEFI, EFI + Btrfs sin cifrado, subvolúmenes, usuario, instalación, SSH y escritorio.
El particionado de la guía reemplaza un disco completo; no es una receta de dual boot.

```bash
git clone https://github.com/cRolandoJr/nixos-hyprland-starter.git
```

Antes de construir, cambiar `personal.nix`, generar el hardware del equipo destino
y resolver los bloqueos de `hosts/equipo/hardware.nix` y `disk.nix` siguiendo la guía.
No ejecutar un rebuild de la plantilla sin adaptar. La ruta definitiva de la copia
instalada es `~/projects/nix-config`, utilizada por los enlaces de Home Manager.

## Qué incluye

- Hyprland, Waybar, Eww, mako, rofi y configuración de terminal/editor.
- Ryogami y fondos en `dotfiles/Wallpapers`.
- Gaming: Steam y herramientas de rendimiento.
- Virtualización: libvirt, QEMU/KVM, virt-manager y Podman.
- SSH habilitado con contraseña para usuarios y acceso root por SSH deshabilitado.

La selección de módulos compartidos vive en `modules/workstation.nix`. Los datos
de usuario y hostname están en `personal.nix`; la configuración de Home Manager,
en `home/user.nix`. Al cambiar hostname, renombrar también la carpeta de host.

## Estado de verificación

Instalación guiada comprobada en VM x86_64 con UEFI, QXL sin OpenGL, 4 GiB de RAM
más swap temporal durante la instalación y disco virtual de 40 GiB. Arrancaron
Hyprland y el escritorio; se verificaron SSH, selector de fondos y ausencia de
unidades fallidas en la comprobación realizada. No se validaron gaming, virtualización
anidada ni GPU, Wi-Fi o suspensión de las laptops destinatarias.

`starter-vm` es una definición experimental de VM automática, ajena al procedimiento
manual probado. Para instalar, usar el output definido por el hostname personal.

La guía documenta también los fallos observados y cómo se diagnosticaron. La
[procedencia](docs/origen.md) conserva el historial de preparación.

## Personalización y actualizaciones

Crear un fork si se desean mantener cambios propios en GitHub. Mantener `flake.lock`
para reproducir las dependencias y revisar sus cambios antes de actualizar.
No subir UUID ni claves privadas de otras personas. Las generaciones NixOS no
revierten los dotfiles editables fuera del store: respaldarlos y versionarlos.

## Atribuciones y recursos

Se conservan las licencias presentes en los componentes incorporados, incluida la
licencia del selector en `pkgs/ryogami/wall-ui/LICENSE`. Los wallpapers incluyen
recursos de terceros; su inclusión no cambia sus derechos ni implica que tengan
una licencia común. No se declara una licencia global que sustituya las originales.
