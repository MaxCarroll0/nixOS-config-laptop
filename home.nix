{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  sops-nix,
  ...
}:

{
  imports = [
    ./hyprland.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "max";
  home.homeDirectory = "/home/max";

  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    userName = "Max";
    userEmail = "mjvcarroll@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  #programs.opam = {
  #    enable = true;
  #  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bash = {
    enable = true;

    bashrcExtra = ''
      eval "$(direnv hook bash)"
    '';
  };

  programs.emacs = {
    enable = true;
    package = (
      pkgs.emacsWithPackagesFromUsePackage {
        package = pkgs.emacs-pgtk;
        config = ./emacs/config.org;
        defaultInitFile = true;
        alwaysEnsure = true;

        extraEmacsPackages =
          epkgs: with epkgs; [
            treesit-grammars.with-all-grammars
            use-package
            meow
            nixpkgs-fmt
            apheleia
            nix-ts-mode
            magit
            agda2-mode
            direnv
            auctex
            vertico
            orderless
            corfu
            cape
            xenops
            cdlatex
            vterm
            claude-code
          ];
      }
    );
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    nixfmt-rfc-style
    nixd
    # TODO: remove isabelle, lean4, agda. Add instead on per-project level
    isabelle
    lean4
    agda
    ghostscript
    claude-code
    mcp-nixos

    # Fonts
    nerd-fonts.fira-code
    nerd-fonts.mononoki
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/max/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "emacs";
  };

  # Declaratively configure Claude Code MCP servers
  # Hacky: This merges into ~/.claude.json without overwriting other settings
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.claude-code}/bin/claude mcp add-json emacs '{"type": "stdio", "command": "claude-code-mcp"}' -s user 2>/dev/null || true
    ${pkgs.claude-code}/bin/claude mcp add-json nixos '{"command": "mcp-nixos", "args": []}' -s user 2>/dev/null || true
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
