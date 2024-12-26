
# module "configure_mimir" {
#   source     = "./modules/playbook"
#   depends_on = [module.acme_certs]

#   playbook          = "../ansible/observability-playbook.yml"
#   inventory         = local.logging
#   host_key_checking = false
#   private_key_file  = "./private_staging_key"
#   ansible_callback  = "default"
#   quiet             = true
#   extra_vars = {
#     validate_certificate = true
#     alias                = "mimir"
#     minio_buckets = [
#       {
#         name   = "mimir-object"
#         policy = "read-write"
#       },
#       {
#         name   = "mimir-block"
#         policy = "read-write"
#       }
#     ]
#     minio_users = [
#       {
#         buckets_acl = [
#           {
#             name   = "mimir-object"
#             policy = "read-write"
#           },
#           {
#             name   = "mimir-block"
#             policy = "read-write"
#           }
#         ]
#         name     = "mimir"
#         password = var.pve_password
#       },
#     ]
#     minio_root_user     = "root"
#     minio_root_password = var.pve_password
#     minio_url           = "https://${local.dns_names.minio}:{{ server_port }}"
#     minio_enable_tls    = true
#     server_port         = "9091"
#     object_storage = {
#       storage = {

#         backend = "s3"
#         s3 = {
#           endpoint          = local.dns_names.minio
#           access_key_id     = "mimir"
#           secret_access_key = "${var.pve_password}"
#           insecure          = false # False when using https
#           bucket_name       = "mimir-object"
#         }
#       }
#       block_storage = {
#         s3 = {
#           bucket_name = "mimir-block"
#         }
#       }
#     }
#   }
# }


