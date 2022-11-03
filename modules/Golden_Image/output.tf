output "Manifest" {
    value = jsondecode(data.local_file.manifest.content)
}