provider "aws" {
  region  = "eu-west-2"
  version = "= 1.54.0"
  # shared_credentials_file = "/Users/Hoglund/.aws/credentials"
  profile = "dev"
}
provider "null" {
  version = "= 1.0"
}

resource "aws_instance" "http-server" {
  # AMI from https://nixos.org/nixos/download.html
  ami             = "ami-0dada3805ce43c55e"
  # instance_type = "t2.micro"
  instance_type   = "t2.medium"
  key_name        = "admin"

  tags {
    Name = "http-server"
  }
}
resource "null_resource" "http-server-prov" {
  triggers {
    build_number = "${timestamp()}" # Always run
  }
  # For all provisioners
  connection {
    type = "ssh"
    user = "root"
    host = "${element(aws_instance.http-server.*.public_ip, 0)}"
    private_key = "${file("~/.aws/admin-key.pem")}"
  }

  # Copy NixOS config file
  provisioner "file" {
    source      = "http-server.nix"
    destination = "/etc/nixos/configuration.nix"
  }
  # TODO mkdir /var/www/blog
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/www/blog"
    ]
  }
  # TODO copy index.html to above dir
  provisioner "file" {
    source      = "public/"
    destination = "/var/www/blog"
  }
  # TODO invoke nixos-rebuild switch
  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch"
    ]
  }
  # TODO errors in above?
}
