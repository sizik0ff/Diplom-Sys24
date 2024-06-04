# Inventory file for Ansible

resource "local_file" "hosts" {
  content = templatefile("~/diplom/hosts.tpl",
    
    {
      vm1_ip = yandex_compute_instance.vm-1.network_interface[0].ip_address
      vm2_ip = yandex_compute_instance.vm-2.network_interface[0].ip_address
      zabbix_ip = yandex_compute_instance.zabbix.network_interface[0].ip_address
      zabbix_nat = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
      elas_ip = yandex_compute_instance.elas.network_interface[0].ip_address
      kib_ip = yandex_compute_instance.kib.network_interface[0].ip_address
      bast_ip = yandex_compute_instance.bast.network_interface.0.nat_ip_address
    
    }
  )
  filename = "/home/sizik0ff/diplom/ansible/hosts.cfg"
}