### Описание провайдера

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

### Токен YC

provider "yandex" {
  token     = "${var.token_id}"
  cloud_id  = "${var.cloud_id}"
  folder_id = "${var.folder_id}"
  zone      = "${var.zone_a}"
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}


### Server 1   

resource "yandex_compute_instance" "vm-1" {

  name ="vm1"
    zone = "${var.zone_a}" 
    platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private1.id}"
    ip_address         = "192.168.10.10"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/id_rsa.pub")}"
  }
}


### Server 2 

resource "yandex_compute_instance" "vm-2" {

    name ="vm2"
    zone = "${var.zone_b}" 
    platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private2.id}"
    ip_address         = "192.168.20.10"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/id_rsa.pub")}"
  }
}



### Настройки таргет группы 


resource "yandex_alb_target_group" "tg-1" {
  name = "tg-1"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private1.id}"
    ip_address = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private2.id}"
    ip_address = "${yandex_compute_instance.vm-2.network_interface.0.ip_address}"
  }
}


# Backend group

resource "yandex_alb_backend_group" "backend-group" {
  name                     = "backend-group"

  http_backend {
    name                   = "bd-1"
    weight                 = 1  
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.tg-1.id]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "router" {
  name = "router"
}

resource "yandex_alb_virtual_host" "router-host" {
  name           = "router-host"
  http_router_id = yandex_alb_http_router.router.id
  route {
    name = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group.id
        timeout          = "3s"
      }
    }
  }
}




### Сетевой балансировщик

resource "yandex_alb_load_balancer" "alb-1" {
  name        = "alb-1"
  network_id  = "${yandex_vpc_network.network-1.id}"
  security_group_ids = [yandex_vpc_security_group.load-balancer-sg.id, yandex_vpc_security_group.private-sg.id] 
  
  allocation_policy {
    location {
      zone_id   = "ru-central1-d"
      subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    }
  }

  
  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}


### Мониторинг и логи 

### Zabbix 

resource "yandex_compute_instance" "zabbix" {

  name = "zabbix"
  zone = "${var.zone_d}" 

  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 16
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address = "192.168.50.10"    
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/zabbix.pub")}"
  }
}

### Elasticsearch

resource "yandex_compute_instance" "elas" {

  name = "elas"
  zone = "${var.zone_d}" 

  platform_id = "standard-v3"

  resources {
    cores  = 4
    memory = 8
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 16
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private3.id}"
    security_group_ids = [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.elasticsearch-sg.id]
    ip_address = "192.168.30.10"
  }
    metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/elk.pub")}"
  }
}  

### Kibana 

resource "yandex_compute_instance" "kib" {

  name = "kib"
  zone = "${var.zone_d}" 

  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 16 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address         = "192.168.50.20"  
    nat       = true
    security_group_ids =  [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/kib.pub")}"
  }
}

### Bastion 

resource "yandex_compute_instance" "bast" {

  name = "bast"
  zone = "${var.zone_d}" 

  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction= 20
  }

  #  scheduling_policy {
  #  preemptible = true
  #}

  boot_disk {
    initialize_params {
      image_id = "fd84ocs2qmrnto64cl6m"
      size = 10 
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    security_group_ids =[yandex_vpc_security_group.bastion-sg.id]
    nat = true
}

  metadata = {
    ssh-keys = "ubuntu:${file("/home/sizik0ff/.ssh/bastion.pub")}"
  }


}

# Выводы 

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}

output "internal_ip_address_zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "external_ip_address_zabbix" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "internal_ip_address_bastion" {
  value = yandex_compute_instance.bast.network_interface.0.nat_ip_address
}

output "internal_ip_address_kib" {
  value = yandex_compute_instance.kib.network_interface.0.nat_ip_address
}

output "internal_ip_address_elas" {
  value = yandex_compute_instance.elas.network_interface.0.nat_ip_address
}
