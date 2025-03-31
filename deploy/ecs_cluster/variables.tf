variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to add to resources"
}

variable "image_name" {
  type        = string
  default     = "ghcr.io/kcdubois/flask-eris:latest"
  description = "Image name to use for task definition"
}
