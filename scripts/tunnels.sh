while getopts "qs" opt; do
  case $opt in
    s)
      echo "Starting tunnel"
      ssh                             \
        -L 8200:$MANAGER_0_IP:8200    \
        -L 8400:$MANAGER_0_IP:8400    \
        -L 8500:$MANAGER_0_IP:8500    \
        -L 4646:$MANAGER_0_IP:4646    \
        -L 9999:$WORKER_0_IP:9999     \
        -i ~/misc/keys/abhaya-aws.pem \
        ubuntu@$BASTION_IP            \
        -N -f -M                      \
        -S ~/.ssh/hashi-control-path
      ;;
    q)
      echo "Killing tunnel"
      ssh -S ~/.ssh/hashi-control-path \
        -O exit ubuntu@$BASTION_IP
      ;;
  esac
done
