provider "aws" {
    region = "us-east-1"
}

provider "azurerm" {
    subscription_id = "azure-subscription-id"
    client_id = "azure-client-id"
    client_secret = "azure-client-secret"
    tenant_id = "azure-tenant-id"
}

/*
terraform {
    required_providers {         // Required providers block
        aws = {
            source = "hashicorp/aws"
            version = "~>3.0.0"
        }
        azure = {
            source = "hashicorp/azurerm"
            version = ">=2.0, <3.0"
        }
    }
}
