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

resource "aws_dynamodb_table" "project_sapphire_inventory" {
  name           = "inventory"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AssetID"

  attribute {
    name = "AssetID"
    type = "N"
  }
  attribute {
    name = "AssetName"
    type = "S"
  }
  attribute {
    name = "age"
    type = "N"
  }
  attribute {
    name = "Hardware"
    type = "B"
  }
  global_secondary_index {
    name             = "AssetName"
    hash_key         = "AssetName"
    projection_type    = "ALL"
    
  }
  global_secondary_index {
    name             = "age"
    hash_key         = "age"
    projection_type    = "ALL"
    
  }
  global_secondary_index {
    name             = "Hardware"
    hash_key         = "Hardware"
    projection_type    = "ALL"
    
  }
}

resource "aws_dynamodb_table_item" "upload" {
  hash_key = aws_dynamodb_table.project_sapphire_inventory.hash_key
  table_name = aws_dynamodb_table.project_sapphire_inventory.name
  item = <<EOF
  {
    "AssetID": {"N": "1"},

    "AssetName": {"S": "printer"},

    "age": {"N": "5"},

    "Hardware": {"B": "true" }
  }
  EOF
}

resource "kubernetes_service" "webapp-service" {
  # Metadata for the Kubernetes Service
  metadata {
    # The name of the service
    name = "webapp-service"
  }

  # Service specification
  spec {
    # Selector to match the pods this service will route traffic to
    # This assumes your pods have the label `app: webapp`.
    selector = {
      app = "frontend"
    }

    # The type of service, in this case a NodePort
    type = "NodePort"

    # Define the service port
    port {
      # The port on the service itself (where traffic arrives)
      port = 8080

      # The port on the pods to which the traffic is forwarded
      target_port = 8080

      # The specific port on each node that exposes the service
      node_port = 30080
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      name = "frontend"
    }
  } 

  spec {
    replicas = 4
    selector {
      match_labels = {
        name = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          name = "frontend"
        }
      }
      spec {
        container {
          name  = "simple-webapp"
          image = "kodekloud/webapp-color:v1"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "docker_image" "php-httpd-image" {
  name = "php-httpd:challenge"
  build {
    path = "${path.cwd}/lamp_stack/php_httpd/"
    dockerfile = "Dockerfile"
    label = {
      challenge : "second"
    }
  }
}

resource "docker_image" "mariadb-image" {
  name = "mariadb:challenge"
  build {
    path = "${path.cwd}/lamp_stack/custom_db/"
    dockerfile = "Dockerfile"
    label = {
      challenge : "second"
    }
  }
}

resource "docker_network" "private_network" {
  name = "my_network"
  attachable = true
  labels {
    label = "challenge"
    value = "second"
  }
}

resource "docker_container" "php-httpd" {
  name  = "webserver"
  hostname = "php-httpd"
  image = docker_image.php-httpd-image.name
  networks_advanced {
    name = docker_network.private_network.name
  }
  ports {
    internal = 80
    external = 80
  }
  labels {
    label = "challenge"
    value = "second"
  }
  volumes {
    container_path = "/var/www/html"
    host_path = "${path.cwd}/lamp_stack/website_content/"
  }
}

resource "docker_container" "phpmyadmin" {
  name  = "db_dashboard"
  hostname = "phpmyadmin"
  image = "phpmyadmin/phpmyadmin"
  networks_advanced {
    name = docker_network.private_network.name
  }
  ports {
    internal = 80
    external = 8081
  }
  labels {
    label = "challenge"
    value = "second"
  }
  depends_on = [ docker_container.mariadb ]
  links  = [docker_container.mariadb.name]
}

resource "docker_container" "mariadb" {
  name  = "db"
  hostname = "db"
  image = docker_image.mariadb-image.name
  networks_advanced {
    name = docker_network.private_network.name
  }
  ports {
    internal = 3306
    external = 3306
  }
  labels {
    label = "challenge"
    value = "second"
  }
  env = [
    "MYSQL_ROOT_PASSWORD=1234",
    "MYSQL_DATABASE=simple-website",  
  ]
  volumes {
    volume_name = docker_volume.mariadb_volume.name
    container_path = "/var/lib/mysql"
  }
}

resource "docker_volume" "mariadb_volume" {
  name = "mariadb-volume"
}