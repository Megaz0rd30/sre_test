variable "Network" {
    type = object({
        main_vpc = string
        public_subnets = list(string)
        private_subnets = list(string)
    })
}

variable "Manifest" {
    type = object({
            builds = list(object({
                name = string
                builder_type = string
                build_time = number
                artifact_id = string
                packer_run_uuid = string
            }))
            last_run_uuid = string
        })
}

variable "Name" {
    type = string
}

variable "Tags" {
    type = map
}
