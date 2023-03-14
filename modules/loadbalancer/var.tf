variable "internal" {
    type = string  
}
variable "type" {
    type = string  
}

variable "appname" {
    type = string
}

variable "env" {
    type = string
}

variable "tags" {
    type = map(string)
    default = {}
}
variable "subnets" {
    type = list(string)
}

variable "security_groups" {
    type = set(string)
}

variable "vpc_id" {
    type = string
}