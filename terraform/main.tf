"# Terraform configuration" # terraform/main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = "ru-central1-a"
}

# Создаем сеть
resource "yandex_vpc_network" "monitoring_network" {
  name = "monitoring-network"
}

# Создаем подсеть
resource "yandex_vpc_subnet" "monitoring_subnet" {
  name           = "monitoring-subnet"
  network_id     = yandex_vpc_network.monitoring_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
}

# ВМ для мониторинга (Prometheus + Grafana)
resource "yandex_compute_instance" "monitoring_server" {
  name        = "monitoring-server"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.monitoring_subnet.id
    nat       = true # Даем внешний IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  labels = {
    role = "monitoring"
  }
}

# ВМ - "цель" для мониторинга
resource "yandex_compute_instance" "target_server" {
  name        = "target-server"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.monitoring_subnet.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  labels = {
    role = "target"
  }
}