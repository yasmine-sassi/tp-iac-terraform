output "db_container_name" {
  value = docker_container.db_container.name
}

output "app_access_url" {
  value = "http://localhost:${docker_container.app_container.ports[0].external}"
}

output "db_connection_info" {
  value = "postgresql://${var.db_user}@localhost:5432/${var.db_name}"
}