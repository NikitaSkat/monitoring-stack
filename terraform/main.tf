terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89.0"
    }
  }
}

provider "yandex" {
  # Эти значения мы зададим в variables.tf
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = "ru-central1-a"
}

# Создаём сеть
resource "yandex_vpc_network" "monitoring_network" {
  name = "monitoring-network-tf"
}

# Создаём подсеть
resource "yandex_vpc_subnet" "monitoring_subnet" {
  name           = "monitoring-subnet-tf"
  network_id     = yandex_vpc_network.monitoring_network.id
  v4_cidr_blocks = ["192.168.40.0/24"]
  zone           = "ru-central1-a"
}

# Создаём ВМ для мониторинга
resource "yandex_compute_instance" "monitoring_server" {
  name        = "monitoring-tf"
  description = "Monitoring server created by Terraform"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  # Ресурсы (минимальные для экономии)
  resources {
    cores  = 2
    memory = 2  # GB
  }

  # Диск с Ubuntu 22.04
  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04 LTS
      size     = 15 # GB
    }
  }

  # Сетевой интерфейс
  network_interface {
    subnet_id = yandex_vpc_subnet.monitoring_subnet.id
    nat       = true  # Даём внешний IP
  }

  # SSH ключ для доступа
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  # Метки для удобства
  labels = {
    created-by = "terraform"
    project    = "devops-monitoring"
    owner      = "nikit"
  }
}

# Выводим IP адрес для подключения
output "vm_public_ip" {
  value       = yandex_compute_instance.monitoring_server.network_interface.0.nat_ip_address
  description = "Public IP address of monitoring server"
}

output "ssh_connection_command" {
  value       = "ssh ubuntu@${yandex_compute_instance.monitoring_server.network_interface.0.nat_ip_address}"
  description = "SSH command to connect to the server"
}
