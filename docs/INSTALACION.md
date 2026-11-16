# Instalar NixOS con el escritorio compartido

Guía basada en la instalación guiada realizada por Rolando el 14 de noviembre de
2026. Destino probado: VM x86_64, UEFI, disco de 40 GiB, 4 GiB de RAM, QXL sin
OpenGL. Se comprobó arranque desde disco, Hyprland, terminal, Waybar, acceso SSH,
selector de fondos y ausencia de unidades fallidas en esa comprobación.

## Alcance y preparación

Esta receta reemplaza un disco completo: GPT, EFI de 1 GiB y Btrfs en el resto,
sin LUKS, sin LVM y sin dual boot. No sirve para conservar particiones existentes.
En una laptop real, respaldar los datos y verificar su recuperación antes de borrar.
GPU, Wi-Fi, sonido, suspensión, gaming y virtualización requieren pruebas propias
en cada equipo; el éxito de la VM no acredita esas funciones.

Preparar una ISO oficial NixOS minimal x86_64 desde
[Descargas NixOS](https://nixos.org/download/), un USB de arranque o una VM y una
copia completa de este starter. Conservar `flake.lock`: la ISO proporciona las
herramientas de instalación, mientras el lock determina las dependencias del sistema.
No ejecutar `nix flake update` durante esta instalación inicial.

La copia local de preparación de Rolando se llama `nixos-hyprland-starter`.
La ruta definitiva instalada será `~/projects/nix-config`, porque Home Manager
apunta allí para sus dotfiles. El repositorio público es
[cRolandoJr/nixos-hyprland-starter](https://github.com/cRolandoJr/nixos-hyprland-starter).
La transferencia por SSH documentada abajo conserva el recorrido de la práctica.

Ejecutar los bloques por etapas y detenerse ante errores. No pegar la guía completa
como un script. Los comandos marcados «instalador» corren en el equipo destino
arrancado desde la ISO, no en la laptop que lo administra.

### Crear la VM de práctica

En virt-manager: crear máquina con medio local, seleccionar la ISO, asignar 2 CPU,
4096 MiB de RAM y un disco virtual nuevo de 40 GiB. Marcar personalización previa,
elegir UEFI x86_64 / OVMF sin Secure Boot y red `default` con NAT.

La combinación que permitió esta práctica fue vídeo QXL y pantalla Spice sin
OpenGL. Virtio 3D produjo pantalla negra; no se determinó su causa raíz.
QXL permitió arrancar el escritorio, pero no valida aceleración ni rendimiento.
No trasladar QXL a la configuración de una laptop física.

Comprobar que la lectora virtual tenga la ISO como medio. En la prueba, una lectora
vacía dejó el firmware en UEFI Shell. Desde el anfitrión se puede comprobar con:

```bash
virsh -c qemu:///system domblklist nixos-starter-lab --details
```

Si el CD-ROM muestra `-` como origen, insertar la ISO. Elegir la entrada normal del
instalador; LTS es una alternativa si el kernel normal no arranca correctamente.

## 1. Comprobar el entorno de instalación

En el instalador:

```bash
test -d /sys/firmware/efi && echo "Arranque UEFI confirmado"
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
ip -br address
curl -I https://cache.nixos.org
free -h
```

Exigir confirmación de UEFI, identificar el disco por tamaño/modelo/serial y
comprobar una respuesta HTTP satisfactoria. Si falta red, resolverla antes de seguir.
En Wi-Fi, consultar `command -v nmtui` y `command -v iwctl` para identificar qué
herramienta trae la ISO; la configuración de Wi-Fi no se practicó en esta VM.

### SSH al instalador, opcional

Desde la consola del instalador:

```bash
sudo passwd nixos
sudo systemctl start sshd
systemctl is-active sshd
ip -br address
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

En la laptop administradora, definir la IP real observada; este es el ejemplo de
la VM y se debe sustituir si cambia:

```bash
IP_DESTINO=192.168.122.123
ssh nixos@"$IP_DESTINO"
```

Comparar la huella presentada con la de la consola antes de aceptar. La contraseña
de `nixos` pertenece al entorno live; no configura al futuro usuario instalado.

## 2. Particionar el disco destino

En el instalador, elegir las tres rutas según `lsblk`. Este bloque corresponde
EXCLUSIVAMENTE al disco de la VM probado:

```bash
DISCO=/dev/vda
EFI=/dev/vda1
RAIZ=/dev/vda2
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS "$DISCO"
```

En NVMe, un ejemplo de nombres es `/dev/nvme0n1`, `/dev/nvme0n1p1` y
`/dev/nvme0n1p2`; en SATA puede ser `/dev/sda`, `/dev/sda1`, `/dev/sda2`.
Son ejemplos, no una detección automática. Sustituir las tres variables y verificar.
Las variables se pierden al cerrar la sesión: volver a definirlas si se reconecta.

El siguiente comando BORRA la tabla de particiones del disco seleccionado.
Continuar solamente tras confirmar destino, respaldo y reemplazo completo:

```bash
sudo parted --script "$DISCO" -- \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1025MiB \
  set 1 esp on \
  mkpart primary btrfs 1025MiB 100%
sudo parted "$DISCO" print
lsblk "$DISCO"
```

Esperado: partición 1 de 1 GiB con marca ESP y partición 2 con el espacio restante.
`mkpart` define límites; todavía no crea los sistemas de archivos.

## 3. Formatear, crear subvolúmenes y montar

En el instalador, estos comandos borran el contenido de las particiones elegidas:

```bash
sudo mkfs.fat -F 32 -n EFI "$EFI"
sudo mkfs.btrfs -L nixos "$RAIZ"
sudo mount "$RAIZ" /mnt
sudo btrfs subvolume create /mnt/@root
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume list /mnt
sudo umount /mnt
```

Usar `sudo`: durante la práctica, el formateo Btrfs sin privilegios falló al
inspeccionar el dispositivo. No responder a ese error agregando `-f` a ciegas.

```bash
sudo mount -o subvol=@root,compress=zstd "$RAIZ" /mnt
sudo mkdir -p /mnt/{boot,home,nix}
sudo mount -o subvol=@home,compress=zstd "$RAIZ" /mnt/home
sudo mount -o subvol=@nix,compress=zstd "$RAIZ" /mnt/nix
sudo mount -o fmask=0077,dmask=0077 "$EFI" /mnt/boot
findmnt -R /mnt -o TARGET,SOURCE,FSTYPE,OPTIONS
```

`/mnt` representa la futura raíz `/`. Los tres subvolúmenes comparten el espacio
Btrfs; no son particiones de tamaño fijo y no crean backups ni snapshots automáticos.
Las máscaras EFI se incorporan desde el inicio para evitar el aviso de permisos
abiertos de `/boot` que apareció en la práctica con `0022`.

## 4. Generar la configuración de hardware

```bash
sudo nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix
sudo nano /mnt/etc/nixos/hardware-configuration.nix
```

Conservar los UUID y módulos detectados en ESTE equipo. No usar los UUID de Rolando
ni los de la VM de ejemplo. En cada entrada Btrfs, conservar su subvolumen y agregar
compresión; por ejemplo, para la raíz:

```nix
options = [ "subvol=@root" "compress=zstd" ];
```

Repetir para `@home` y `@nix`. En `fileSystems."/boot"`, dejar:

```nix
options = [ "fmask=0077" "dmask=0077" ];
```

```bash
nix-instantiate --parse /mnt/etc/nixos/hardware-configuration.nix > /dev/null && echo "Sintaxis correcta"
```

El generador no conservó la compresión en la práctica. Estado montado y
configuración persistente son dos cosas distintas: comprobar ambos.

## 5. Transferir y personalizar el starter

Para una instalación nueva, obtener la copia directamente en el instalador si
`git` está disponible:

```bash
git clone https://github.com/cRolandoJr/nixos-hyprland-starter.git ~/nixos-hyprland-starter
```

Si falta Git, obtenerlo temporalmente con `nix-shell -p git` y ejecutar el clone
dentro de ese shell. Alternativamente, usar la transferencia de la práctica que
sigue. Elegir una sola vía; no copiar encima de un clon existente.

En la laptop de Rolando, con la IP definida en esa terminal:

```bash
scp -r ~/projects/nixos-hyprland-starter nixos@"$IP_DESTINO":~/
```

Si se distribuye como carpeta por otro medio, colocar su contenido en
`~/nixos-hyprland-starter` dentro del instalador y continuar. No hace falta instalar
primero un escritorio ni instalar el NixOS predeterminado de la ISO.

En el instalador, copiar una sola vez a un destino que aún no exista:

```bash
sudo cp -a ~/nixos-hyprland-starter /mnt/etc/nixos/starter
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
  /mnt/etc/nixos/starter/hosts/equipo/hardware.nix
sudo nano /mnt/etc/nixos/starter/personal.nix
```

Ejemplo de datos iniciales, reemplazar el usuario por el propio antes de instalar:

```nix
{
  username = "nombre";
  hostname = "equipo";
}
```

Usar nombres simples en minúsculas. Para este primer recorrido se puede conservar
`equipo`. Si se cambia a `lenovo`, renombrar también `hosts/equipo` a `hosts/lenovo`
y usar `lenovo` en cada selector `#equipo` y ruta de host de esta guía.
El flake deriva la carpeta y el nombre del output de `hostname`.

En `home/user.nix`, reemplazar los ejemplos de identidad Git por los propios.
Revisar zona horaria y locale en `modules/base.nix`; el teclado y los monitores
se personalizan en los dotfiles de Hyprland. El hardware generado no resuelve
por sí solo todos los ajustes de GPU de cualquier laptop.

Abrir `hosts/equipo/disk.nix` en la copia del instalador y sustituir el bloqueo
inicial por este contenido completo:

```nix
{
  # Particionado manual: los montajes están definidos en hardware.nix.
}
```

No ejecutar disko: ya se particionó manualmente. Su módulo puede seguir importado
sin definir dispositivos. Los bloqueos de la plantilla obligan a adaptar cada destino.
No usar el output `starter-vm`: corresponde a otro experimento de VM automática.

El sistema instalado deja SSH desactivado. Esto no cambia el SSH opcional de la
ISO explicado antes. Para habilitarlo, seguir la sección SSH del paso 9 desde
una consola local; nunca copiar claves privadas al repositorio.

La carpeta de fondos se entrega sin imágenes de terceros. Copiar al menos una
imagen propia o con permisos comprobados dentro de `dotfiles/Wallpapers` si se
quiere probar el selector. Sin imágenes, el listado vacío es esperado.

Comprobar la carpeta y sus dos consumidores:

```bash
ls /mnt/etc/nixos/starter/dotfiles/Wallpapers
rg -n 'paths.wallpaper' /mnt/etc/nixos/starter/home/user.nix
```

Si `rg` no está en la ISO, leer esas líneas con el editor. Ambas rutas deben terminar
en `/projects/nix-config/dotfiles/Wallpapers`. Mayúsculas y minúsculas importan.

## 6. Evaluar y preparar memoria

En el instalador:

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  eval --raw \
  'path:/mnt/etc/nixos/starter#nixosConfigurations.equipo.config.system.build.toplevel.drvPath'
```

Esperado: una ruta `.drv`. Evaluar valida la receta; no demuestra construcción ni
arranque. Resolver las aserciones o errores antes de instalar. `path:` permite usar
esta carpeta aunque no se haya inicializado Git.

Con 4 GiB de RAM, la instalación fue terminada por el OOM killer. En esa VM se
resolvió con 4 GiB de swap temporal y menor paralelismo. Comprobar espacio primero:

```bash
free -h
df -h /mnt /mnt/nix
```

Para repetir el laboratorio de 4 GiB, crear la swap una sola vez:

```bash
sudo btrfs subvolume create /mnt/@swap
sudo btrfs filesystem mkswapfile --size 4G /mnt/@swap/install.swap
sudo swapon /mnt/@swap/install.swap
swapon --show
free -h
```

`@swap` aquí vive dentro de la raíz montada; no se añade a `fstab`. Es temporal.
No usar un archivo creado con `truncate` como sustituto de `mkswapfile` en Btrfs.
La swap ocupa espacio adicional y no garantiza que cualquier build quepa.

## 7. Instalar NixOS

```bash
sudo nixos-install \
  --root /mnt \
  --flake path:/mnt/etc/nixos/starter#equipo \
  --option experimental-features 'nix-command flakes' \
  --max-jobs 1 \
  --cores 1 \
  --option max-substitution-jobs 2
```

Esperar a `installation finished!`. Al final se establece la contraseña de root
del sistema instalado. No continuar con `nixos-enter` si la instalación falló.

Si aparece `Killed`, diagnosticar antes de repetir:

```bash
free -h
df -h /mnt /mnt/nix
sudo journalctl -k -b --no-pager -n 100
```

En la práctica, `Out of memory: Killed process ... (nix)` confirmó falta de RAM.
Después de resolver la causa, repetir `nixos-install`, sin formatear nuevamente;
los paquetes descargados se reutilizan. La VM descargó varios GiB y necesitó
bastante más espacio durante la instalación que el tamaño del repositorio.

## 8. Preparar usuario y dotfiles antes del primer arranque

En el instalador, definir el mismo usuario de `personal.nix`:

```bash
USUARIO=nombre
sudo nixos-enter --root /mnt -c "passwd $USUARIO"
sudo mkdir -p "/mnt/home/$USUARIO/projects"
sudo cp -a /mnt/etc/nixos/starter "/mnt/home/$USUARIO/projects/nix-config"
sudo nixos-enter --root /mnt -c "chown -R $USUARIO:users /home/$USUARIO/projects"
sudo nixos-enter --root /mnt -c "id $USUARIO; stat -c '%U:%G (%u:%g) %n' /home/$USUARIO/projects/nix-config/dotfiles"
```

Copiar solo una vez: repetir `cp` sobre un destino existente puede anidar carpetas.
La comprobación dentro del sistema instalado debe mostrar el dueño correcto.
Desde la ISO, el mismo UID puede aparecer como `nixos`; el nombre se resuelve
usando la base de usuarios del entorno desde el que se observa.

Home Manager usa enlaces fuera del store: el escritorio necesita esta copia física.
Desde ahora, mantener `~/projects/nix-config` como fuente de trabajo; la copia en
`/etc/nixos/starter` queda como referencia inicial y no se sincroniza sola.

Si se creó la swap temporal, retirarla después de finalizar la instalación:

```bash
sudo swapoff /mnt/@swap/install.swap
```

Solo si ese comando terminó correctamente:

```bash
sudo rm /mnt/@swap/install.swap
sudo btrfs subvolume delete /mnt/@swap
```

Si `swapoff` falla, no borrar el archivo activo. Resolver el error antes de continuar.

```bash
sync
sudo poweroff
```

Retirar el USB o expulsar la ISO de la lectora virtual (vaciar el medio no borra
el archivo ISO ni el disco virtual). Encender desde el disco; elegir Linux Boot
Manager si es necesario. Iniciar sesión con el usuario creado, no con `nixos`.

## 9. Verificar el sistema instalado

En una terminal del sistema nuevo:

```bash
whoami
hostname
nixos-version
findmnt /boot -o TARGET,FSTYPE,OPTIONS
findmnt -t btrfs -o TARGET,SOURCE,OPTIONS
systemctl --failed
systemctl --user --failed
hyprctl configerrors
```

Esperado: identidad elegida, máscaras EFI `0077`, subvolúmenes y compresión
correctos, cero unidades fallidas y ninguna salida de errores de Hyprland.
En la práctica se verificaron los servicios y Hyprland; la última comprobación
posterior al ajuste EFI no fue compartida, por lo que queda como checkpoint obligatorio.

Probar terminal, lanzador, red, audio, selector de fondos y apagar/reiniciar. En
laptops físicas, agregar Wi-Fi, brillo, suspensión/reanudación, pantalla externa y GPU.
No dar por probado Steam o KVM solo porque sus paquetes estén instalados.

### Fondos de escritorio

```bash
jq -r '.paths.wallpaper' \
  ~/.config/ryoku/ryogami.json \
  ~/.config/ryogami-wall/config.json
ls ~/projects/nix-config/dotfiles/Wallpapers
```

Las dos rutas deben coincidir con la carpeta. En la práctica, `wallpapers` frente
a `Wallpapers` dejó vacío el selector. Corregir nombre/rutas y aplicar el rebuild
si cambió `home/user.nix`. Después:

```bash
systemctl --user restart ryogami.service ryogami-surface.service
```

Abrir el selector y elegir una imagen: comprobar listado y aplicación del fondo.

### SSH y cambio de identidad tras instalar

SSH está desactivado por defecto. Para habilitarlo, editar el bloque existente
en `hosts/equipo/default.nix` y añadir la clave **pública** del cliente al usuario:

```nix
services.openssh = {
  enable = true;
  openFirewall = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };
};
users.users.nombre.openssh.authorizedKeys.keys = [
  "REEMPLAZAR_POR_LA_CLAVE_PUBLICA_COMPLETA"
];
```

Sustituir `nombre` por el usuario de `personal.nix` y el marcador por el contenido
real de la clave pública (por ejemplo `id_ed25519.pub`). No pegar la clave privada.
Aplicar el rebuild del paso 10 desde consola local, mantener esa consola abierta
y comprobar el acceso desde una segunda terminal antes de depender de SSH.
`openFirewall` abre el puerto SSH; habilitarlo sólo en la red prevista.

Con SSH habilitado:

```bash
systemctl is-active sshd
ip -br address
```

Desde otro equipo, usar `ssh nombre@IP`, sustituyendo ambos datos. `equipo` es el
hostname, no el usuario. Si aparece `REMOTE HOST IDENTIFICATION HAS CHANGED`,
verificar la huella desde la consola local del equipo instalado:

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Solo si coincide con la huella del aviso, en la laptop administradora:

```bash
ssh-keygen -R "$IP_DESTINO"
ssh nombre@"$IP_DESTINO"
```

Comparar nuevamente y aceptar la identidad nueva. No borrar todo `known_hosts`
ni desactivar la verificación. La IP puede mantenerse al cambiar del live al sistema
instalado, pero cada entorno tiene sus claves de host.

## 10. Cambios posteriores y recuperación

Editar la copia en `~/projects/nix-config`. Para usuario `nombre`, host `equipo`:

```bash
sudo nixos-rebuild switch \
  --flake path:/home/nombre/projects/nix-config#equipo \
  --max-jobs 1 --cores 1
```

Sustituir usuario/host según lo elegido. `switch` construye y activa; comprobar la
función cambiada después. Sudo solicita la contraseña del usuario también para
rebuild y limpieza de generaciones. Si se modificaron máscaras EFI, usar
`findmnt /boot`.
Si el montaje no refleja la configuración y el rebuild terminó bien, reiniciar y
volver a comprobar; no afirmar que se aplicó solo porque terminó el build.

Si un cambio impide arrancar, seleccionar una generación anterior en systemd-boot.
Si aún hay terminal administrativa, se puede intentar:

```bash
sudo nixos-rebuild switch --rollback
```

Este mecanismo no se ejercitó en esta VM. Revierte el sistema, no documentos ni
ediciones de dotfiles externos. Hacer respaldo de esos archivos y revisar el diff
antes de aplicar cambios. Si no hay generaciones útiles, arrancar la ISO, identificar
las particiones existentes y repetir SOLO los montajes del paso 3; nunca `mkfs` ni
`parted`. Desde ahí se puede inspeccionar o entrar con `nixos-enter --root /mnt`.

No subir hardware generado, contraseñas, claves SSH ni datos privados de otra
persona al starter común. Cada equipo mantiene su propia copia o fork y su hardware.
`system.stateVersion` no es la versión a actualizar: el starter conserva `25.11`
como base probada; no cambiarlo solo por actualizar NixOS.

## Evidencia, límites y referencias

La práctica confirmó instalación y arranque en VM mediante `nixos-install`,
rebuild posterior, SSH y fondos tras corregir el nombre de carpeta. El sistema
mostrado fue NixOS 26.11 con kernel 7.2.7; son datos de esa prueba, no promesas
para futuras actualizaciones del lock. Gaming y máquinas virtuales anidadas no
se probaron, ni se certificó compatibilidad de las laptops de los destinatarios.

Antes de publicar los recursos gráficos, revisar sus permisos de redistribución y
atribuciones: copiarlos al repo no les otorga una licencia nueva. Esta guía no
implica que el proyecto ya se haya publicado ni que esa revisión esté terminada.

Fuentes para contrastar herramientas y cambios futuros:

- [Manual oficial de NixOS](https://nixos.org/manual/nixos/stable/).
- [Swapfiles en Btrfs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).
- [Manual de Home Manager](https://nix-community.github.io/home-manager/).
