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

Сменить порт SSH:

```bash
vim /etc/ssh/sshd_config
systemctl daemon-reload
service ssh restart
```

Установить NVM и Node:
https://github.com/nvm-sh/nvm

Установить Git:

```bash
apt install git -y
```

Создать SSH ключи:

```bash
ssh-keygen -t ed25519
```

Прокинуть *.pub-ключ в GitHub.

Установить GitHub CLI:
https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian

Авторизоваться в GitHub CLI, выбрать HTTPS:

```bash
gh auth login
```

Устанавливаем Open Claw:

```bash
npm i -g openclaw@latest
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
