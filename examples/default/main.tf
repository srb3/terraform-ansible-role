provider "libvirt" {
  uri = "qemu:///system"
}

module "nginx_rp" {
  source                     = "srb3/domain/libvirt"
  version                    = "0.0.1"
  hostname                   = "nginx-rp-1"
  user                       = "centos"
  ssh_public_key             = "~/.ssh/id_rsa.pub"
  os_name                    = "centos"
  os_version                 = "8"
  os_cached_image            = var.os_cached_image
  unique_libvirt_domain_name = false
}

output "nginx" {
  value = module.nginx_rp
}

locals {
  conf = templatefile("${path.module}/templates/nginx.conf", {})

  roles = [
    "geerlingguy.nginx"
  ]
  hosts = {
    "reverse-proxy" = {
      role            = "geerlingguy.nginx"
      hosts           = [module.nginx_rp.ip]
      vars            = local.conf
      ssh_user        = "centos"
      ssh_private_key = "~/.ssh/id_rsa"
    }
  }
  extra_vars = {
    nginx_vhosts = [
      {
        "listen"      = "8000"
        "server_name" = "sample.com www.sample.com"
        "return"      = "301 https://twitter.com$request_uri"
        "filename"    = "sample.com.8000.conf"
      }
    ]
  }
}

module "deploy_nginx" {
  source     = "../../"
  roles      = local.roles
  hosts      = local.hosts
  extra_vars = local.extra_vars
}
