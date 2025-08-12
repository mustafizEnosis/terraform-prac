variable "name" {
     type = string
     default = "Mark"
  
}
variable "number" {
     type = bool
     default = true
  
}
variable "distance" {
     type = number
     default = 5
  
}

variable "length" {
    default = 12
  
}

variable "jedi" {
     type = map
     default = {
     filename = "/root/first-jedi"
     content = "phanius"
     }
  
}

variable "prefix" {
    default = "Mr"
}

variable "gender" {
     type = list(string)
     default = ["Male", "Female"]
}
variable "hard_drive" {
     type = map
     default = {
          slow = "HHD"
          fast = "SSD"
     }
}
variable "users" {
     type = set(string)
     default = ["tom", "jerry", "pluto", "daffy", "donald", "jerry", "chip", "dale"]

  
}

variable "filename" {
     type = string
}

variable "content" {
    default = "password: S3cr3tP@ssw0rd"
}
  
variable "media" {
  type = set(string)
  default = [ 
    "/media/tails.jpg",
    "/media/eggman.jpg",
    "/media/ultrasonic.jpg",
    "/media/knuckles.jpg",
    "/media/shadow.jpg",
      ]
  
}

variable "project_name" {
  type = string
  default = "storm"
}
variable "department" {
  type = string
  default = "finance"
}

variable "project_id" {
  description = "project id"
  default = "kkgcplabs01-043"
}

variable "region" {
  description = "region"
  default = "us-central1"
}

variable "tcp_port_list" {
  description = "List of TCP ports to open"
  type        = list(number)
  default     = [22, 80, 443, 3306]
}




