data "external" "my_public_ip" {
    program = ["sh", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

locals {
    last_ami = [for x in var.Manifest.builds: x.artifact_id if x.packer_run_uuid == var.Manifest.last_run_uuid]
    current_ami = split(":",local.last_ami[0])[1]
}



###################### SSH KEY GENERATOR ##############################
resource "tls_private_key" "ssh_rsa_keyschain" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "keypair_${var.Name}"
  public_key = tls_private_key.ssh_rsa_keyschain.public_key_openssh
}
##################### SECURITY GROUPS #############################
resource "aws_security_group" "application_loadbalancer_sg" {
    name        = "alb_sg_${var.Name}"
    vpc_id      = var.Network.main_vpc

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound traffic.
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge(var.Tags,{
        Name = "alb_sg_${var.Name}"
    })
}

resource "aws_security_group" "bastion_sg" {
  name = "sg_public_bastion_${var.Name}"
  vpc_id = var.Network.main_vpc
}


resource "aws_security_group" "private_sg" {
    name = "sg_private_${var.Name}"
    vpc_id = var.Network.main_vpc

    ingress {
        protocol = "tcp"
        from_port = 22
        to_port = 22
        security_groups = [aws_security_group.bastion_sg.id]
    }

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.application_loadbalancer_sg.id]
    }

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
}

resource "aws_security_group_rule" "rule_egress_bastion" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = aws_security_group.private_sg.id
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "rule_ingress_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.my_public_ip.result.ip}/32"]
  security_group_id = aws_security_group.bastion_sg.id
}



###################### BASTION SETUP ##############################



resource "aws_instance" "public_ec2" {
    ami           = "ami-01d08089481510ba2"
    instance_type = "t2.micro"
    key_name = aws_key_pair.ssh_key_pair.key_name
    subnet_id = var.Network.public_subnets[0]
    associate_public_ip_address = true

    vpc_security_group_ids = [ aws_security_group.bastion_sg.id]

    tags = merge(var.Tags,{
        Name = "ec2_${var.Name}_public"
    })
}

###################### ALB SETUP ##############################



resource "aws_alb" "application_loadbalancer" {
    name            = "alb-${var.Name}"
    security_groups = [aws_security_group.application_loadbalancer_sg.id]
    subnets         = var.Network.public_subnets
    tags = merge(var.Tags,{
        Name = "alb-${var.Name}"
    })
}

resource "aws_alb_target_group" "target_group_alb" {
    name     = "tgt-group-alb-${var.Name}"
    port     = 80
    protocol = "HTTP"
    vpc_id   = var.Network.main_vpc
    load_balancing_algorithm_type = "round_robin"
    # Alter the destination of the health check to be the login page.
    health_check {
        path = "/"
        port = 80
    }
}

resource "aws_alb_listener" "listener_http" {
    load_balancer_arn = "${aws_alb.application_loadbalancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.target_group_alb.arn}"
        type             = "forward"
    }
}



###################### PRIVATE SETUP ##############################


resource "aws_network_interface" "private_nic" {
    count = length(var.Network.private_subnets)
    subnet_id   = element(var.Network.private_subnets,count.index)
    security_groups = [ aws_security_group.private_sg.id] 
    tags = merge(var.Tags,{
        Name = "prvt_nic_${var.Name}_ec2"
    })
}


resource "aws_instance" "private_ec2" {
    count = length(var.Network.private_subnets)
    ami           = local.current_ami
    instance_type = "t2.micro"
    key_name = aws_key_pair.ssh_key_pair.key_name
    network_interface {
        network_interface_id = aws_network_interface.private_nic[count.index].id
        device_index         = 0
    }

    tags = merge(var.Tags,{
        Name = "ec2_${var.Name}_private"
    })
}


#################### ALB x PRIVATE INSTANCES ##################################

resource "aws_lb_target_group_attachment" "private_instances_alb" {
    count = length(aws_instance.private_ec2)
    target_group_arn = aws_alb_target_group.target_group_alb.arn
    target_id        = aws_instance.private_ec2[count.index].id
    port             = 80
}


