@description('Location for the load balancer')
param location string

@description('Name for the public IP')
param publicIpName string

@description('ID for the subnet')
param subnetId string

@description('Name for the backend pool')
param backendPoolName string

@description('Name for the health probe')
param healthProbeName string

@description('Name for the load balancer')
param loadBalancerName string

@description('Array of Network Interface IDs')
param networkInterfaceIds array

// Public IP Address resource
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Load Balancer resource
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard' // Ensure consistency with Public IP SKU
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'FrontendConfiguration'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIpName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendIPConfigurations: [
            for nicId in networkInterfaceIds: {
              id: '${nicId}/ipConfigurations/ipconfig1' // Replace "ipconfig1" with your IP configuration name
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: healthProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}


// Output frontend IP configuration, backend pool, and health probe IDs
output frontendIpId string = loadBalancer.properties.frontendIPConfigurations[0].id
output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
output healthProbeId string = loadBalancer.properties.probes[0].id
