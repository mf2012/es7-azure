### TODO:
# * render config file for elasticsearch & logstash on vm1
#   with private IPs and blob endpoint



data "template_file" "elastic_cfg" {
  count    = "${var.node_count}"
  template = "${file("${path.module}/../templates/elasticsearch.yml")}"

  vars = {
    es_cluster    = "${var.es_cluster}"
    es_node_name  = "es-${var.es_cluster}-vm${count.index + 1}"
    host_priv_ip  = "${element(azurerm_network_interface.elasticsearch_nic.*.private_ip_address, count.index)}"
    priv_node_ips = "[\"${join("\", \"", azurerm_network_interface.elasticsearch_nic.*.private_ip_address)}\" ]"
    es_masters    = "[\"${join("\", \"", azurerm_virtual_machine.elasticsearch_vms.*.name)}\" ]"
  }
}

data "template_file" "logstash_cfg" {
  count    = "${var.node_count}"
  template = "${file("${path.module}/../templates/logstash-eventhub.conf")}"

  vars = {
    eventhub_conn        = "${azurerm_eventhub_authorization_rule.eventrw.primary_connection_string}"
    eventdump_conn       = "${azurerm_storage_account.eventdump.primary_connection_string}"
    event_consumer_group = "${azurerm_eventhub_consumer_group.eventconsumer.name}"
    host_priv_ip         = "${element(azurerm_network_interface.elasticsearch_nic.*.private_ip_address, count.index)}"
  }
}

# create virtual machine
resource "azurerm_virtual_machine" "elasticsearch_vms" {
  count               = "${var.node_count}"
  name                = "es-${var.es_cluster}-vm${count.index + 1}"
  location            = var.azure_location
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  network_interface_ids = ["${element(azurerm_network_interface.elasticsearch_nic.*.id, count.index)}"]
  vm_size               = "Standard_D1"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "elasticsearch_osdisk"
    vhd_uri       = "${azurerm_storage_account.elasticsearch_storage.primary_blob_endpoint}${element(azurerm_storage_container.elasticsearch_storage_container.*.name, count.index)}/elasticsearch${count.index + 1}.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "es-${var.es_cluster}-vm${count.index + 1}"
    admin_username = "ubuntu"
    #custom_data    = "${data.template_file.userdata_script.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${file(var.key_path)}"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.elasticsearch_storage.primary_blob_endpoint
  }

  tags = var.tags
}

resource "null_resource" "elasticsearch" {
  count = "${var.node_count}"
  connection {
    user        = "ubuntu"
    host        = "${element(azurerm_public_ip.elasticsearch_ips.*.ip_address, count.index)}"
    private_key = "${file(var.priv_key_path)}"
    timeout     = 30
  }

  provisioner "file" {
    source      = "../templates"
    destination = "templates"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash templates/bootstrap.sh"]
  }

  # provisioner "local-exec" {
  #   command = "cat > ../secrets/elaticsearch${count.index}.yml <<EOL\n${element(data.template_file.elastic_cfg.*.rendered, count.index)}\nEOL"
  # }
}

resource "null_resource" "configs_elk" {
  count = "${var.node_count}"
  connection {
    user        = "ubuntu"
    host        = "${element(azurerm_public_ip.elasticsearch_ips.*.ip_address, count.index)}"
    private_key = "${file(var.priv_key_path)}"
    timeout     = 30
  }
  depends_on = [
    # The IP address in Dynamic allocation scheme is only available after VM is created
    azurerm_virtual_machine.elasticsearch_vms,
    azurerm_eventhub_authorization_rule.eventrw,
    azurerm_storage_account.eventdump,
  ]

  provisioner "remote-exec" {
    inline = [
      "sudo tee /etc/elasticsearch/elasticsearch.yml <<EOF",
      "${element(data.template_file.elastic_cfg.*.rendered, count.index)}",
      "EOF",
      "sudo systemctl restart elasticsearch",
    ]
    # If cluster does not form correctly check all below
    ## ES cluster bootstrap (NOTE: node_names must be equal to dns names)
    # 1. stop
    # 2. remove data from data.path
    # 3. cluster start on all nodes
  }

  provisioner "remote-exec" {
    inline = [
      "sudo tee /etc/logstash/conf.d/eventhub.conf <<EOF",
      "${element(data.template_file.logstash_cfg.*.rendered, count.index)}",
      "EOF",
      "sudo systemctl restart kibana",
    ]
  }
}
