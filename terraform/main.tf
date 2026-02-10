terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "C:/Users/Nikit/.yc/sa-key.json"   # ← обязательно добавь это!
  cloud_id                 = var.yandex_cloud_id
  folder_id                = var.yandex_folder_id
  zone                     = "ru-central1-a"
}

# Сеть
resource "yandex_vpc_network" "monitoring_network" {
  name = "monitoring-network-tf"
}

# Подсеть
resource "yandex_vpc_subnet" "monitoring_subnet" {
  name           = "monitoring-subnet-tf"
  network_id     = yandex_vpc_network.monitoring_network.id
  v4_cidr_blocks = ["192.168.40.0/24"]
  zone           = "ru-central1-a"
}

data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"  # чтобы взять свежую версию Ubuntu 22.04 LTS
}

# ВМ для мониторинга
resource "yandex_compute_instance" "monitoring_server" {
  name        = "monitoring-tf"
  description = "Monitoring server created by Terraform"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  # Ресурсы
  resources {
    cores  = 2
    memory = 2  # GB
  }

  # Диск с Ubuntu 22.04
  boot_disk {
  initialize_params {
    image_id = data.yandex_compute_image.ubuntu_2204.id
    size     = 15
    type     = "network-hdd"  # явное указание
  }
}

  # Сетевой интерфейс
  network_interface {
    subnet_id = yandex_vpc_subnet.monitoring_subnet.id
    nat       = true  # Даём внешний IP
  }

  # SSH ключ для доступа
  metadata = {
  ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key_path))}"

  user-data = <<EOF
#cloud-config
package_update: true
package_upgrade: true

packages:
  - curl
  - ca-certificates
  - gnupg
  - lsb-release

runcmd:
  # Установка Docker
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - chmod a+r /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Включаем и запускаем Docker
  - systemctl enable docker
  - systemctl start docker

  # Добавляем пользователя ubuntu в группу docker
  - usermod -aG docker ubuntu

  # Проверяем установку
  - docker --version
  - docker compose version
EOF
}

  # Метки для удобства
  labels = {
    created-by = "terraform"
    project    = "devops-monitoring"
    owner      = "nikit"
  }
}

# IP адрес для подключения
output "vm_public_ip" {
  value       = yandex_compute_instance.monitoring_server.network_interface.0.nat_ip_address
  description = "Public IP address of monitoring server"
}

output "ssh_connection_command" {
  value       = "ssh ubuntu@${yandex_compute_instance.monitoring_server.network_interface.0.nat_ip_address}"
  description = "SSH command to connect to the server"
}
