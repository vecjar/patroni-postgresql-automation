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
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendIPConfigurations: [
            {
              id: '${networkInterfaceIds[0]}/ipConfigurations/ipconfig1'
            }
            {
              id: '${networkInterfaceIds[1]}/ipConfigurations/ipconfig1'
            }
            {
              id: '${networkInterfaceIds[2]}/ipConfigurations/ipconfig1'
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
          port: 5432
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'Postgres'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'FrontendConfiguration')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, healthProbeName)
          }
          protocol: 'Tcp'
          frontendPort: 5432
          backendPort: 5432
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
        }
      }
    ]
  }
}

// Output frontend IP configuration, backend pool, and health probe IDs
output frontendIpId string = loadBalancer.properties.frontendIPConfigurations[0].id
output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
output healthProbeId string = loadBalancer.properties.probes[0].id
