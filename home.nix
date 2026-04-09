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
          epkgs:
          let
            claude-code-ide = epkgs.trivialBuild {
              pname = "claude-code-ide";
              version = "unstable";
              src = pkgs.fetchFromGitHub {
                owner = "manzaltu";
                repo = "claude-code-ide.el";
                rev = "56db02ee386d009ddb8b1482310f1f9beeefb810";
                hash = "sha256-qH1QnG5G+0UiH/v0KaS7oSpQZY+BkUMZvrjbx6kyFhg=";
              };
              packageRequires = with epkgs; [
                websocket
                web-server
                transient
              ];
              postPatch = "rm -f claude-code-ide-tests.el";
            };
            claude-code-ide-mcp-tools = epkgs.trivialBuild {
              pname = "claude-code-ide-mcp-tools";
              version = "unstable";
              src = pkgs.fetchFromGitHub {
                owner = "Kaylebor";
                repo = "claude-code-ide-mcp-tools";
                rev = "9e74701482f44090aab80f45e6e7eabce5208bd4";
                hash = "sha256-rvju/JSdsCIGZakdkQTlERi943gXDp8pKmFEAIHZHdU=";
              };
              packageRequires = [ claude-code-ide ];
            };
          in
          with epkgs;
          [
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
            claude-code-ide
            claude-code-ide-mcp-tools
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
  # Note: emacs MCP is auto-configured by claude-code-ide.el when launching via M-x claude-code-ide
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.claude-code}/bin/claude mcp add-json nixos '{"command": "mcp-nixos", "args": []}' -s user 2>/dev/null || true
    _claude="$HOME/.claude.json"
    [ -f "$_claude" ] || echo '{}' > "$_claude"
    ${pkgs.jq}/bin/jq '. * {"model":"sonnet","env":{"MAX_THINKING_TOKENS":"10000","CLAUDE_AUTOCOMPACT_PCT_OVERRIDE":"50","CLAUDE_CODE_SUBAGENT_MODEL":"haiku"}}' "$_claude" > "$_claude.tmp" && mv "$_claude.tmp" "$_claude"
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
