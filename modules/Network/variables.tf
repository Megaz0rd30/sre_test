variable "Network_CIDR" {
  type = string
}

variable "N_subnets" {
  type = number
  validation {
   condition     = var.N_subnets <= 6 && var.N_subnets >= 2
   error_message = "Number of Subnets must be greater than 2 and less than or equals 6"
 }
}

variable "Name" {
  type = string
}

variable "Tags" {
  type = map
}

