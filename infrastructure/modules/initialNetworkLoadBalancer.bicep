@description('Location for the load balancer')
param location string

@description('Name for the public IP')
param publicIpName string

@description('ID for the subnet')
param subnetId string

@description('Name for the health probe')
param healthProbeName string

@description('Name for the load balancer')
param loadBalancerName string

// Load Balancer resource
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
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
    probes: [
      {
        name: healthProbeName
        properties: {
          protocol: 'Tcp'
          port: 5432
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

// Output the backend pool ID for use in VM configuration
output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
