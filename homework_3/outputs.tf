output "vm_public_ip" {
  value = yandex_compute_instance.vm1.network_interface[0].nat_ip_address
}

output "image_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.test.bucket}/${yandex_storage_object.img.key}"
}
