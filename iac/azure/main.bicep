// GitHub Actions ワークショップ デモ用の最小構成
//
// つくるもの:
//   - Linux App Service プラン（F1 = 無料枠）
//   - Node.js 20 の Web App
//
// 依存パッケージゼロのアプリを `npm start` で動かすだけなので、
// ビルド処理（Oryx）は無効にしています。
//
// デプロイ:
//   az group create -n rg-gha-demo -l japaneast
//   az deployment group create -g rg-gha-demo -f main.bicep -p appName=gha-demo-<自分の識別子>

targetScope = 'resourceGroup'

@description('Web App の名前。世界で一意である必要があります（例: gha-demo-chiba-0902）')
@minLength(3)
@maxLength(40)
param appName string

@description('リソースを作るリージョン')
param location string = resourceGroup().location

@description('App Service プランの SKU。F1 は無料枠です')
@allowed([
  'F1'
  'B1'
])
param sku string = 'F1'

@description('リソースに付けるタグ')
param tags object = {
  purpose: 'github-actions-workshop'
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appName}-plan'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: sku
  }
  properties: {
    // Linux プランでは reserved: true が必須
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: tags
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appCommandLine: 'npm start'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      // F1（無料枠）では alwaysOn は使えません
      alwaysOn: false
      appSettings: [
        {
          // 依存パッケージが無いので、デプロイ時のビルドは不要
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
      ]
    }
  }
}

@description('公開 URL。デプロイ後にここを開いて確認します')
output siteUrl string = 'https://${site.properties.defaultHostName}'

@description('RBAC を割り当てる対象のリソース ID')
output siteResourceId string = site.id

@description('Web App 名。ワークフローの app-name に指定します')
output webAppName string = site.name
