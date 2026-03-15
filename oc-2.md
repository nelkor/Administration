# Сценарий настройки сервера

Ubuntu 24.04, RuVDS.

## Меняем пароль root

```bash
passwd
```

На всякий случай.

## Создаём пользователя

```bash
adduser openclaw
```

Выдаём пользователю `openclaw` неограниченные sudo-права:

```bash
usermod -aG sudo openclaw && \
echo 'openclaw ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/openclaw && \
chmod 440 /etc/sudoers.d/openclaw
```

## Заходим на сервер

Пишем в файле `~/.ssh/config`:

```
Host oc
  HostName 192.168.1.100
  User openclaw
  Port 22
```

Подключаемся по SSH:

```bash
ssh oc
```

## Готовим систему

Отключаем Bell:

```bash
echo "set bell-style none" > ~/.inputrc
```

Устанавливаем полезные вещи:

```bash
sudo apt update && \
sudo apt install -y vim git lsof ffmpeg && \
sudo loginctl enable-linger openclaw
```

Устанавливаем Google Chrome:

```bash
wget -O /tmp/google-chrome-stable_current_amd64.deb \
https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
sudo apt update && \
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb && \
google-chrome-stable --version
```

Устанавливаем ключ Open Router:

```bash
mkdir ~/.openclaw && vim ~/.openclaw/.env
```

`export OPENROUTER_API_KEY=`

Меняем порт SSH:

```bash
sudo vim /etc/ssh/sshd_config
```

```bash
sudo service ssh restart && sudo reboot
```

## Устанавливаем Open Claw

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

## Нормализуем конфиг

### Раздел "tools"

Меняем "profile" на "full". Рядом с "profile" добавляем:

```
"web": {
  "search": {
    "provider": "perplexity",
    "perplexity": {
      "baseUrl": "https://openrouter.ai/api/v1",
      "model": "perplexity/sonar-pro"
    }
  }
}
```

### Раздел "agents"

Можно удалить лишнюю модель из "models". Рядом с "models" добавляем:

```
"memorySearch": {
  "enabled": false
},
"heartbeat": {
  "every": "0m"
}
```

### Раздел "channels"

Устанавливаем `telegram.groupPolicy` в "disabled".

### Раздел "browser"

Добавляем раздел "browser":

```
"browser": {
  "headless": true,
  "defaultProfile": "openclaw",
  "executablePath": "/usr/bin/google-chrome-stable"
}
```

## Перезагружаем Gateway

```bash
openclaw gateway restart
```
