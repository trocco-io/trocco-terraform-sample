terraform {
  required_providers {
    trocco = {
      source  = "registry.terraform.io/trocco-io/trocco"
      version = ">= 0.13.0"
    }
  }
}

variable "trocco_api_key" {
  type      = string
  sensitive = true
}

provider "trocco" {
  api_key = var.trocco_api_key # コピー元アカウントのTROCCO APIキー
  region  = "japan"
}
