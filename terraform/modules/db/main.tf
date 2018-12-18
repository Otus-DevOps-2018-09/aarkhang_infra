resource "google_compute_instance" "db" {
  name         = "reddit-db${var.name_suffix}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  labels = {
    environment = "${var.env_name}"
    inventory_group  = "db"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  tags = ["tag-db${var.name_suffix}", "${var.env_name}"]

  # определение сетевого интерфейса
  network_interface {
    network = "default"
    address = "${google_compute_address.db_ip.address}"

    access_config = {}
  }
}

resource "google_compute_firewall" "firewall_mongo" {
  name        = "allow-mongo${var.name_suffix}"
  description = "Allow MongoDB access from instances with given tag"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  # правило применимо к инстансам с тегом ...
  target_tags = ["tag-db${var.name_suffix}"]

  # порт будет доступен только для инстансов с тегом ...
  source_tags = ["tag-app${var.name_suffix}"]
}

resource "google_compute_address" "db_ip" {
  name         = "db-ip${var.name_suffix}"
  address_type = "INTERNAL"
}
