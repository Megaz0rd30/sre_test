terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
module "Golden_Base" {
  source = "./modules/Golden_Image"
  Manifest_path = "${abspath(path.root)}"
}

module "Network_Base" {
  source = "./modules/Network"
  Network_CIDR = var.Network_CIDR
  N_subnets = var.N_subnets
  Name = var.Name
  Tags = var.Tags
}

module "ec2_Instances" {
  source = "./modules/Instances"
  Network = module.Network_Base.Network
  Manifest = module.Golden_Base.Manifest
  Name = var.Name
  depends_on = [
    module.Golden_Base,
    module.Network_Base
  ]
  Tags = var.Tags
}

output "main" {
  value = {
    Private_Instances_IP_Addresses = module.ec2_Instances.Private_Instances_IP_Addresses
    Load_balancer_HTTP_DNS = module.ec2_Instances.Load_balancer_HTTP_DNS
    SSH_key_Content = module.ec2_Instances.SSH_key_Content
    Bastion_Host_IP_address = module.ec2_Instances.Bastion_Host_IP_address
    Usernames = module.ec2_Instances.Usernames
  }
}
