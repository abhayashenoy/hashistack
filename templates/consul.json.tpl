{
  "node_name": "${name}",
  "data_dir": "${data_dir}/consul",
  "bind_addr": "0.0.0.0",
  "server": true,
  "ui": true,
  "bootstrap_expect": 3,
  "client_addr": "0.0.0.0",
  "retry_join": ["${ip_other_1}", "${ip_other_2}"]
}
