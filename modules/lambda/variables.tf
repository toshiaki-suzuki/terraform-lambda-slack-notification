variable "name" {
  type = string
}

variable "function_name" {
  type = string
}

variable "timeout" {
  type = number
}

variable "iam_policy" {
  type = any
}

variable "in_vpc" {
  type        = bool
  default     = false
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
}