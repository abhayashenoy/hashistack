while getopts "qs" opt; do
  case $opt in
    s)
      echo "Starting tunnel"
      ssh                             \
        -L 8200:localhost:8200        \
        -L 8400:localhost:8400        \
        -L 8500:localhost:8500        \
        -L 4646:localhost:4646        \
        -L 9999:$WORKER_ONE_IP:9999   \
        -i ~/misc/keys/abhaya-aws.pem \
        ubuntu@$MASTER_IP             \
        -N -f -M                      \
        -S ~/.ssh/hashi-control-path
      ;;
    q)
      echo "Killing tunnel"
      ssh -S ~/.ssh/hashi-control-path \
         -O exit ubuntu@$MASTER_IP
      ;;
  esac
done



