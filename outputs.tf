output "nat_instance_public_ip" {
  value       = yandex_compute_instance.nat-instance.network_interface.0.nat_ip_address
  description = "Публичный IP NAT-инстанса"
}

output "nat_instance_internal_ip" {
  value       = yandex_compute_instance.nat-instance.network_interface.0.ip_address
  description = "Внутренний IP NAT-инстанса"
}

output "public_vm_public_ip" {
  value       = yandex_compute_instance.public-vm.network_interface.0.nat_ip_address
  description = "Публичный IP публичной ВМ"
}

output "private_vm_internal_ip" {
  value       = yandex_compute_instance.private-vm.network_interface.0.ip_address
  description = "Внутренний IP приватной ВМ"
}

output "public_subnet_id" {
  value       = yandex_vpc_subnet.public-subnet.id
  description = "ID публичной подсети"
}

output "private_subnet_id" {
  value       = yandex_vpc_subnet.private-subnet.id
  description = "ID приватной подсети"
}

output "route_table_id" {
  value       = yandex_vpc_route_table.nat-route.id
  description = "ID route table для приватной подсети"
}
