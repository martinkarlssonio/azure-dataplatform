output "raw_ctgrp_name" {
  value = azurerm_container_group.raw.name
}

output "enriched_ctgrp_name" {
  value = azurerm_container_group.enriched.name
}

output "curated_ctgrp_name" {
  value = azurerm_container_group.curated.name
}