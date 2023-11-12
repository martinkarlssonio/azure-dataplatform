# output "container_ipv4_address" {
#   value = azurerm_container_group.container.ip_address
# }
output "rg_name" {
  value = azurerm_resource_group.rg.name
}
output "rg_location" {
  value = azurerm_resource_group.rg.location
}
output "stacc_name" {
  value = azurerm_storage_account.stacc.name
}
output "acr_name" {
  value = azurerm_container_registry.acr.name
}
