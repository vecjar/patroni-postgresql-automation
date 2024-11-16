# Bicep Deployment
az group create --name azure-patroni-integration-rg --location australiaeast
az deployment group create --resource-group azure-patroni-integration-rg --template-file main.bicep --parameters parameters.json --mode Complete