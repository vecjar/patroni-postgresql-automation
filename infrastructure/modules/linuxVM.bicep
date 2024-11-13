param location string
param vmName string
param adminUsername string
@secure()
param adminPassword string

@description('Address space for the VNet')
param addressSpace string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetPrefix string = '10.0.1.0/24'

@description('Provide the name of the Virtual Network (VNet)')
param vnetName string = '${vmName}-vnet'

@description('Provide the name of the Subnet within the VNet')
param subnetName string = '${vmName}-subnet'

// Provision the Virtual Network (VNet)
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

// Reference the subnet within the newly created VNet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

// Network Interface for the VM
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v3'  // 4 vCPUs, 8 GB memory
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30  // 30 GB OS disk size
      }
      imageReference: {
        publisher: 'Canonical' // Replace this to provision Oracle Linux, CentOS, or any other
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
