output "bastion_public_ip" {
  value = module.kubernetes.bastion_public_ip
}

output "bastion_private_ip" {
  value = module.kubernetes.bastion_private_ip
}

output "controller_nodes" {
  value = module.kubernetes.controller_private_ip
}

output "worker_nodes" {
  value = module.kubernetes.worker_private_ip
}
