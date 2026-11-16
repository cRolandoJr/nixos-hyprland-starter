# Licencias y atribuciones

Las aportaciones propias de este repositorio (configuración NixOS, módulos,
scripts de soporte y documentación) se publican bajo la licencia [MIT](../LICENSE).
Los componentes de terceros incluidos o referenciados conservan sus licencias
originales y no son relicenciados por el starter.

## Componentes incorporados

- **Selector Ryogami:** se conserva íntegro
  [wall-ui/LICENSE](../pkgs/ryogami/wall-ui/LICENSE), MIT, copyright 2026 liixini.
  Este aviso corresponde al selector; no se extiende al resto del repositorio.
- **Daemon y adaptación Ryogami:** el paquete declara procedencia de
  [Ryoku](https://github.com/Ryoku-dev/ryoku) y `gpl3Only`. El upstream presenta
  una licencia GPL-3.0, pero eso no identifica por sí solo la revisión de cada
  fuente copiada. Falta reconstruir esa procedencia, conservar los avisos
  aplicables y aportar el texto de licencia correspondiente a esa revisión.
  No se considera cerrada la revisión del daemon por su metadata Nix.
- **Dotfiles y configuración Nix:** las revisiones de origen y el inventario de
  copia están en [origen.md](origen.md). Haberlos copiado de los repos personales
  no acredita autoría exclusiva ni una licencia común. Revisar también gráficos,
  temas y fragmentos incorporados antes de asignar una licencia al conjunto.
- **Paquetes de nixpkgs:** sus licencias son las de cada paquete. La configuración
  permite paquetes no libres; el starter no los relicencia.

## Wallpapers separados

Se retiraron del árbol actual 86 archivos, 369014830 bytes de contenido, con
permisos de redistribución no verificados. El
[inventario](wallpapers-inventory.json) registra nombre, tamaño y SHA-256 para
poder contrastar fuentes sin atribuir autoría a partir del nombre de archivo.
No se publica un paquete alternativo de esas imágenes ni se las comprime para
redistribuirlas: ninguna de esas operaciones acredita permisos.

Las imágenes también fueron eliminadas del historial Git para que un clon completo
no descargue archivos sin permisos verificados.

## Antes de difundir

- Resolver procedencia y avisos pendientes del código y los gráficos incorporados.
- Elegir una licencia para las aportaciones propias sin extenderla a terceros.
- Usar capturas con fondos propios o de permisos comprobados y sin datos privados.
- Si vuelve una imagen, registrar fuente exacta, autor, licencia o autorización
  verificable y atribución exigida; si no se puede comprobar, mantenerla fuera.
