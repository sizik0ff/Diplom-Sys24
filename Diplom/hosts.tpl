[all:vars]
ansible_ssh_common_args="-o ProxyCommand=\"ssh -q ubuntu@${bast_ip} -o IdentityFile=~/.ssh/bastion -o Port=22 -W %h:%p\""

[bastion]
bastion ansible_host=${bast_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/bastion

[nginx]
vm1 ansible_host=${vm1_ip}   ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_rsa
vm2 ansible_host=${vm2_ip}   ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/id_rsa

[zabbix]
zabbix  ansible_host=${zabbix_nat},${zabbix_ip}  ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/zabbix

[kib]
kib ansible_host=${kib_ip} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/kib

[elas]
elas ansible_host=${elas_ip} ansible_user=ubuntu ansible_ssh_private_key=~/.ssh/elas
