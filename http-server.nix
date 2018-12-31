{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  ec2.hvm = true;

  networking.firewall = {
    enable = false; # TODO
    # allowedTCPPorts = [ 8081 ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."blog.example.com" = {
      # enableACME = true;
      root = "/var/www/blog";
    };
  };
}
