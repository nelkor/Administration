# Сценарий настройки сервера

Ubuntu 24.04, RuVDS.

C:/Users/a.tutunnik/.ssh/config:

```
Host oc
  Hostname 194.00.00.127
  User root
  Port 22
```

Сменить пароль:

```bash
passwd
```

Удалить помехи bash-конфигу:

```bash
rm .bash_* bash*
```

Обновить репозиторий:

```bash
apt update
```

Установить lsof:

```bash
apt install lsof
```

Установить VIM:

```bash
apt install vim -y
```

Отключить bell:

```bash
echo "set bell-style none" > .inputrc
```

Сменить порт SSH:

```bash
vim /etc/ssh/sshd_config
systemctl daemon-reload
service ssh restart
```

NVM больше не подходит. Ставим системный Nodejs.
Добавить в APT: https://deb.nodesource.com

Установить Git:

```bash
apt install git -y
```

Первоначальная настройка Git:

```bash
git config --global user.name "nelkor"
git config --global user.email "nelkor@proton.me"
git config --global pull.rebase true
```

Создать SSH ключи:

```bash
ssh-keygen -t ed25519
```

Прокинуть *.pub-ключ в GitHub.

Добавить https://github.com в "known hosts":

```bash
ssh -T git@github.com
```

Установить GitHub CLI:
https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian

Авторизоваться в GitHub CLI, выбрать HTTPS:

```bash
gh auth login
```

Устанавливаем Open Claw:

```bash
npm i -g openclaw@latest
```

> Этот баг уже исправлен 🔽

Перед онбордингом надо подготовить Gateway Service.
Скорее всего, проблема только при установке под `root`:

Смотрим, где находится бинарник `openclaw`:

```bash
command -v openclaw
```

Например, `/root/.nvm/versions/node/v22.22.0/bin/openclaw`.
Создаём файл `~/.config/systemd/user/openclaw-gateway.service`:

```
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/root/.nvm/versions/node/v22.22.0/bin/openclaw gateway run
Restart=on-failure
RestartSec=2
WorkingDirectory=%h

[Install]
WantedBy=default.target
```

И активируем сервис:

```bash
systemctl --user daemon-reload
systemctl --user enable --now openclaw-gateway.service
```

> Если баг пофиксят, от этой секции можно избавиться.

В `.bashrc` Добавляем: `export OPENROUTER_API_KEY=sk-or-v1-42222222222222222`

Теперь можно перейти к онбордингу:

```bash
openclaw onboard --install-daemon
```

Для починки используем:

```bash
openclaw doctor --fix
```

Для перезагрузки Gateway:

```bash
openclaw gateway restart
```

Узнать файл конфига:

```bash
openclaw config file
```

Узнать раздел конфига:

```bash
openclaw config get tools
```

Задать профиль инструментов:

```bash
openclaw config set tools.profile "full"
```

Посмотреть агентов в конфиге:

```bash
openclaw config get agents
```

Добавляем вручную в `models` новую модель:

```
"openrouter/anthropic/claude-opus-4.6": {}
```

Устанавливаем Opus в качестве основного субагента:

```bash
openclaw config set agents.defaults.subagents.model "openrouter/anthropic/claude-opus-4.6"
```

Закрываем боту группы в Телеграме (в конфиге):

```
channels:
  telegram:
    groupPolicy: "disabled"
```

## Heartbeat

На текущий момент Heartbeat забагованный. Лучше отключить его:

```
openclaw config set agents.defaults.heartbeat.every "0m"
```

И установить `cron`:

```bash
openclaw cron add \
  --name "hb-10m-internal" \
  --cron "*/10 * * * *" \
  --session isolated \
  --message "Read HEARTBEAT.md in the workspace"
```

Крон-задачи можно проверять:

```bash
openclaw cron list
openclaw cron runs --id <jobId> --limit 20
```

Web Search:

Добавить в `tools`: `"allow": ["web_search"],`, а также:

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

Google Chrome:

```bash
wget -O /tmp/google-chrome-stable_current_amd64.deb \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt update
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
google-chrome-stable --version
```

В конфиге рядом с `agents`:

```
"browser": {
  "headless": true,
  "noSandbox": true,
  "defaultProfile": "openclaw",
  "executablePath": "/usr/bin/google-chrome-stable"
},
```

Можно включать браузер, чтобы бот сразу его использовал.

```bash
openclaw browser --browser-profile openclaw start
openclaw browser --browser-profile openclaw stop
```

Установить oc-state:

```bash
mv oc-state.bash /usr/local/bin/oc-state
chmod +x /usr/local/bin/oc-state
```
