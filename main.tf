# ================================================
# Пункт 1. Пустая VPC
# ================================================
resource "yandex_vpc_network" "my-vpc" {
  name        = "my-vpc"
  description = "VPC для домашнего задания"
}
# ================================================
# Пункт 2а. Публичная подсеть 192.168.10.0/24
# ================================================
resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
# ================================================
# Security group для NAT-инстанса
# ================================================
resource "yandex_vpc_security_group" "nat-sg" {
  name       = "nat-instance-sg"
  network_id = yandex_vpc_network.my-vpc.id

  ingress {
    protocol       = "ANY"
    description    = "Allow all incoming from VPC"
    v4_cidr_blocks = ["192.168.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ================================================
# Пункт 2б. NAT-инстанс
# ================================================
resource "yandex_compute_instance" "nat-instance" {
  name        = "nat-instance"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1" # образ NAT-инстанса
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-sg.id]
    ip_address         = "192.168.10.254"
    nat                = true
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: yc-user\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh_authorized_keys:\n      - ${file(var.ssh_key_path)}"
  }
}
# ================================================
# Пункт 2в. Публичная ВМ для теста и прыжка на приватную
# ================================================
resource "yandex_compute_instance" "public-vm" {
  name        = "public-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-sg.id]
    nat                = true
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: yc-user\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh_authorized_keys:\n      - ${file(var.ssh_key_path)}\nruncmd:\n  - ufw disable\n  - systemctl stop ufw\n  - systemctl disable ufw"
  }
}
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}
# ================================================
# Пункт 3а. Приватная подсеть 192.168.20.0/24
# ================================================
resource "yandex_vpc_subnet" "private-subnet" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat-route.id
}
# ================================================
# Пункт 3б. Route table: весь трафик 0.0.0.0/0 → NAT-инстанс
# ================================================
resource "yandex_vpc_route_table" "nat-route" {
  name       = "nat-route-for-private"
  network_id = yandex_vpc_network.my-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat-instance.network_interface.0.ip_address
  }
}
# ================================================
# Пункт 3в. Приватная ВМ (без публичного IP)
# ================================================
resource "yandex_compute_instance" "private-vm" {
  name        = "private-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-sg.id]
    # nat не указываем — публичного IP не будет
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: yc-user\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh_authorized_keys:\n      - ${file(var.ssh_key_path)}\nruncmd:\n  - ufw disable\n  - systemctl stop ufw\n  - systemctl disable ufw"
  }
}
