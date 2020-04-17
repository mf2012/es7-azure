### TODO:
# * render config file for elasticsearch & logstash on vm1
#   with private IPs and blob endpoint



# data "ptivate_ips" {
#   value = "${azurerm_network_interface.elasticsearch_nic.*.private_ip_address}"
# }
#
# data "template_file" "userdata_script" {
#   template = "${file("${path.module}/../templates/elasticsearch.yml")}"
#
#   vars = {
#     es_cluster     = "${var.es_cluster}"
#     es_environment = "${var.environment}-${var.es_cluster}"
#     node_count     = "${var.node_count}"
#     node_ips       = "${var.private_ips}"
#   }
# }


### TODO:
# * For VM add depends on nics so the private IPs are available for rendering script above
# create virtual machine
resource "azurerm_virtual_machine" "elasticsearch_vm" {
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
}
