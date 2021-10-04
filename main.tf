locals {
  ansible_location  = "${path.module}/temp_files/ansible"
  playbook_location = "${local.ansible_location}/playbook"

  site = templatefile("${path.module}/templates/site.yml", {
    hosts = var.hosts
  })

  reqs = templatefile("${path.module}/templates/requirements.yml", {
    roles = var.roles
  })

  hosts = templatefile("${path.module}/templates/hosts", {
    hosts = var.hosts
  })

  group_vars = {
    for k, v in var.hosts : k => { "content" = v.vars }
  }
}

resource "local_file" "playbook" {
  content         = local.site
  filename        = "${local.playbook_location}/site.yml"
  file_permission = "0644"
}

resource "local_file" "group_vars" {
  for_each        = local.group_vars
  content         = each.value.content
  filename        = "${local.playbook_location}/group_vars/${each.key}/vars.yml"
  file_permission = "0644"
}

resource "local_file" "reqs" {
  content         = local.reqs
  filename        = "${local.ansible_location}/requirements.yml"
  file_permission = "0644"
}

resource "local_file" "hosts" {
  content         = local.hosts
  filename        = "${local.ansible_location}/hosts"
  file_permission = "0644"
}

resource "null_resource" "execute_ansible_install" {
  depends_on = [
    local_file.playbook,
    local_file.reqs,
    local_file.hosts,
    local_file.group_vars,
  ]

  provisioner "local-exec" {
    command     = "ansible-galaxy install -r requirements.yml --force"
    working_dir = local.ansible_location
  }
}

locals {
  command = (length(var.extra_vars) > 0
    ?
    "ansible-playbook -i ./hosts playbook/site.yml --extra-vars '${jsonencode(var.extra_vars)}'"
    :
    "ansible-playbook -i ./hosts playbook/site.yml"
  )
}

resource "null_resource" "execute_ansible_role" {
  triggers = {
    value = md5(join(",", [jsonencode(var.hosts), jsonencode(var.roles)]))
  }
  depends_on = [null_resource.execute_ansible_install]

  provisioner "local-exec" {
    command     = local.command
    working_dir = local.ansible_location
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
