@description('Specifies the location for resources.')
param location string = 'eastus'

@description('The name of the OpenAI backend pool')
param openAIBackendPoolName string = 'openai-backend-pool'

@description('The description of the OpenAI backend pool')
param openAIBackendPoolDescription string = 'Load balancer for multiple OpenAI endpoints'

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-js-genai-gateway-demo'
  location: location
  sku: {
    name: 'BasicV2'
    capacity: 1
  }
  properties: {
    publisherEmail: 'jimmyshah@microsoft.com'
    publisherName: 'Jimmy Shah'
  }
  identity: {
    type: 'SystemAssigned'
  } 
}

resource eusBackendOpenAI 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'eus-genai-openai-endpoint'
  parent: apimService
  properties: {
    description: 'Backend for OpenAI endpoint in East US'
    url: 'https://js-eus-openai-genai-demo.openai.azure.com/openai'
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 3
            errorReasons: [
              'Server errors'
            ]
            interval: 'PT5M'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
            ]
          }
          name: 'openAIBreakerRule'
          tripDuration: 'PT1M'
          acceptRetryAfter: true
        }
      ]
    }    
  }
}

resource wusBackendOpenAI 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'wus-genai-openai-endpoint'
  parent: apimService
  properties: {
    description: 'Backend for OpenAI endpoint in East US'
    url: 'https://js-wus-openai-genai-demo.openai.azure.com/openai'
    protocol: 'http'
  }
}

resource backendPoolOpenAI 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: openAIBackendPoolName
  parent: apimService
  properties: {
    description: openAIBackendPoolDescription
    type: 'Pool'
    pool: {
      services: [
        {
          id: eusBackendOpenAI.id
          priority: 1
          weight: 3
        }
        {
          id: wusBackendOpenAI.id
          priority: 1
          weight: 1
        }
      ]
    }
  }
}
