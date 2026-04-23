terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "docker" {
  # Auto-detects Docker socket on Linux (unix://) and Windows (npipe://)
}

resource "null_resource" "docker_build_app" {
  provisioner "local-exec" {
    command = "docker build -f Dockerfile_app -t tp-web-app:latest ."
  }

  triggers = {
    dockerfile = filemd5("${path.module}/Dockerfile_app")
    index_html = filemd5("${path.module}/index.html")
  }
}

resource "docker_image" "postgres_image" {
  name         = "postgres:latest"
  keep_locally = true
}

resource "docker_container" "db_container" {
  name  = "tp-db-postgres"
  image = docker_image.postgres_image.image_id
  ports {
    internal = 5432
    external = 5432
  }
  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]
}

resource "docker_image" "app_image" {
  name           = "tp-web-app:latest"
  keep_locally   = true

  depends_on = [null_resource.docker_build_app]
}

resource "docker_container" "app_container" {
  name       = "tp-app-web"
  image      = docker_image.app_image.image_id
  depends_on = [docker_container.db_container]
  ports {
    internal = 80
    external = var.app_port_external
  }
}
