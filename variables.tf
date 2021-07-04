variable "roles" {
  description = "A list of Ansible roles from Ansible galaxy, to be used as requirements"
  type        = list(string)
  default     = []
}

variable "hosts" {
  description = "A map of host groups and associated hosts"
  type = map(object({
    role            = string
    hosts           = list(string)
    vars            = string
    ssh_user        = string
    ssh_private_key = string
  }))
  default = {}
}
