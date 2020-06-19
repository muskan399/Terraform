provider "kubernetes" {
  config_context_cluster   = "minikube"
}
resource "kubernetes_replication_controller" "rc" {
  metadata {
    name = "myrc1"
  }

  spec {
    replicas = 1
    selector = {
      env = "prod"
      dc = "US"
    }
    template {
      metadata {
        labels = {
         env = "prod"
         dc = "US" 
        }
      }

      spec {
        container {
          image = "vimal13/apache-webserver-php"
          name  = "mycont1"

 }

      }
    }
  }
}
