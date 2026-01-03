{
  pkgs,
  config ? pkgs.config,
  lib ? pkgs.lib,
  ...
}:
let
  cfg = config.services.confess-web;

  flags = [
    "--port=${toString cfg.port}"
    "--static=${cfg.package}/static"
    "--database=${cfg.dataDir}/confess.db"
  ] ++ lib.optionals (!isNull cfg.ntfyUrl) [
    "--ntfy=${cfg.ntfyUrl}"
  ] ++ lib.optionals cfg.reverseProxy [
    "--reverse-proxy"
  ] ++ lib.optionals (!isNull cfg.trustedProxy) [
    "--trusted-proxy=${cfg.trustedProxy}"
  ];
in
{
  options.services.confess-web = {
    enable = lib.mkEnableOption "confess-web";

    package = lib.mkOption {
      description = "package to use";
      default = pkgs.callPackage ./build.nix { };
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/confess-web";
      description = "The directory where confess stores its database.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "confess-web";
      description = "User account under which confess runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "confess-web";
      description = "Group under which confess runs.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3000;
      description = "port to run http api on";
    };

    ntfyUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "ntfy url to use";
    };

    reverseProxy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "if running behind reverse proxy";
    };

    trustedProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Reverse proxy to trust";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Useful for storing secrets like: NTFY_URL";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

    users.users = lib.mkIf (cfg.user == "confess-web") {
      confess-web = {
        group = cfg.group;
        home = cfg.dataDir;
        createHome = true;
        isSystemUser = true;
      };
    };

    users.groups.${cfg.group} = { };

    systemd.services.confess-web = {
      enable = true;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ProtectSystem = "full";
        ProtectHome = "yes";
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        PrivateUsers = true;
        StateDirectory = cfg.dataDir;
        ExecStart = "${lib.getExe cfg.package} ${lib.concatStringsSep " " flags}";
        EnvironmentFile = cfg.environmentFile;
        Restart = "always";
      };

      environment.GIN_MODE = "release";
      wantedBy = [ "default.target" ];
    };
  };
}
