resource "null_resource" "run_packer" {
    provisioner "local-exec" {
        command = <<-EOT
            cd ${path.module}/packer
            packer init .
            packer validate .
            packer build  -var "manifest_path=${var.Manifest_path}" -var "name=${var.Name}" .
        EOT
    }
}

data "local_file" "manifest" {
  filename = "${var.Manifest_path}/manifest_golden_image.json"
  depends_on = [
    null_resource.run_packer
  ]
}