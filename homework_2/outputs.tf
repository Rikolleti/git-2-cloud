output "image_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.test.bucket}/${yandex_storage_object.img.key}"
}
