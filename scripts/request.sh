while true; do 
  curl -H "Host: hashipy.com" http://$ALB/version
  sleep 1
done
