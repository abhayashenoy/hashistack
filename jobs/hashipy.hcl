# Define a job called my-service
job "hashipy" {
  datacenters = ["dc1"]

  type = "service"

  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "web" {
    count = 5

    task "frontend" {
      driver = "exec"
      config {
        command = "/usr/bin/python3"
        args = ["local/server.py"]
      }
      artifact {
        source = "https://gist.githubusercontent.com/abhayashenoy/9b51dcf512ede0f68f846658fb3147de/raw/426614556f2a31111732cddc682e225b55c57759/server.py"
      }
      env {
        NODE_NAME = "${NOMAD_ALLOC_INDEX}"
        SERVER_PORT = "${NOMAD_PORT_http}"
      }
      service {
        name = "hashipy"
        tags = ["urlprefix-hashipy.com/"]
        port = "http"
        check {
          type = "http"
          path = "/health"
          interval = "10s"
          timeout = "2s"
        }
      }
      resources {
        cpu = 500
        memory = 128
        network {
          mbits = 1
          port "http" {
          }
        }
      }
    }
  }
}
