@description('Get the resource group location and tenant id')
param location string = resourceGroup().location

// a 4 character suffix to add to the various names of Azure resources to help them be unique
var appSuffix = substring(uniqueString(resourceGroup().id),0,4)

@description('Administrator username for the VM')
param adminUsername string

@description('Administrator password for the VM')
@secure()
param adminPassword string

@description('Name of the Virtual Network')
param vnetName string

@description('Subnet name within the Virtual Network')
param subnetName string

@description('Virtual Machine name')
param vmName string

// Module for creating a Linux VM
module linuxVM './modules/linuxVM.bicep' = {
  name: 'linuxVMDeployment'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetName: vnetName
    subnetName: subnetName
  }
}


