packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
locals{
    timestamp_dt = formatdate("YYYYMMDDhhmm", timestamp())
}
source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.name}_${local.timestamp_dt}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "${var.name}"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
        inline = [
          "echo Updating and Upgrade Packages",
          "sudo apt update -y",
          "sudo apt upgrade -y",
          "echo Installing Nginx",
          "sudo apt install nginx -y",
          "sudo chmod 777 /var/www/html/index.nginx-debian.html",
          "echo \"Hello World at `date +%Y-%d-%m`\" > /var/www/html/index.nginx-debian.html",
        ]
  }

  post-processor "manifest" {
      output = "${var.manifest_path}/manifest_golden_image.json"
      strip_path = true
  }
}




