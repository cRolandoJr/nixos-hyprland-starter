# Procedencia y selección inicial

## Estado de preparación

Proyecto independiente en `/home/rolando/projects/nixos-hyprland-starter`.
La plantilla requiere hardware y disco propios antes de instalar. Rolando completó
una instalación adaptada en VM el 14 de noviembre de 2026; ver la
[guía de instalación](INSTALACION.md). Los apartados siguientes conservan el historial
de preparación y no describen todos el estado actual. No se modificaron los repos originales.

### Revisiones de referencia

- `nix-config`: `1053d0c4b0c4504594c923f727f444fc9986e560`.
- `dotfiles`: `3aee6d4d18d95612236739b5925ddb752cb4bc47`.

Las revisiones identifican el historial de referencia. Los archivos de trabajo
contienen además los cambios locales indicados abajo; no atribuirlos a esos commits.
Revalidar los diffs antes de copiar si los orígenes cambiaron.

### Cambios locales revisados y decisiones aprobadas

- `nix-config/home/rolando.nix`: agregado de `xh` a los paquetes de usuario.
  Incluir en la versión compartible como herramienta de consola.
- `dotfiles/hypr/.config/hypr/hyprland.lua`: regla `no_blur = true` para ventanas
  cuyo título coincide con `^(deadlocked_overlay)$`. Excluir de la copia compartible.
  Rolando identifica la aplicación como acompañante de un juego; no recuerda el
  motivo del ajuste. Conservar la regla en sus dotfiles personales.

### Primera selección de módulos

- Origen `nix-config/modules/gaming.nix`; destino `modules/gaming.nix`.
- Origen `nix-config/modules/virtualisation.nix`; destino `modules/virtualisation.nix`.

Ambos se copiarán inicialmente para revisión. Copiarlos no significa que sus políticas
ya estén aprobadas para otros equipos. Gaming contiene una referencia a la cuenta
`rolando`; virtualización configura QEMU con `runAsRoot = true`. Revisar estos puntos
antes de incorporar los módulos a una configuración instalable.

### Pendientes

- Completar la adaptación de los módulos copiados mediante práctica guiada.
- Resolver las dependencias y adaptaciones pendientes de los archivos incorporados.
- Comprobar licencias y atribuciones antes de distribuir código y recursos gráficos.
- Actualizar el inventario cuando se realicen nuevas adaptaciones.

### Copia del escritorio y paquetes locales

Se incorporaron 169 archivos de configuración y 150 archivos de paquetes locales.
La selección usa archivos versionados de los componentes que consume Home Manager;
no copia los repositorios Git, cachés ni archivos no versionados. El inventario exacto,
con hashes de origen y destino, está en [inventario-copia.json](inventario-copia.json).

Se conservan las fuentes completas de Ryogami, incluidos sus tests y selector, y las
expresiones Nix de Boundary Desktop y Balena Etcher. La licencia MIT del selector se
conservó. Revisar todavía la documentación de licencia del daemon y los recursos
incluidos antes de publicar; la anotación en el paquete no reemplaza esa revisión.

Excepciones respecto al origen:

- Se excluyó la regla `deadlocked_overlay` de la copia de Hyprland, como se acordó.
- De OpenCode se incluyó solo `opencode.json`, sin las referencias a memorias del autor.
  No se copiaron sus memorias, agentes, comandos, plugins, tests ni skills personales.
- No se copiaron configuraciones de asistentes ubicadas fuera de esos componentes.

Verificación realizada: hashes de las copias y conservación de los originales;
16 de 16 destinos de los enlaces Home Manager presentes; sintaxis de Home Manager y
las tres expresiones de paquetes válida. No se construyeron los paquetes ni se
activó el escritorio. La existencia de archivos no demuestra su funcionamiento.

Adaptaciones pendientes en la copia:

- Calendario inicial y textos que describen el antiguo calendario PEDCO.
- Revisar otras dependencias de scripts y recursos antes de probar el escritorio limpio.

### Adaptación de monitores, identidad y controles

- Monitores: se conserva solo la regla general de modo preferido, posición automática
  y escala 1; cada usuario puede ajustar su equipo en `configs/monitors.lua`.
- Eww: el nombre visible viene de `id -un`, consultado por `session_username`.
- Qt6: la paleta usa un marcador `@HOME@` en la copia inicial. La activación de Home
  Manager lo sustituye por el home configurado, después de preparar los enlaces.
  Si el usuario cambia posteriormente la ruta de la paleta, se conserva ese cambio.
- Waybar: el botón existente controla solamente scx; se retiraron k3s y las cifras
  de consumo medidas en la máquina del autor. No promete una mejora de rendimiento.

Verificaciones de este bloque: sintaxis Nix y Bash válida; ejecución del script real
contra un doble de systemctl para estados activo, parado y ausente; consultas registradas
exclusivamente para scx. La orden real de preparación Qt, con rutas temporales, respetó
el modo seco, resolvió un home con espacios, fue estable en una segunda ejecución y
conservó una ruta personalizada. No se ejecutó el toggle contra servicios reales.

Pendiente: comprobar visualmente monitores, Eww y Qt en la VM, y validar los permisos
sudo necesarios para el botón scx al integrar el módulo base. No se activó el escritorio.

### Indicador verificado y host de preparación

El indicador distingue repositorio ausente, error al consultar Git, limpio y modificado.
La prueba ejecuta el script real con repositorios temporales. Antes del cambio,
cuatro pruebas dieron un fallo y un error; después, cuatro pruebas correctas.
El consumidor fue rastreado manualmente desde `custom/nixos` en Waybar: este proyecto
no estaba entre los repositorios indexados en CodeGraph.

Comando reproducible desde cualquier directorio:

```zsh
python3 ~/projects/nixos-hyprland-starter/tests/test_waybar_nixos_status.py
```

Se agregó `hosts/equipo/default.nix`, que recibe `hostname` y conecta los dos módulos
ya preparados. Falta integrar base, arranque, red, audio, fuentes y escritorio.
`hardware.nix` y `disk.nix` contienen aserciones pendientes explícitas, sin seleccionar
ningún dispositivo. Se reemplazarán por la configuración verificada del destino.

Verificación: sintaxis de los tres archivos válida; evaluación directa confirma el
hostname `equipo` y las dos aserciones falsas. No se evaluó ni construyó todavía el
sistema NixOS completo. El siguiente checkpoint es integrar los módulos compartidos,
retirando configuración personal como puertos de Gama23 y audio de Astro.

### Integración de módulos compartidos

Se integraron `base.nix`, `boot.nix`, `network.nix`, `audio.nix`, `fonts.nix` y
`desktop-hyprland.nix` en el host `equipo`.

Adaptaciones respecto al origen:

- Cuenta, confianza en Nix y reglas sudo reciben `username`.
- Se retiraron los puertos de Gama23, el audio de Astro y su ajuste asociado de prioridad.
- Se retiraron reglas sudo para k3s y btrbk, y los alias de snapshots que apuntaban a
  un servicio no incorporado. Snapshots y scrub se definirán junto con el disco real;
  no se copiaron montajes de Victus ni se asumió Btrfs en la raíz del destino.
- Se conserva el control sudo específico de scx que utiliza el botón de Waybar.
- Se declara soporte gráfico genérico de 64 y 32 bits. El driver de GPU sigue siendo
  responsabilidad del hardware destino; no se importó el módulo AMD de Victus.
- El servicio de perfiles de energía queda junto a la base, porque lo consumen los
  controles del escritorio y no depende de que la GPU sea AMD.
- El arranque copiado usa systemd-boot y presupone UEFI; comprobarlo al elegir destino.

Se limpió `flake.lock` mediante `nix flake lock`, retirando PEDCO, sops-nix y dependencias
que quedaron sin consumidor. Se compararon los nodos conservados con el lock de origen:
no cambiaron versiones ni hashes de nixpkgs, Home Manager, disko, hooks o flake-compat.

Evaluación realizada contra el flake real, sin construir ni activar:

- Hostname `equipo`, usuario `nombre`, home `/home/nombre`, shell zsh y grupo uinput.
- Hyprland, UWSM, SDDM, PipeWire, NetworkManager y perfiles de energía habilitados.
- Steam, libvirt y Podman habilitados; k3s y Ollama desactivados.
- Home Manager evalúa 109 paquetes, incluidos los tres paquetes locales, y no informa
  aserciones fallidas propias. Evaluar sus nombres no demuestra que todos construyan.
- El sistema conserva exactamente tres aserciones fallidas: hardware y disco pendientes,
  más la raíz sin definir. Son límites explícitos del borrador, no una prueba de arranque.
- No aparecen los puertos 8081/8443 ni la configuración de PipeWire de Astro.
- Las reglas sudo evaluadas no mencionan k3s ni btrbk.

Resultado de las consultas: [evaluacion-modulos.json](evaluacion-modulos.json).
Sintaxis comprobada en los 12 archivos de módulos, host y Home Manager.

Siguiente checkpoint: preparar un host de VM con disco virtual y acceso de prueba para
construir e instalar sin utilizar discos físicos del anfitrión. El equipo físico sigue
pendiente de identificación, respaldo y autorización de su propietario. La contraseña
inicial del usuario todavía no está configurada.

### Instalación guiada y preparación de entrega — 2026-11-14

Rolando ejecutó particionado manual GPT, EFI y Btrfs sin LUKS, con subvolúmenes
`@root`, `@home` y `@nix`. Generó hardware propio, instaló con el flake y arrancó
Hyprland en VM con QXL sin OpenGL. Se verificaron cero unidades fallidas y ausencia
de errores de configuración de Hyprland; SSH y el selector de fondos funcionaron.

Incidentes resueltos: ISO desconectada, OOM con 4 GiB (swap temporal y menor
paralelismo), cambio de clave SSH del live al sistema instalado y diferencia de
mayúsculas en la carpeta de fondos. La causa de Virtio 3D negro no se determinó.
El rebuild del ajuste EFI terminó; falta evidencia del findmnt final con 0077.

La copia compartible conserva las aserciones de hardware/disco pendientes, SSH
habilitado y las dos rutas Ryogami hacia dotfiles/Wallpapers. Al preparar la guía
se encontró la carpeta local aún en minúsculas y se renombró a Wallpapers.
Se conserva home/user.nix.save como archivo previo del usuario, no importado por
el flake; no utilizarlo como configuración vigente. Los fondos incorporados por
Rolando requieren revisión de licencias antes de una publicación pública.

La guía recoge la instalación manual probada; starter-vm no se utiliza en ella.
No se publicaron archivos, no se activó nada en Victus y no se trasladaron UUID
de la VM a la plantilla. Gaming, virtualización y hardware físico siguen pendientes.
