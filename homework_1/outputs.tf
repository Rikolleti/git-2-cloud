output "public_vm_public_ip" {
  value = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
}

output "public_vm_private_ip" {
  value = yandex_compute_instance.public_vm.network_interface[0].ip_address
}

output "private_vm_private_ip" {
  value = yandex_compute_instance.private_vm.network_interface[0].ip_address
}

output "nat_public_ip" {
  value = yandex_compute_instance.nat.network_interface[0].nat_ip_address
}
