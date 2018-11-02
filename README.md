aarkhang_infra
==============
[![Build Status](https://travis-ci.com/Otus-DevOps-2018-09/aarkhang_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-09/aarkhang_infra)

Otus DevOps 2018-09 Infrastructure repository.

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
