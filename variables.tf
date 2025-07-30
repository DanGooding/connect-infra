variable "project_name" {
  description = "tag applied to all resources"
  type        = string
  default     = "connect"
}

variable "domain_certificate_arn" {
  description = "certificate of public domain for the site"
  type        = string
  default     = "arn:aws:acm:eu-west-2:196481062593:certificate/4ece37fb-0fe4-49d9-8929-65354870ca46"
}

variable "static_service_port" {
  description = "port exposed by static webserver container"
  type        = number
  default     = 80
}

variable "api_service_port" {
  description = "port exposed by api server container"
  type        = number
  default     = 3000
}

variable "db_credentials" {
  description = "configures connectivity to db - the cluster, database, and username"
  type = object({
    name = string
    user = string
    url  = string
  })
  default = {
    name = "connect"
    user = "api2"
    url  = "mongodb+srv://cluster0.649fjz8.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
  }
}

variable "api_service_container_image_tag" {
  description = "container image to run for API service"
  type        = string
  default     = "6d877e3688db18505ba766310425e49095da550a"
}

variable "static_service_container_image_tag" {
  description = "container image to run for static webserver"
  type        = string
  default     = "6d877e3688db18505ba766310425e49095da550a"
}

variable "github_repo" {
  description = "github repository that actions run in"
  type = string
  default = "DanGooding/connect"
}
