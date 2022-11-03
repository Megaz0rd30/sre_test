output "Network" {
    value = {
        main_vpc = aws_vpc.main_vpc.id
        public_subnets = [for x in slice(aws_subnet.vpc_subnets,0,local.N_public_subs): x.id]
        private_subnets = [for x in slice(aws_subnet.vpc_subnets,local.N_public_subs,length(aws_subnet.vpc_subnets)): x.id]
    }
}