provider "libvirt" {
  uri = "qemu:///system"
}

module "nginx_rp" {
  source                     = "/home/steveb/workspace/terraform/modules/srb3/terraform-libvirt-domain"
  hostname                   = "nginx-rp-1"
  user                       = "steveb"
  ssh_public_key             = "/home/steveb/.ssh/id_rsa.pub"
  os_name                    = "centos"
  os_version                 = "8"
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
      role  = "geerlingguy.nginx"
      hosts = [module.nginx_rp.ip]
      vars  = local.conf
    }
  }
}

module "deploy_nginx" {
  source = "../../"
  roles  = local.roles
  hosts  = local.hosts
}
