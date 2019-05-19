# Administration
Administration Ubuntu like a baws

### Поменять порт SSH

vim /etc/ssh/sshd_config

"#Port 22" -> "Port 1234"

service ssh restart

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

