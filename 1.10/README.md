# Задание 1.10

Провести инсталляцию программного обеспечения

Алгоритм установки (текстовый документ)
(опубликовать в электронном портфолио, QR-код в отчете)

## Отчёт по заданию

### Установка и конфигурация Email сервера (алгоритм)

**Необходимо для воспроизведения**:

- выделенный сервер с Ubuntu 16 и новее;
- рабочий NGINX сервер;
- настроенный SSL;
- доменное имя (далее в тексте и командах - "ДОМЕН", напр., `https://ДОМЕН/about`).

Если Вы используете редактор vim, то следующей командой Вы можете заменить все упоминания о домене на свой домен:

`:%s/ДОМЕН/ваш домен (точки через \.)/g`

Либо же можете воспользоваться любой другой функции замены текста по шаблону.

Для того, чтобы не надо было вводить sudo каждый раз, следует выполнять аглоритм от имени суперпользователя (команда `su`).

#### Установка Postfix и предварительная настройка

Ввести следующую команду:

`DEBIAN_PRIORITY=low apt install postfix`

При установке выбрать следующую конфигурацию:

- **General type of mail configuration?**: `Internet Site`.
- **System mail name**: `ИМЯ@ДОМЕН` (в качестве имени можно выбрать любое имя, например, `info` или `admin`). Можно оставить пустым, чтобы отказаться от создания системного аккаунта.
- **Root and postmaster mail recipient**: `root`.
- **Other destinations to accept mail for**: продолжить со значением по умолчанию.
- **Force synchronous updates on mail queue?**: `No`.
- **Local networks**: продолжить со значением по умолчанию.
- **Mailbox size limit**: оставить `0`.
- **Local address extension character**: продолжить со значением по умолчанию.
- **Internet protocols to use**: выбрать все.

В случае допущения ошибки при конфигурации можно всё переконфигурировать следующей командой:

`dpkg-reconfigure postfix`

#### Настройка SPF

В настройках DNS добавить TXT запись для имени ДОМЕН со следующим контентом:

`v=spf1 mx ~all`

Установить SPF агент командой:

`apt install postfix-policyd-spf-python`

Открыть для редактирования следующий файл в предпочитаемом редакторе (например, `vim`).

`vim /etc/postfix/master.cf`

В конец файла внести следующие строки:

```cf
policyd-spf  unix  -       n       n       -       0       spawn
    user=policyd-spf argv=/usr/bin/policyd-spf
```

Открыть следующий файл:

`vim /etc/postfix/main.cf`

В конец файла внести следующие строки:

```cf
policyd-spf_time_limit = 3600
smtpd_recipient_restrictions =
   permit_mynetworks,
   permit_sasl_authenticated,
   reject_unauth_destination,
   check_policy_service unix:private/policyd-spf
```

Перезапустить Postfix сервис командой:

`systemctl restart postfix`

#### Настройка DKIM

Установить OpenDKIM следующей командой:

`apt install opendkim opendkim-tools`

Добавить пользователя `postfix` к OpenDKIM:

`gpasswd -a postfix opendkim`

Открыть следующий файл:

`vim /etc/opendkim.conf`

Раскомментировать следующие строки:

```conf
Canonicalization relaxed/simple
Mode sv
SubDomains no
```

Добавить после них следующие строки:

```conf
AutoRestart yes
AutoRestartRate 10/1M
Background yes
DNSTimeout 5
SignatureAlgorithm rsa-sha256
```

В конец файла добавить следующие строки:

```conf
UserID             opendkim
KeyTable           refile:/etc/opendkim/key.table
SigningTable       refile:/etc/opendkim/signing.table
ExternalIgnoreList  /etc/opendkim/trusted.hosts
InternalHosts       /etc/opendkim/trusted.hosts
```

Создать файловую структуру для OpenDKIM командой:

`mkdir -p /etc/opendkim/keys`

Настроить исключительные права доступа для `opendkim` командами:

```no
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw /etc/opendkim/keys
```

Создать следующий файл:

`vim /etc/opendkim/signing.table`

Со следующим содержанием:

`*@ДОМЕН default._domainkey.ДОМЕН`

Создать следующий файл:

`/etc/opendkim/key.table`

Со следующим содержанием:

`default._domainkey.ДОМЕН your-domain.com:default:/etc/opendkim/keys/ДОМЕН/default.private`

Создать следующий файл:

`/etc/opendkim/trusted.hosts`

Со следующим содержанием:

```hosts
127.0.0.1
localhost
YOU_SERVER_IP_ADDRESS
*.ДОМЕН
```

Создать директорию для домена:

`mkdir /etc/opendkim/keys/ДОМЕН`

Сгенерировать ключи командой:

`opendkim-genkey -b 2048 -d ДОМЕН -D /etc/opendkim/keys/ДОМЕН -s default -v`

Передать права на ключи `opendkim`:

`chown opendkim:opendkim /etc/opendkim/keys/ДОМЕН/default.private`

Вывести значения ключей для записи их в DNS командой (или любым другим способом):

`cat /etc/opendkim/keys/ДОМЕН/default.txt`

Публичный ключ будет начинаться со строки `default._domainkey IN TXT {` и завершаться на `} ; ----- DKIM key default for ДОМЕН`.

Скопировать его содержимое (всё, что внутри фигурных скобок), избавиться от кавычек и пробелов и внести как контент в новую TXT запись в настройках DNS для имени `default._domainkey`.

#### Подключение Postfix к OpenDKIM

Создать директорию для сокета OpenDKIM:

`mkdir /var/spool/postfix/opendkim`

Настроить владельцев директории:

`chown opendkim:postfix /var/spool/postfix/opendkim`

Открыть следующий файл:

`vim /etc/opendkim.conf`

Найти следующую строку:

`Socket local:/var/run/opendkim/opendkim.sock`

Заменить её на следующую строку:

`Socket local:/var/spool/postfix/opendkim/opendkim.sock`

Открыть следующий файл:

`vim /etc/default/opendkim`

Найти следующую строку:

`SOCKET="local:/var/run/opendkim/opendkim.sock"`
<br>**_или_**<br>
`SOCKET=local:$RUNDIR/opendkim.sock`

Заменить её на следующую строку:

`SOCKET="local:/var/spool/postfix/opendkim/opendkim.sock"`

Открыть следующий файл:

`vim /etc/postfix/main.cf`

Добавить следующие строки в конец файла:

```cf
milter_default_action = accept
milter_protocol = 6
smtpd_milters = local:opendkim/opendkim.sock
non_smtpd_milters = $smtpd_milters
```

Перезапустить службы `opendkim` и `postfix`:

`systemctl restart opendkim postfix`

#### Настройка портов и TLS

Открыть порты для отправки Email следующими командами:

```sh
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 465/tcp
```

Открыть следующий файл:

`vim /etc/postfix/main.cf`

Добавить следующие строки в конец файла:

```cf
smtpd_tls_auth_only = no
smtpd_tls_loglevel = 1
smtpd_tls_mandatory_ciphers = high
smtpd_tls_mandatory_exclude_ciphers = aNULL, MD5
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_received_header = yes
smtpd_tls_security_level = encrypt
smtpd_tls_session_cache_timeout = 3600s
smtp_tls_note_starttls_offer = yes
smtp_tls_security_level = may
tls_random_source = dev:/dev/urandom
```
