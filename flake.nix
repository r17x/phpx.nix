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
        devenv.shells.default =
          { config, pkgs, ... }:
          let
            appName = "web";
          in
          {
            env.DBNAME = "no-xampp";
            env.DBUSER = "r17";
            env.HOSTNAME = "localhost";

            packages = [ ];

            # see full options: https://devenv.sh/supported-languages/php/
            languages.php.enable = true;
            languages.php.extensions = [
              "pgsql"
              # add more extensions here
            ];
            languages.php.fpm.pools.${appName} = {
              phpEnv = {
                DBNAME = config.env.DBNAME;
                DBUSER = config.env.DBUSER;
                DBHOST = config.services.postgres.listen_addresses;
                DBPORT = toString config.services.postgres.port;
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

            # see full options: https://devenv.sh/supported-services/postgres/
            services.postgres.enable = true;
            services.postgres.package = pkgs.postgresql_15;
            services.postgres.listen_addresses = "127.0.0.1";
            services.postgres.initialDatabases = [ { name = config.env.DBNAME; } ];

            services.nginx.enable = true;
            services.nginx.httpConfig = # nginx
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

            scripts.up.exec = # bash
              ''
                devenv up
              '';

          };
      };
    };
}
