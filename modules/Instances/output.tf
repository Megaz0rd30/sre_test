output "Private_Instances_IP_Addresses" {
    value = [for x in aws_network_interface.private_nic: x.private_ip]
}

output "Bastion_Host_IP_address" {
    value = aws_instance.public_ec2.public_ip
}

output "Load_balancer_HTTP_DNS" {
    value = aws_alb.application_loadbalancer.dns_name
}

output "SSH_key_Content" {
    value = nonsensitive(tls_private_key.ssh_rsa_keyschain.private_key_pem)
}

output "Usernames" {
    value = "ubuntu"
}