provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# ---------- Object Storage ----------
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "netology-cipher"
  default_algorithm = "AES_128"
  rotation_period   = "720h"
}

resource "yandex_storage_bucket" "test" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read        = true
    list        = false
    config_read = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "img" {
  bucket = yandex_storage_bucket.test.bucket
  key    = "image.jpg"
  source = "image.jpg"
  acl    = "public-read"
}
# ---------- VPC ----------
resource "yandex_vpc_network" "net" {
  name = "net"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# ---------- Single VM ----------
resource "yandex_compute_instance" "vm1" {
  name        = var.vm_name
  platform_id = "standard-v1"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    serial-port-enable = var.metadata["serial-port-enable"]
    ssh-keys           = var.metadata["ssh-keys"]

    user-data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - apache2

      write_files:
        - path: /var/www/html/index.html
          permissions: "0644"
          content: |
            <html>
            <body>
              <h1>Hello</h1>
              <img src="https://storage.yandexcloud.net/${yandex_storage_bucket.test.bucket}/${yandex_storage_object.img.key}">
            </body>
            </html>

      runcmd:
        - systemctl enable apache2
        - systemctl restart apache2
    EOF
  }
}
