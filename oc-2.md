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
usermod -aG sudo openclaw &&
echo 'openclaw ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/openclaw &&
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
sudo apt update &&
sudo apt install -y vim git lsof ffmpeg build-essential &&
sudo loginctl enable-linger openclaw
```

Устанавливаем Google Chrome:

```bash
wget -O /tmp/google-chrome-stable_current_amd64.deb \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
sudo apt update &&
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb &&
google-chrome-stable --version
```

Обновляем приглашение в `~/.bashrc`:

```bash
vim ~/.bashrc
```

Удаляем все блоки с `PS1=`, вместо них добавляем `PS1='\u@vds:\w\$ '`.

Меняем порт SSH:

```bash
sudo vim /etc/ssh/sshd_config
```

```bash
sudo service ssh restart && sudo reboot
```

Проверяем файл подкачки (если его нет, надо создать):

```bash
swapon --show
```

## Настраиваем доступы в Git/GitHub

Первоначальная настройка Git:

```bash
git config --global user.name "nelkor"
git config --global user.email "nelkor@proton.me"
git config --global pull.rebase true
```

Создаём SSH ключи:

```bash
ssh-keygen -t ed25519
```

Прокидываем *.pub-ключ в GitHub.
Добавим github.com в "known hosts":

```bash
ssh -T git@github.com
```

Устанавливаем GitHub CLI:
https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian

Авторизуемся в GitHub CLI, выбираем HTTPS + Classic PAT:

```bash
gh auth login
```

## Устанавливаем Node.js

Добавляем свежую версию в APT из
[NodeSource](https://nodesource.com/products/distributions).

Остался нерешённым вопрос — не подхватился глобальный каталог NPM пользователя.
Можно попробовать перезайти в систему и попрбовать `npm i -g npm`.
Если "нет прав", то:

```bash
mkdir -p ~/.npm-global &&
npm config set prefix ~/.npm-global &&
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
```

И перезайти в систему.

## Устанавливаем Open Claw

```bash
npm i -g openclaw@latest
```

Устанавливаем ключ Open Router:

```bash
mkdir ~/.openclaw && vim ~/.openclaw/.env
```

`OPENROUTER_API_KEY=`

Запускаем Wizard:

```bash
openclaw onboard --install-daemon
```

## Нормализуем конфиг

```bash
vim ~/.openclaw/openclaw.json
```

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
},
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
},
```

## Перезагружаем Gateway

В интерактивном режиме, после проверки доктором.

```bash
openclaw doctor
```

## Настраиваем пробуждения

Вместо Heartbeat используем `cron`.
Пока что не удалось найти способ заставить Heartbeat работать.

Для параметра `--to` спрашиваем User ID у бота.

```bash
openclaw cron add \
  --announce \
  --every 35m \
  --to 1500000000 \
  --light-context \
  --name hb-35m-test \
  --session isolated \
  --message "Read HEARTBEAT.md and follow it strictly"
```

Проверить задачи:

```bash
openclaw cron list
```

Удалить задачу:

```bash
openclaw cron remove task-id
```
