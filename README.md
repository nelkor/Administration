# Administration
Administration Ubuntu like a baws

### Windows docker switch

bcdedit /set hypervisorlaunchtype auto
bcdedit /set hypervisorlaunchtype off

### Поменять порт SSH

vim /etc/ssh/sshd_config

"#Port 22" -> "Port 1234"

systemctl restart ssh

### Создание и настройка пользователя

useradd -m username  
usermod -s /bin/bash username  
passwd username

### Выдать пользователю sudo

usermod -aG sudo username

### Пример конфига PHP-сокета

[username]  

user = username  
group = username  

listen = /var/www/username/php7.2-fpm.sock  

listen.owner = www-data  
listen.group = www-data  

pm = dynamic  

pm.max_children = 5  
pm.start_servers = 2  
pm.min_spare_servers = 1  
pm.max_spare_servers = 3  

### Пример конфига NGINX (простой)

server {  

    listen 80;  

    server_name example.com;  

    root /var/www/username/www;  

    index index.php;  

    error_log /var/www/username/log/error.log;  
    access_log /var/www/username/log/access.log;  

    location / {  
        try_files $uri $uri/ =404;  
    }  

    location ~ \.php$ {  
        include snippets/fastcgi-php.conf;  

        fastcgi_pass unix:/var/www/username/php7.2-fpm.sock;  
    }  
}  

server {  

    listen 80;  
    server_name www.example.com;  
    return 301 $scheme://example.com$request_uri;  
}  

### Пример конфига NGINX (посложнее)

server {  

    listen 80;  

    server_name example.com;  

    root /var/www/username/www;  

    index index.html;  

    error_log /var/www/username/log/www.error.log;  
    access_log /var/www/username/log/www.access.log;  

    location / {  
      try_files $uri $uri/ /index.html;  
    }  
}  

server {  

    listen 80;  
    server_name www.example.com;  
    return 301 $scheme://example.com$request_uri;  
}  

server {  

    listen 80;  
    
    server_name api.example.com;  

    root /var/www/username/api;  

    error_log /var/www/username/log/api.error.log;  
    access_log /var/www/username/log/api.access.log;  

    location / {  
      add_header Access-Control-Allow-Origin http://example.com;  
      include fastcgi_params;  
      fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;  
      fastcgi_param SCRIPT_FILENAME $document_root/index.php;  
    }  
}  

### Пример конфига NGINX (микрофронтенды)

server {  

    listen 443 ssl;  

    server_name example.com;  

    ssl_certificate /etc/nginx/ssl/example.com.cer;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    root /var/www/domain;  

    error_log /var/www/username/log/www.error.log;  
    access_log /var/www/username/log/www.access.log;  

    location ~ ^/news/. {
      try_files $uri $uri/ /news/index.html;
    }

    location ~ ^/common/. {
      try_files $uri $uri/ =404;
    }

    location / {  
      root /var/www/domain/main;

      try_files $uri $uri/ /index.html;
    }  
}  

### Пример конфига NGINX (http + ws)

```
server {  
  listen 443 ssl;  

  server_name nelkor.ru;  

  ssl_certificate /etc/nginx/ssl/nelkor.ru.cer;  
  ssl_certificate_key /etc/nginx/ssl/nelkor.ru.key;  

  root /var/www/artem/www;  

  index index.html;  

  error_log /var/www/artem/log/www.error.log;  
  access_log /var/www/artem/log/www.access.log;  

  location ~ ^/api/. {  
    proxy_pass http://localhost:3060;  
  }  

  location ~ ^/realtime-connection {  
    proxy_pass http://localhost:3060;  
    proxy_http_version 1.1;  
    proxy_set_header Upgrade $http_upgrade;  
    proxy_set_header Connection "upgrade";  
  }  

  location / {  
    try_files $uri $uri/ /index.html;  
  }  
}  

server {  
  listen 80;  
  server_name www.nelkor.ru;  
  return 301 https://nelkor.ru$request_uri;  
}  

server {  
  listen 80;  
  server_name nelkor.ru;  
  return 301 https://nelkor.ru$request_uri;  
}  

server {  
  listen 443 ssl;  
  server_name www.nelkor.ru;  
  return 301 https://nelkor.ru$request_uri;  
}  
```
