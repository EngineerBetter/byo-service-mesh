"service" = {
  "name" = "backend"

  "port" = 8080

  "connect" "sidecar_service" {
    "port" = 20000
  }
}

