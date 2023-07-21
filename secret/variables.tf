variable "name" {}

variable "site" {}

variable "scopes" {
  type = list(string)
}

variable "labels" {
  type = map(string)
}
