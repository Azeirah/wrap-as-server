# service-wrapper/flake.nix
{
  description = "Generic service wrapper for CLI programs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        lib = {
          makeHttpService =
            { name, version, program, port ? 5000, sentryDsn ? null }:
            let
              serverScript =
                pkgs.writeText "server.py" (builtins.readFile ./server.py);

              # Create wrapper with environment setup
              serviceWrapper = pkgs.writeShellScriptBin name ''
                export SERVICE_NAME="${name}"
                export SERVICE_VERSION="${version}"
                export SERVICE_PROGRAM="${program}/bin/${name}"
                export SERVICE_PORT="${toString port}"
                ${if sentryDsn != null then
                  ''export SENTRY_DSN="${sentryDsn}"''
                else
                  ""}

                exec ${
                  pkgs.python3.withPackages (ps: [ ps.flask ps.sentry-sdk ])
                }/bin/python ${serverScript}
              '';
            in serviceWrapper;
        };
      });
}
