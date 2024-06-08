### Настройки сети 

### Настройка маршрутизации из локальной сети в интернет 

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

### Subnet private  / web-server-1 /

resource "yandex_vpc_subnet" "subnet-private1" {
  name           = "subnet-private1"
  description    = "subnet for web-server-1"
  zone           = "${var.zone_a}"
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

### Subnet private / web-server-2 / 

resource "yandex_vpc_subnet" "subnet-private2" {
  name           = "subnet-private2"
  description    = "subnet for web-server-2"
  zone           = "${var.zone_b}" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

### Subnet private / Elasticsearch / 

resource "yandex_vpc_subnet" "subnet-private3" {
  name           = "subnet-private3"
  description    = "subnet for elasticsearch"
  zone           = "${var.zone_d}" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}

### Subnet public / Zabbix / Kibana / Bastion / ALB


resource "yandex_vpc_subnet" "subnet-public1" {
  name           = "subnet-public1"
  description    = "subnet for services"
  zone           = "${var.zone_d}" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["192.168.50.0/24"]
}
