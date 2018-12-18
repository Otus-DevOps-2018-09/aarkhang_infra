resource "google_compute_instance" "app" {
  name         = "reddit-app${var.name_suffix}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  labels = {
    environment = "${var.env_name}"
    inventory_group  = "app"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  tags = ["tag-app${var.name_suffix}", "${var.env_name}"]

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать static IP для доступа из Интернет
    access_config = {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }
}

resource "null_resource" "app_deploy" {
  count = "${var.enable_deploy ? 1 : 0}"

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
    host        = "${google_compute_instance.app.network_interface.0.access_config.0.assigned_nat_ip}"
  }

  provisioner "file" {
    content     = "${data.template_file.puma_service.rendered}"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma${var.name_suffix}"

  # Название сети , в которой действует правило
  network = "default"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["tag-app${var.name_suffix}"]
}

resource "google_compute_address" "app_ip" {
  name = "reddit-ip${var.name_suffix}"
}

data "template_file" "puma_service" {
  template = "${file("${path.module}/files/puma.service")}"

  vars {
    db_address = "${var.db_address}"
  }
}
