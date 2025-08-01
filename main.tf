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

