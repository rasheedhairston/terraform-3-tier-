
variable "cidr_block" {
  type = string
  default = "10.0.0.0/16"

}




variable "public_cidr" {
  default = "10.0.1.0/24"
  type = string
}

variable "private_cidr" {
  default = "10.0.2.0/24"
  type = string
}

variable "database_cidr" {
  default = "10.0.3.0/24"
  type = string
}
