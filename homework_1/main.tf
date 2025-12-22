provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "net" {
  name = "terraform-net"
}

# ---------- Public subnet ----------
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "nat" {
  name = "nat-instance"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 20
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.public.id
    ip_address  = "192.168.10.254"
    nat         = true
  }

  metadata = {
    serial-port-enable = var.metadata["serial-port-enable"]
    ssh-keys           = var.metadata["ssh-keys"]
  }
}

resource "yandex_compute_instance" "public_vm" {
  name = "terraform-vm"
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    serial-port-enable = var.metadata["serial-port-enable"]
    ssh-keys           = var.metadata["ssh-keys"]
  }
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-rt"
  network_id = yandex_vpc_network.net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

# ---------- Private subnet ----------
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.20.0/24"]

  route_table_id = yandex_vpc_route_table.private_rt.id
}

resource "yandex_compute_instance" "private_vm" {
  name = "private-vm"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
  }

  metadata = {
    serial-port-enable = var.metadata["serial-port-enable"]
    ssh-keys           = var.metadata["ssh-keys"]
  }
}
