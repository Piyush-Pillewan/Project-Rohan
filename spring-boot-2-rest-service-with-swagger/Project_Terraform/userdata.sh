user_data = base64encode(<<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Welcome to My Auto-Scaling Web Server</h1>" | sudo tee /usr/share/nginx/html/index.html
EOF
  )
