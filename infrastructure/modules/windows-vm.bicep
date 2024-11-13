param location string = resourceGroup().location
param adminUsername string
param adminPassword string
param vmName string
param vnetName string
param subnetName string
param publicIp bool = false  // Option to create public IP or not

resource windowsVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ms'  // Adjust to your desired VM size
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: virtualNetworkInterface.id
        }
      ]
    }
  }
}

resource virtualNetworkInterface 'Microsoft.Network/networkInterfaces@2023-03-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-03-01' existing = {
  name: subnetName
  parent: vnet
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-03-01' existing = {
  name: vnetName
}

output vmPrivateIP string = windowsVM.properties.networkProfile.networkInterfaces[0].properties.ipConfigurations[0].properties.privateIPAddress
