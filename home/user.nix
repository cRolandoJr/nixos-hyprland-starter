{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:

let
  ryogami = pkgs.callPackage ../pkgs/ryogami { };
  hyprcapture = import ../pkgs/hyprcapture {
    inherit pkgs;
    src = inputs.hyprcapture;
  };
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      # Reemplazá estos ejemplos por tu nombre y correo para los commits de Git.
      user.name = "Tu Nombre";
      user.email = "tu-correo@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "nvim";
        excludesfile = "${config.home.homeDirectory}/.gitignore_global";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

    # compinit -C: saltea re-scan si dump tiene <24h (~60-80ms ganados con el fpath enorme de NixOS).
    completionInit = ''
      autoload -U compinit
      if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
    '';

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -la --icons --git";
      ls = "eza --icons";
      tree = "eza --tree --icons";
      cat = "bat";

      # nh selecciona la configuración por el hostname del equipo.
      rebuild = "nh os switch ~/projects/nix-config";
      rebuild-test = "nh os test ~/projects/nix-config";
      rebuild-boot = "nh os boot ~/projects/nix-config";
      update = "cd ~/projects/nix-config && nix flake update";

      # Mismo criterio que nix.gc: `-d` borraba todas las generaciones y dejaba sin rollback.
      gc = "sudo nix-collect-garbage --delete-older-than 7d && nix-collect-garbage --delete-older-than 7d";

      # uhid: mouse como HID físico. shortcut-mod=lsuper: no choca con alt_shift_toggle.
      # render-driver=opengl: evita stutter de SDL3 en Wayland.
      scrcpy = "scrcpy --mouse=uhid --shortcut-mod=lsuper --no-audio --max-fps=60 --render-driver=opengl";

      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
    };

    initContent = ''
      setopt INTERACTIVE_COMMENTS
      unsetopt NOMATCH
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # init manual: programs.starship pisaría el starship.toml del mkOutOfStoreSymlink.
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Cache por versión: evita fork+exec en cada init (~10ms); se invalida al subir fzf en nixpkgs.
      _fzf_cache="$HOME/.cache/fzf-zsh-${pkgs.fzf.version}.zsh"
      if [[ ! -f "$_fzf_cache" ]]; then
        mkdir -p "$HOME/.cache"
        ${pkgs.fzf}/bin/fzf --zsh > "$_fzf_cache"
      fi
      source "$_fzf_cache"
      unset _fzf_cache

      # fzf secuestra Tab; restauramos al completador nativo (después del source para ganar el binding).
      bindkey '^I' expand-or-complete

      _comp_options+=(globdots)

      # "" vacío como primer patrón: exacto → case-insensitive → substring.
      zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'

      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'

      # _eza solo ofrece flags; _files para que ls/ll/tree completen paths.
      compdef _files eza
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # enableZshIntegration = false: se usa cache manual en initContent (ver arriba).
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
    };
  };

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
    enable = true;
  };

  # hyprsunset.conf vive en dotfiles/hypr/ (HM no puede escribir dentro del mkOutOfStoreSymlink).
  services.hyprsunset.enable = true;

  # Notifica a mako los eventos de batería de upower (low/critical/carga).
  services.poweralertd.enable = true;

  # Servicio en vez de exec_cmd del autostart: waybar 0.15.0 crashea al perder el
  # audio y con exec_cmd nadie lo relevanta (14 coredumps entre el 15 y el 28-jul).
  # settings/style quedan vacíos a propósito: así el módulo NO escribe el config y
  # sigue mandando el symlink a dotfiles.
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # El reloj de waybar no toma la zona de /etc/localtime; el TZ va explícito.
  systemd.user.services.waybar.Service.Environment = [
    "TZ=America/Argentina/Buenos_Aires"
  ];

  # Como unidad y no como exec_cmd del autostart: ese handler corre solo en
  # `hyprland.start`, y tras un rebuild sin reiniciar sesion los binds fallaban
  # en silencio contra un daemon inexistente.
  systemd.user.services.ryogami = {
    Unit = {
      Description = "Ryogami — daemon de wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${ryogami}/bin/ryogami daemon";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # El orden contra el daemon evita el parpadeo inicial (la superficie
  # reintenta sola, pero arranca en vano hasta que el socket existe).
  systemd.user.services.ryogami-surface = {
    Unit = {
      Description = "Ryogami — superficie que pinta el wallpaper";
      Requires = [ "ryogami.service" ];
      After = [
        "ryogami.service"
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${ryogami}/bin/ryogami-surface";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:";

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:";
    };
  };

  home.packages = with pkgs; [
    # Escritorio: sesión Hyprland, notificaciones, portapapeles, terminal, archivos
    # Los plugins van por override y no como paquetes sueltos: rofi solo carga
    # los .so que tiene en su propio wrapper.
    (rofi.override {
      plugins = [
        rofi-calc
      ];
    })
    eww
    mako
    hypridle
    hyprlock
    swayosd
    cliphist
    wl-clipboard
    brightnessctl
    libnotify
    kdePackages.qt6ct
    foot
    thunar
    yazi
    xh

    # Capturas de pantalla y grabación
    hyprcapture
    gpu-screen-recorder
    (tesseract.override {
      enableLanguages = [
        "eng"
        "spa"
      ];
    })

    # Multimedia
    vlc
    mpv
    spotify
    sox
    cava

    # Ocio y comunicación
    telegram-desktop
    discord
    google-chrome

    # Productividad
    obsidian
    libreoffice
    khal
    tzdata

    # Dev: editores y git
    neovim
    vscode
    antigravity-ide
    opencode
    gh
    lazygit
    codex

    # Dev: CLI
    bat
    eza
    ripgrep
    fd
    httpie
    poppler-utils
    fastfetch
    nix-output-monitor
    postman

    # Infra: secretos
    sops
    ssh-to-age

    # Clientes Kubernetes; no habilitan un clúster local.
    kubectl
    k9s
    kubernetes-helm

    # Infra: Android
    android-tools
    scrcpy

    # Fuera de nixpkgs
    (callPackage ../pkgs/boundary-desktop.nix { })
    (callPackage ../pkgs/balena-etcher.nix { })
    ryogami

    # Python + CodeGraphContext
    python3

    # CGC requiere python3.12 (excluye tree-sitter en 3.13); lowPrio evita colisión
    # con python3 en nombres genéricos (bin/python3, etc.).
    # WORKAROUND nixpkgs 26-jul-2026: tests/test_inject.py de pipx 1.14.0 no collecta con el
    # pytest actual (parametrize con string); el `disabledTests` de nixpkgs es -k y corre
    # post-collection, así que no alcanza. Retirar cuando `pipx` plano vuelva a buildear.
    (pipx.overridePythonAttrs (o: {
      disabledTestPaths = (o.disabledTestPaths or [ ]) ++ [ "tests/test_inject.py" ];
    }))
    (lib.lowPrio python312)

    # CGC (FalkorDB Lite) hace dlopen de libstdc++.so.6, ausente en rutas FHS de NixOS.
    # Este wrapper inyecta gcc-lib solo al proceso CGC; cgc-nix evita colisión con el binario de pipx.
    (writeShellScriptBin "cgc-nix" ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # El cliente habla solo por socket Unix; sin esto redislite abría *:6379 en todas las interfaces.
      export FALKORDB_PORT=0
      exec "$HOME/.local/share/pipx/venvs/codegraphcontext/bin/codegraphcontext" "$@"
    '')

    # Neovim toolchain
    gcc
    gnumake
    tree-sitter
    nodejs

    # LSPs
    go
    gopls
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    nixd
    bash-language-server
    lua-language-server

    # Formatters
    stylua
    ruff
    gofumpt
    (lib.lowPrio gotools)
    rustfmt
    prettierd
    shfmt

    # Linters
    golangci-lint
    eslint_d
    shellcheck
    markdownlint-cli
    yamllint
    hadolint
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0";
    QT_STYLE_OVERRIDE = "Fusion";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Estas variables indican la ubicación esperada; no instalan el SDK.
    ANDROID_SDK_ROOT = "${config.home.homeDirectory}/Android/Sdk";
    ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";

    NH_NOM = "1"; # nh pipea el build por nix-output-monitor
  };

  xdg.configFile = {
    "hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/hypr/.config/hypr";

    "waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/waybar/.config/waybar";

    "eww".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/eww/.config/eww";

    "cliphist".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/cliphist/.config/cliphist";

    "rofi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/rofi/.config/rofi";

    "fastfetch".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/fastfetch/.config/fastfetch";

    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/nvim/.config/nvim";

    "quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/quickshell/.config/quickshell";

    "foot".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/foot/.config/foot";

    "mako".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/mako/.config/mako";

    "khal".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/khal/.config/khal";

    "qt6ct".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/qt6ct/.config/qt6ct";

    "yazi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/yazi/.config/yazi";

    "opencode".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/opencode/.config/opencode";
  };

  home.file.".config/starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/starship/.config/starship.toml";

  # markdownlint-cli lee ~/.markdownlintrc (verificado): apaga largo de línea y estilo de tablas.
  home.file.".markdownlintrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/nix-config/dotfiles/markdownlint/.markdownlintrc";

  home.file.".local/lib/hyprland/libhyprcapture.so".source = "${hyprcapture}/lib/libhyprcapture.so";

  home.file.".local/lib/hyprland/libhyprfocus.so".source =
    "${pkgs.hyprlandPlugins.hyprfocus}/lib/libhyprfocus.so";

  home.file.".local/lib/hyprland/libhyprbars.so".source =
    "${pkgs.hyprlandPlugins.hyprbars}/lib/libhyprbars.so";

  # El .desktop por defecto de nixpkgs usa `Terminal=true` y `Exec=nvim %F`, lo que
  # hace que launchers/file managers caigan en `xterm` (fondo blanco y fuente fea).
  # Forzamos `foot` explícitamente para que siempre abra con tu tema y fuente.
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "foot -e nvim %F";
    icon = "nvim";
    terminal = false;
    type = "Application";
    categories = [
      "Utility"
      "TextEditor"
      "Development"
    ];
    mimeType = [
      "text/english"
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };

  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram";
    comment = "New era of messaging";
    icon = "org.telegram.desktop";
    exec = "Telegram -- %U";
    terminal = false;
    type = "Application";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
    startupNotify = true;
    settings = {
      TryExec = "Telegram";
      DBusActivatable = "false";
      StartupWMClass = "TelegramDesktop";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;";
    };
    actions.quit = {
      name = "Quit Telegram";
      exec = "Telegram -quit";
      icon = "application-exit";
    };
  };
  # ─────────────────────────────────────────────────────────────────────
  # El daemon y el selector leen archivos distintos, y escribir en el que no es
  # no da error: da silencio. Se tocan solo las claves estructurales y quedan
  # escribibles, porque el selector guarda ahi sus favoritos; la contrapartida es
  # que editarlas a mano no sobrevive al proximo rebuild. La logica va en un
  # script porque con $DRY_RUN_CMD las redirecciones se ejecutan igual.
  # Resuelve el marcador inicial de Qt sin sobrescribir una paleta personalizada.
  # El archivo sigue editable en el clon de dotfiles, fuera del store.
  home.activation.qt6ctHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i "s|@HOME@|${config.home.homeDirectory}|g" "${config.home.homeDirectory}/.config/qt6ct/qt6ct.conf"
  '';

  home.activation.ryogamiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.writeShellScript "ryogami-config" ''
      set -eu
      daemon_cfg="$HOME/.config/ryoku/ryogami.json"
      picker_cfg="$HOME/.config/ryogami-wall/config.json"

      mkdir -p "$HOME/.config/ryoku" "$HOME/.config/ryogami-wall" "$HOME/Wallpapers"
      [ -f "$daemon_cfg" ] || echo '{}' > "$daemon_cfg"
      [ -f "$picker_cfg" ] || echo '{}' > "$picker_cfg"

      # El daemon NO expande `~`: con "~/Wallpapers" devuelve cero wallpapers y
      # no avisa. Por eso la ruta se interpola absoluta desde Nix.
      ${pkgs.jq}/bin/jq '.paths.wallpaper = "${config.home.homeDirectory}/Wallpapers"
        | .features.matugen = false
        | .features.steam = false' "$daemon_cfg" > "$daemon_cfg.new"
      mv "$daemon_cfg.new" "$daemon_cfg"

      # matugen en false a proposito: sus plantillas escriben temas en
      # ~/.config/{kitty,yazi,qt6ct}. Hoy no rompe nada porque home-manager deja
      # esas rutas de solo lectura, pero no conviene depender de eso.
      ${pkgs.jq}/bin/jq '.paths.wallpaper = "${config.home.homeDirectory}/Wallpapers"
        | .components.wallpaperSelector.displayMode = "slices"
        | .features.matugen = false
        | .features.steam = false
        | .transition = {enabled: true, shader: "random", durationMs: 600}' \
        "$picker_cfg" > "$picker_cfg.new"
      mv "$picker_cfg.new" "$picker_cfg"
    ''}
  '';
}
