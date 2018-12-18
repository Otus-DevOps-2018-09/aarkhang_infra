aarkhang_infra
==============
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-09/aarkhang_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-09/aarkhang_infra)

Otus DevOps 2018-09 Infrastructure repository.

Домашнее задание #10    Ansible-3
----------------------------------
### Что сделано
1. На основе плейбука ansible/db.yml создана роль ansible/roles/db
2. На основе плейбука ansible/app.yml создана роль ansible/roles/app
3. Плейбуки app.yml и db.yml изменены для использования созданных ролей
4. Проверена работа плейбука ansible/site.yml в инфраструктурах stage и prod.
5. Созданы окружения stage и prod для вызова плейбуков Ansible, для их настройки созданы групповые переменные.
6. В роли app и db добавлена задача по выводу названия окружения, в котором находится конфигурируемый хост.
7. Реорганизована структура каталога ansible.
8. Проверена работа плейбука ansible/playbooks/site.yml в окружениях stage и prod.
9. В плейбук ansible/playbooks/app.yml добавлен вызов коммьюнити-роли jdauphant.nginx.
10. С помощью nginx настроено обратное проксирование для нашего приложения и проверена его доступность на 80-ом порту.
11. Создан плейбук ansible/playbooks/users.yml, использующий файл с логинами и паролями пользователей ansible/environments/<окружение>/credentials.yml.
12. Создан секретный ключ ~/.ansible/vault.key и с помощью утилиты ansible-vault файлы credentials.yml зашифрованы.
13. Вызов плейбука users.yml добавлен в site.yml и проверена его работа в окружениях stage и prod.
14. Доработан скрипт dyninventory.py, созданный в ДЗ-9, для возможности его использования одновременно в двух окружениях.
15. Созданы скрипты inventory.sh для использование в качестве динамического инвентори для окружений stage и prod.
16. По подсказке И.Косолапова самописные скрипты динамического инвентори заменены на использование плагина gcp_compute:
  - в файлы terraform/modules/{app,db}/main.tf добавлены labels
  - созданы файлы динамических инвентори ansible/environments/{prod,stage}/inventory.gcp.yml
  - откорректироаны файлы ansible/environments/{prod,stage}/group_vars/app для получения IP-адреса db_host
  - в конфигурационном файле ansible.cfg изменено inventory по-умолчанию
17. Также попробовал использовать в качестве динамического инвентори terraform-inventory, из-за чего закомитил файл  ansible/environments/stage/tfinventory.sh. Оно тоже работает, но преимуществ перед gcp_compute я не увмдел.
18. С помощью trytravis настроены тесты Travis CI для проверки валидности шаблонов Packer, Terraform и синтаксиса плейбуков Ansible.

### Как запустить проект
- Клонировать репозиторий
- Построить с помощью packer образы ВМ, как описано в домашнем задании #9
- Запустить параллельно окружения stage и prod, как описано в домашнем задании  #7
- Закомментировать вызов плейбука users.yml в ansible/playbooks/site.yml либо создать собственный секретный ключ и пересоздать и зашифровать им собственные версии файлов credentials.yml.
- Перейти в каталог ansible и выполнить команды

```sh
$ ansible-playbook playbooks/site.yml
$ ansible-playbook -i environments/prod/inventory.gcp.yml  playbooks/site.yml
```

### Как проверить работоспособность приложения
Определить внешние адреса запущенных инстансов, например выпонив команду:
```
arh@zalman:/home/my/projects/otus/aarkhang_infra/ansible$ gcloud compute instances list
NAME          ZONE             MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
reddit-app-s  europe-north1-b  f1-micro                   10.166.0.3   35.228.9.114   RUNNING
reddit-db-s   europe-north1-b  f1-micro                   10.166.0.2   35.228.241.58  RUNNING
reddit-app    europe-west4-a   f1-micro                   10.164.0.3   35.204.35.210  RUNNING
reddit-db     europe-west4-a   f1-micro                   10.164.0.2   35.204.30.1    RUNNING
```
Перейти по ссылкам http://<reddit-app-external_ip> и http://<reddit-app-s-external_ip>


Домашнее задание #9    Ansible-2
----------------------------------
### Что сделано
1. В модуле terraform добавлена логическая переменная и с её помощью отключён провижининг в Terraform.
2. Проверена работа плейбука с одним и с несколькими сценариями, запуск хэндлеров.
3. В плейбук добавлен сценарий для деплоя приложения.
4. Основной плейбук разбит на 3 части: app.yml, db.yml, deploy.yml.
5. Проверена работа такого плейбука со скриптом dyninventory.py, разработанным в ДЗ #8. При пересоздании окружения требуется вручную вносить изменения в сценарии app.yml и db.yml.
6. Доработан скрипт dyninventory.py и сценарии app.yml и db.yml для исключения ручного редактирования при изменении окружения. При этом потеряна возможность параллельного запуска двух окружений.
7. Провижининг с помощью shell-скриптов в Packer заменен на использование Ansible. 
8. Пересозданы образы Packer, по очереди запущены оба окружения и проверена работа нового плейбука и доработанного скрипта dyninventory.py в каждом из них.
9. В модули terraform добавлены теги с названиями окружений, доработан скрипт dyninventory.py  для извлечения этих тегов и плейбук для их использования. В результате восстановлена возможность параллельного запуска двух окружений.

### Как запустить проект
- Клонировать репозиторий
- В директории packer скопировать файл variables.json.example в variables.json и заменить в нем project_id на реальный ID вашего проекта
- Построить образы ВМ, запустив из корневой папки репозитория команды
```sh
 $ packer build --var-file packer/variables.json packer/app.json
 $ packer build --var-file packer/variables.json packer/db.json
```
- Создать бакет в Google Cloud Storage и запустить параллельно окружения stage и prod, как описано в домашнем задании  #7
- Перейти в каталог ansible и выполнить команду

```sh
$ ansible-playbook site.yml

```

Вывод команды будет выглядеть так

```
arh@zalman:/home/my/projects/otus/aarkhang_infra/ansible$ ansible-playbook site.yml

PLAY [Configure MongoDB] ***********************************************************************************************************

TASK [Change mongo config file] ****************************************************************************************************
changed: [reddit-db-s]
changed: [reddit-db]

RUNNING HANDLER [restart mongod] ***************************************************************************************************
changed: [reddit-db-s]
changed: [reddit-db]

PLAY [Configure application] *******************************************************************************************************

TASK [Add unit file for Puma] ******************************************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

TASK [Add config file for DB connection] *******************************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

TASK [enable Puma] *****************************************************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

RUNNING HANDLER [reload puma] ******************************************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

PLAY [Deploy application] **********************************************************************************************************

TASK [Fetch the latest version of application code] ********************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

TASK [Bundle install] **************************************************************************************************************
changed: [reddit-app]
changed: [reddit-app-s]

RUNNING HANDLER [restart puma] *****************************************************************************************************
changed: [reddit-app-s]
changed: [reddit-app]

PLAY RECAP *************************************************************************************************************************
reddit-app                 : ok=7    changed=7    unreachable=0    failed=0   
reddit-app-s               : ok=7    changed=7    unreachable=0    failed=0   
reddit-db                  : ok=2    changed=2    unreachable=0    failed=0   
reddit-db-s                : ok=2    changed=2    unreachable=0    failed=0   

```
Мохно также выполнять плейбук только на одном из запущенных окружений:
```sh
$ ansible-playbook site.yml --limit stage

```
### Как проверить работоспособность приложения
Определить внешние адреса запущенных инстансов, например выпонив команду: 
```
arh@zalman:/home/my/projects/otus/aarkhang_infra/ansible$ gcloud compute instances list
NAME          ZONE             MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
reddit-app-s  europe-north1-b  f1-micro                   10.166.0.3   35.228.9.114   RUNNING
reddit-db-s   europe-north1-b  f1-micro                   10.166.0.2   35.228.241.58  RUNNING
reddit-app    europe-west4-a   f1-micro                   10.164.0.3   35.204.35.210  RUNNING
reddit-db     europe-west4-a   f1-micro                   10.164.0.2   35.204.30.1    RUNNING
```
Перейти по ссылкам http://<reddit-app-external_ip>:9292 и http://<reddit-app-s-external_ip>:9292


Домашнее задание #8    Ansible-1
----------------------------------
### Что сделано
1. Установлена Ansible.
2. Созданы конфигурационный и inventory-файл для инфраструктуры из окружений stage и prod
3. Проверена работа базовых модулей ping, command, shell, service с отдельными хостами и группами хостов
4. Создан inventory-файл в формате YAML
5. Проверена процедура клонирования репозитория с помощью модуля git
6. Создан плейбук, выполняющий клонирование репозитория
7. Проверено восстановление репозитория с помощью плейбука после его удаления
8. Проверено использовние скрипта [ansible-inventory](https://docs.ansible.com/ansible/latest/cli/ansible-inventory.html#ansible-inventory) для преобразования формата inventory-файла из ini в YAML и JSON
9. Создан скрипт dyninventory.py, использующий вызов *gcloud compute instances list* и реализущий динамическое инвентори для инфраструктуры из окружений stage и prod 

### Как запустить проект
- Клонировать репозиторий
- Поднять параллельно инфраструктуры stage и prod, как описано в домашней работе #7

### Как проверить работоспособность
- Перейти в каталог ansible и выполнить команду
```sh
$ ansible -i dyninventory.py all -m ping
```
Вывод команды должен выглядеть так
```
reddit-app | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-db | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-app-stage | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-db-stage | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```
### Примечание
В предыдущих домашних работах я ради эксперимента собрал образы ВМ на основе Ubuntu 18.04. 
При тестировании приложения возникла ошибка  **NameError at / **, поэтому образ reddit-app-base был пересобран 
на основе Ubuntu 16.04. Ошибка исчезла и образ reddit-db-base я пересобирать не стал. Теперь при работе с
Ansible у меня возникла следующая ошибка:
```
arh@zalman:/home/my/aarkhang_infra/ansible$ ansible -i inventory all -m ping
reddit-app | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-app-stage | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-db | FAILED! => {
    "changed": false, 
    "module_stderr": "Shared connection to 35.228.241.58 closed.\r\n", 
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n", 
    "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", 
    "rc": 127
}
reddit-db-stage | FAILED! => {
    "changed": false, 
    "module_stderr": "Shared connection to 35.195.151.178 closed.\r\n", 
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n", 
    "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", 
    "rc": 127
}
```
Оказывается, в Ubuntu 18.04 python 2.7 по-умолчанию не установлен, но есть python3
```
appuser@instance-2:~$ python --version

Command 'python' not found, but can be installed with:

apt install python3       
apt install python        
apt install python-minimal

Ask your administrator to install one of them.

You also have python3 installed, you can run 'python3' instead.

appuser@instance-2:~$ python3 --version
Python 3.6.6
```
Чтобы не пересобирать образ я добавил в inventory-файл (и код скрипта) указание использовать python3 для образов reddit-db 
```
[db:vars]
ansible_python_interpreter=/usr/bin/python3
```

Домашнее задание #7    Terraform-2
----------------------------------
1. В конфигурации Terraform cоздано правило файрвола для SSH. 
2. Добавлен ресурс статического внешнего IP-адреса для приложения 
3. Подготовлены два образа ВМ в GCE с предустановленными Ruby и MongoDB. 
   - Созданы Packer-шаблоны app.json и db.json на основе ubuntu16.json
   - Доработан скрипт install_mongodb.sh для замены bindIP в конфигурационном файле mongod.conf на "0.0.0.0"
   - Построены образы reddit-app-base-1540806487 и reddit-db-base-1540892043
4. Создана конфигурация Terraform для запуска приложения reddit и сервера БД в отдельных экземплярах ВМ
   - Основной конфигурационный файл Terraform разделён на 4 части: app.tf, db.tf, vpc.tf и main.tf
   - Добавлен ресурс статического внутреннего IP-адреса в db.tf
   - Изменен файл app.json для корректной работы провижинера
	    * добавлена input-переменная db_address для получения IP-адреса сервера БД 
	    * добавлен [источник данных](https://www.terraform.io/docs/configuration/data-sources.html) [*template_file*](https://www.terraform.io/docs/providers/template/d/file.html) для формирования systemd-юнита puma.service со строкой, передающей IP-адрес БД в переменную окружения DATABASE_URL
  	  * скорректирован провижинер для записи файла puma.service на сервер
   - Проверен запуск этих ВМ и корректная работа приложения
5. Конфигурации Terraform для ВМ и настройки сети перемещены в модули
6. Создана инфраструктура для двух окружений stage и prod с использоанием модулей
7. С помощью параметризации модулей инфраструктуры окружений сделаны независимыми друг от друга (возможен параллельный запуск двух окружений)
8. Создан бакет для хранения состояния инфраструктуры в сервисе GCS
9. Настроено хранение состояния инфраструктуры в удалённом бекенде
10. Проверено создание блокировок при одновременном применении конфигурации

### Как запустить проект
- Клонировать репозиторий
- В директории packer скопировать файл variables.json.example в variables.json и заменить в нем project_id на реальный ID вашего проекта 
- Построить образы ВМ из шаблонов
```sh
 packer build --var-file variables.json app.json
 packer build --var-file variables.json db.json
```
- В директории terraform скопировать файл terraform.tfvars.example в terraform.tfvars и вписать в него реальный ID вашего проекта 
- Создать бакет в Google Cloud Storage
```sh
 terraform init
 terraform apply
```
- В директории terraform/stage скопировать файл terraform.tfvars.example в terraform.tfvars и вписать в него реальный ID вашего проекта 
- Запустить инстансы в Google Cloud Engine
```sh
 terraform init
 terraform apply
```
- То же самое проделать в директории terraform/prod (можно не ждать окончания процесса в stage)
В файлах terraform.tfvars.example для stage и prod указаны разные region и zone, если их установить одинаковыми в terraform.tfvars, то второй процесс развёртывания завершится с ошибкой:
```
* module.app.google_compute_address.app_ip: 1 error(s) occurred:
* google_compute_address.app_ip: Error creating address: googleapi: Error 403: Quota 'STATIC_ADDRESSES' exceeded. Limit: 1.0 in region europe-west1., quotaExceeded
```
В разных регионах удаётся развернуть параллельно оба окружения

### Как проверить работу приложения
По завешении процесса развёртывания на экран будет выведено сообщение вида
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

app_external_ip = 35.228.177.152
db_internal_ip = 10.166.0.2
```
Перейти по ссылке http://<app_external_ip>:9292

### Как проверить работу блокировок
Запустить 2 процесса  *terraform apply* в одном и том же окружении параллельно. Один из процессов должен завершиться с ошибкой
```
Acquiring state lock. This may take a few moments...

Error: Error locking state: Error acquiring the state lock: writing "gs://infra-219311-tfstate/stage/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        1541082383241326
  Path:      gs://infra-219311-tfstate/stage/default.tflock
  Operation: OperationTypeApply
  Who:       Arhcomp\arh@Arhcomp
  Version:   0.11.10
  Created:   2018-11-01 14:24:02.0452 +0000 UTC
  Info:      


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

Домашнее задание #6    Terraform-1
----------------------------------

### Основное ДЗ
1. Удалены ключи пользователя appuser из метаданных прокта
2. Установлена Terraform
3. Создана конфигурация Terraform для запуска 1 экземпляра ВМ из образа reddit-base в GCP
   - Публичный ключ пользователя appuser добавлен к метаданным экземпляра
   - Добавлено правило файрволла и тег для него
   - Добавлены провижинеры для развёртывания и запуска тестового приложения
   - Добавлен приватный ключ для подключения провижинера по SSH
4. Конфигурационный файл параметризован с помощью входных переменных
5. Отформатированы конфигурационные файлы
6. Проверена работа приложения


### Задание со *
Добавить ssh-ключи к метаданным проекта можно 2 способами:
   - С помощью ресурса [google_compute_project_metadata](https://www.terraform.io/docs/providers/google/r/compute_project_metadata.html)
```
resource "google_compute_project_metadata" "ssh_keys" {
  metadata {
    ssh-keys = "appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key2_path)}"
  }
}
```
   - С помощью ресурса [google_compute_project_metadata_item](https://www.terraform.io/docs/providers/google/r/compute_project_metadata_item.html)
```
resource "google_compute_project_metadata_item" "ssh_keys" {
  key   = "ssh-keys"
  value = "appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key2_path)}"
}
```
С помощью **одного** ресурса можно добавить несколько ключей, разделяя их символом "\n", а при использовании синтаксиса ${file(var.public_key_path)} разделитель можно опустить, т.к. он имеется внутри файла с публичным ключом.

Ключи, указанные в конфигурации terraform, перезапишут любые другие ssh-ключи, утановленные вручную и удалят все ключи, не указанные в конфигурации.


Домашнее задание #5    Packer base
----------------------

### Шаблоны

Созданы и параметризованы шаблоны для сборки **Packer**-ом образов ВМ

* ubuntu16.json: cемейство reddit-base (базовая установка Ruby и МоngoDB) 

* immutable.json: cемейство reddit-full (строится на основе базового) 


### Сборка


Для сборки base-образа применяется команда
```sh
$ packer build -var-file=variables.json  ubuntu16.json
```

Для автоматизации сборки full-образа создан скрипт build-reddit-full.sh
```sh
#!/bin/sh
set -e

IMAGE=`gcloud compute images list --format="value(name)"  --filter="name:reddit-base"  --sort-by="~name" --limit=1`

echo Using last base image: $IMAGE

packer validate -var-file=variables-immutable.json -var "source_image=$IMAGE" immutable.json
packer build -var-file=variables-immutable.json -var "source_image=$IMAGE" immutable.json
```

### Запуск


Для автоматизации запуска образа ВМ создан скрипт create-reddit-vm.sh
```sh
#!/bin/sh

IMAGE=`gcloud compute images list --format="value(name)"  --filter="name:reddit-full"  --sort-by="~name" --limit=1`

echo Using last image: $IMAGE

gcloud compute instances create reddit-app \
  --image $IMAGE \
  --machine-type=g1-small \
  --tags "puma-server" \
  --zone "europe-west1-b"
```


Домашнее задание #4
----------------------

### Данные для подключения
```
testapp_IP = 35.228.70.71
testapp_port = 9292
```

#### Команда создания инстанса
```sh
$ gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=install_reddit.sh
```

#### Команда создания правила брандмауэра
```sh
$ gcloud compute --project=infra-219311 firewall-rules \
     create  default-puma-server \
   --direction=INGRESS --priority=1000 --network=default \
   --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 \
   --target-tags=puma-server
```


Домашнее задание #3
----------------------

### Адреса ВМ в GCP
```
bastion_IP = 35.228.177.152
someinternalhost_IP = 10.166.0.3
```

#### Подключение к *someinternalhost* одной командой
```sh
$ ssh -i ~/.ssh/appuser -tA appuser@35.228.177.152 ssh 10.166.0.3
```

#### Подключение к *someinternalhost* по алиасу
Добавляем в файл ~/.ssh/config следующие строчки
```
Host someinternalhost
 HostName 10.166.0.3
 IdentityFile= ~/.ssh/appuser
 User appuser
 ProxyCommand ssh appuser@35.228.177.152 -W %h:%p
```
Если версия клиента OpenSSH >= 7.3 вместо **ProxyCommand** можно использовать

```
ProxyJump appuser@35.228.177.152
```
Теперь можно подключиться командой
```sh
$ ssh someinternalhost
```

#### Подключение к *someinternalhost* через *OpenVPN*
```sh
$ sudo openvpn cloud-bastion.ovpn 
```
Вводим имя пользователя и пароль, установленный при настройке Pritunl. Подключаемся в другом окне терминала: 

```sh
$ ssh -i ~/.ssh/appuser appuser@10.166.0.3

```
