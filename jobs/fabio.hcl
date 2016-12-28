job "fabio" {
  datacenters = ["dc1"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "fabio" {
    task "fabio" {
      driver = "exec"
      config {
        command = "local/fabio-1.3.5-go1.7.4-linux_amd64"
      }

      artifact {
        source = "https://github.com/eBay/fabio/releases/download/v1.3.5/fabio-1.3.5-go1.7.4-linux_amd64"
        options {
          checksum = "sha256:e0d681fcc23e1408485e16e14c35a22865674e021fc17247ecf74ef5465a8fb0"
        }
      }


      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1

          port "http" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}
