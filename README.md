# Administration
Administration Ubuntu like a baws

### Поменять порт SSH

vim /etc/ssh/sshd_config

#Port 22 -> Port 1234

### Создание и настройка пользователя

useradd -m username
usermod -s /bin/bash username

### Выдать пользователю sudo

usermod -aG sudo username
