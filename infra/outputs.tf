# outputs.tf - values printed after `terraform apply`, and readable later with
# `terraform output`. Handy for the IPs you SSH/RDP to.

output "win_srv_public_ip" {
  description = "The public IP you RDP to (reachable only from your home IP)."
  value       = azurerm_public_ip.win_srv.ip_address
}

output "win_srv_admin_password" {
  description = "win-srv local admin password. Read with: terraform output -raw win_srv_admin_password"
  value       = random_password.win_srv.result
  sensitive   = true
}

output "private_ips" {
  description = "Private IPs of the core VMs (reach them by hopping through win-srv)."
  value = {
    wazuh     = azurerm_linux_virtual_machine.wazuh.private_ip_address
    win_srv   = azurerm_windows_virtual_machine.win_srv.private_ip_address
    linux_srv = azurerm_linux_virtual_machine.linux_srv.private_ip_address
  }
}

output "web_srv_private_ip" {
  description = "web-srv's IP when the stage is enabled."
  value       = var.enable_web_srv ? azurerm_linux_virtual_machine.web_srv[0].private_ip_address : "web-srv disabled (set enable_web_srv = true)"
}
