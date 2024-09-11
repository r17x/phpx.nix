{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.devenv.url = "github:cachix/devenv";
  inputs.devenv.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = _args: {
        devenv.shells.default = { config, pkgs, ... }:
          let
            appName = "web";
            username = builtins.getEnv "USER";
          in
          {
            env = {
              DBNAME = "no-xampp";
              DBUSER = username;
              HOSTNAME = "localhost";
              DBPORT = 5432; # change this if you are already allocate this port
            };

            packages = [ ];

            # see full options: https://devenv.sh/supported-languages/php/
            languages.php = {
              enable = true;
              extensions = [
                "pgsql"
                # add more extensions here
              ];
              fpm.pools.${appName} = {
                phpEnv = {
                  DBNAME = config.env.DBNAME;
                  DBUSER = config.env.DBUSER;
                  DBHOST = config.services.postgres.listen_addresses;
                  DBPORT = toString config.env.DBPORT;
                };
                settings = {
                  "pm" = "dynamic";
                  "pm.max_children" = 75;
                  "pm.start_servers" = 10;
                  "pm.min_spare_servers" = 5;
                  "pm.max_spare_servers" = 20;
                  "pm.max_requests" = 500;
                };
              };
            };

            # see full options: https://devenv.sh/supported-services/postgres/
            services.postgres = {
              enable = true;
              package = pkgs.postgresql_15;
              port = config.env.DBPORT;
              listen_addresses = "127.0.0.1";
              initialDatabases = [ { name = config.env.DBNAME; } ];
            };

            services.nginx = {
              enable = true;
              httpConfig = # nginx
                ''
                server {
                  listen 80;
                  server_name ${config.env.HOSTNAME};
                  
                  root         ${config.env.DEVENV_ROOT}/src/;

                  index index.html index.htm index.php;

                  location / {
                              try_files $uri $uri/ /index.php$is_args$args;
                  }

                  location ~ \.php$ {
                    fastcgi_split_path_info ^(.+\.php)(/.+)$;
                    fastcgi_pass unix:${config.languages.php.fpm.pools.${appName}.socket};
                    fastcgi_index index.php;
                    include ${config.services.nginx.package}/conf/fastcgi.conf;
                    }
                }
                '';
            };

            scripts.up.exec = # bash
              ''
                devenv up
              '';
          };
      };
    };
}
