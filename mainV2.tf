resource "local_sensitive_file" "games" {
  filename     = "/root/favorite-games"
  content  = "FIFA 21" #This content won't be displayed in the execution plan
}
