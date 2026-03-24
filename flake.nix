{
  description = "Bun + TypeScript + Njs Project Automation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        deps = with pkgs; [ bun nodejs-slim openssl ];

        config-script = pkgs.writeShellScriptBin "config-project" ''
          if [ ! -f packages/backend/.env ]; then
            echo "Creating .env from example..."
            cp .env.example packages/backend/.env
            SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)
            sed -i "s/HASH_SECRET=.*/HASH_SECRET=$SECRET/" packages/backend/.env
            echo "Done! Please edit packages/backend/.env to set your DEVICE_TOKEN."
          else
            echo ".env already exists, skipping."
          fi
        '';

        start-script = pkgs.writeShellScriptBin "start-project" ''
          echo "Building Frontend..."
          cd packages/frontend && ${pkgs.bun}/bin/bun install && ${pkgs.bun}/bin/bun run build
          mkdir ../backend/public/
          cp -r out/* ../backend/public/
          
          echo "Starting Backend..."
          cd ../backend && ${pkgs.bun}/bin/bun install && ${pkgs.bun}/bin/bun run src/index.ts
        '';

      in
      {
        devShells.default = pkgs.mkShell { buildInputs = deps; };
        apps = {
          config = {
            type = "app";
            program = "${config-script}/bin/config-project";
          };
          start = {
            type = "app";
            program = "${start-script}/bin/start-project";
          };
        };
      });
}
