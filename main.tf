resource "local_file" "games" {
  filename     = "/root/favorite-games"
  content  = "FIFA 21"
}

resource "random_pet" "other-pet" {
	      prefix = "Mr"
	      separator = "."
	      length = "1"
}

resource "random_string" "iac_random" {
  length = 10
  min_upper = 5
}

resource "local_file" "jedi" {
     filename = var.jedi["filename"]
     content = var.jedi["content"]
}

resource "time_static" "time_update" {
}

resource "local_file" "time" {
     filename = "/root/time.txt"
     content = "Time stamp of this file is ${time_static.time_update.id}"
}

resource "tls_private_key" "pvtkey" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "key_details" {
  filename="/root/key.txt"
  content="${tls_private_key.pvtkey.private_key_pem}"
}

resource "local_file" "whale" {
  filename="/root/whale"
  content="whale"
  depends_on = [ local_file.krill ]
}

resource "local_file" "krill" {
  filename="/root/krill"
  content="krill"
}