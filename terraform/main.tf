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

# Создаем сеть в другой зоне
resource "yandex_vpc_network" "monitoring_network" {
  name = "monitoring-network-2"
}

resource "yandex_vpc_subnet" "monitoring_subnet" {
  name           = "monitoring-subnet-2"
  network_id     = yandex_vpc_network.monitoring_network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  zone           = "ru-central1-b"
}

# Одна ВМ для мониторинга
resource "yandex_compute_instance" "monitoring_server" {
  name        = "monitoring-server"
  description = "Prometheus + Grafana monitoring"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.monitoring_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  labels = {
    project = "devops-monitoring"
    owner   = "nikit"
  }
}