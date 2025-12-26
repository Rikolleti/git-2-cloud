provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_iam_service_account" "ig_sa" {
  name      = "ig-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "ig_sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
}
# ---------- Object Storage ----------
resource "yandex_storage_bucket" "test" {
  bucket = "azmamedov.26122025"

  folder_id = var.folder_id
  anonymous_access_flags {
    read        = true
    list        = false
    config_read = true
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
# ---------- Load Balancer  ----------
resource "yandex_lb_network_load_balancer" "nlb" {
  depends_on = [yandex_compute_instance_group.group1]
  name = "network-load-balancer-lamp"

  listener {
    name        = "http"
    port        = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.group1.load_balancer[0].target_group_id

    healthcheck {
      name = "http-check"
      http_options {
        port = 80
        path = "/"
      }
      interval            = 5
      timeout             = 2
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }
}
# ---------- VM group  ----------
resource "yandex_compute_instance_group" "group1" {
  name                = "test-ig"
  folder_id           = var.folder_id
  service_account_id  = yandex_iam_service_account.ig_sa.id
  deletion_protection = false
  instance_template {
    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 3
      }
    }
   network_interface {
     subnet_ids   = [yandex_vpc_subnet.public.id]
     nat         = true
   }
    metadata = {
      serial-port-enable = var.metadata["serial-port-enable"]
      ssh-keys = var.metadata["ssh-keys"]

	  user-data = <<-EOF
	    #cloud-config
	    write_files:
	      - path: /var/www/html/index.html
	        permissions: '0644'
	        content: |
	          <html>
	          <body>
	            <h1>Hello</h1>
	            <img src="https://storage.yandexcloud.net/${yandex_storage_bucket.test.bucket}/${yandex_storage_object.img.key}">
	          </body>
	          </html>
	    runcmd:
	      - systemctl restart apache2 || systemctl restart httpd
	  EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  load_balancer {
    target_group_name        = "target-group-lamp"
    target_group_description = "Целевая группа Network Load Balancer"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 2
  	http_options {
    	path = "/"
    	port = 80
  	}
    interval = 5
    timeout = 2
  }
}
