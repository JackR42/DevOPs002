## code/AZ-GH-TF-Pre-Reqs.ps1
<#
https://4bes.nl/2019/07/11/step-by-step-manually-create-an-azure-devops-service-connection-to-azure/

$xSPName = "SPN-project01-927432"
$xAzSubscriptionName = "S2-Visual Studio Ultimate with MSDN"
$xSubscription = (Get-AzSubscription -SubscriptionName $xAzSubscriptionName)
$xSubscriptionID = $xSubscription.Id

$xspId = (Get-AzADServicePrincipal -DisplayName $xSPName).Id
$xspAppId = (Get-AzADServicePrincipal -DisplayName $xSPName).AppId
$xTenantId = $xSubscription.TenantId

Write-Output "SubscriptionID: $xSubscriptionID 
Subscription Name: $xAzSubscriptionName
Service Principal ID: $xspId
Service Principal CLient ID (AppId): $xspAppId
Tenant ID: $xTenantId "
#>

#Log into Azure
#az login

# Setup Variables
$randomInt = Get-Random -Maximum 999999
$subscriptionId=$(az account show --query id -o tsv)
$subscriptionName = "S2-Visual Studio Ultimate with MSDN"
$ProjectName = "project01"
$resourceGroupName = "S2-RG-CORE-$ProjectName"
$storageName = "core$ProjectName$randomInt"
$kvName = "core-$ProjectName-kv$randomInt"
$appName="SPN-$ProjectName-$randomInt" #AppName=SpnName
$region = "westeurope"

# Create a resource resourceGroupName
az group create --name "$resourceGroupName" --location "$region"
#az group delete --name  "$resourceGroupName" --no-wait --yes

# Create a Key Vault
az keyvault create `
    --name "$kvName" `
    --resource-group "$resourceGroupName" `
    --location "$region" `
    --enable-rbac-authorization

# Authorize the operation to create a few secrets - Signed in User (Key Vault Secrets Officer)
az ad signed-in-user show --query id -o tsv | foreach-object {
    az role assignment create `
        --role "Key Vault Secrets Officer" `
        --assignee "$_" `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$kvName"
    }

# Create an azure storage account - Terraform Backend Storage Account
az storage account create `
    --name "$storageName" `
    --location "$region" `
    --resource-group "$resourceGroupName" `
    --sku "Standard_LRS" `
    --kind "StorageV2" `
    --https-only true `
    --min-tls-version "TLS1_2"

#az storage account list
#permissions StorageAccount???

# Authorize the operation to create the container - Signed in User (Storage Blob Data Contributor Role)
az ad signed-in-user show --query id -o tsv | foreach-object {
    az role assignment create `
        --role "Storage Blob Data Contributor" `
        --assignee "$_" `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageName"
    }

#Create Upload container in storage account to store terraform state files
Start-Sleep -s 60
az storage container create `
    --account-name "$storageName" `
    --name "tfstate" `
    --auth-mode login

# Create Terraform Service Principal and assign RBAC Role on Key Vault
$spnJSON = az ad sp create-for-rbac --name $appName `
    --role "Key Vault Secrets Officer" `
    --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$kvName

# Save new Terraform Service Principal details to key vault
$spnObj = $spnJSON | ConvertFrom-Json
foreach($object_properties in $spnObj.psobject.properties) {
    If ($object_properties.Name -eq "appId") {
        $null = az keyvault secret set --vault-name $kvName --name "ARM-CLIENT-ID" --value $object_properties.Value
    }
    If ($object_properties.Name -eq "password") {
        $null = az keyvault secret set --vault-name $kvName --name "ARM-CLIENT-SECRET" --value $object_properties.Value
    }
    If ($object_properties.Name -eq "tenant") {
        $null = az keyvault secret set --vault-name $kvName --name "ARM-TENANT-ID" --value $object_properties.Value
    }
}
$null = az keyvault secret set --vault-name $kvName --name "ARM-SUBSCRIPTION-ID" --value $subscriptionId
$null = az keyvault secret set --vault-name $kvName --name "ARM-SPN" --value $spnObj.displayName
$null = az keyvault secret set --vault-name $kvName --name "SQLServer-InstanceName" --value "sqlserver$randomInt"
$null = az keyvault secret set --vault-name $kvName --name "SQLServer-InstanceNameFqdn" --value "sqlserver$randomInt.database.windows.net"
$null = az keyvault secret set --vault-name $kvName --name "SQLServer-InstanceAdminUserName" --value 'admindba'
$null = az keyvault secret set --vault-name $kvName --name "SQLServer-InstanceAdminPassword" --value 'ABCabc123.42'
$null = az keyvault secret set --vault-name $kvName --name "SQLServer-Database1Name" --value 'dba$randomInt'


# Assign additional RBAC role to Terraform Service Principal Subscription as Contributor and access to backend storage
az ad sp list --display-name $appName --query [].appId -o tsv | ForEach-Object {
    az role assignment create --assignee "$_" `
        --role "Contributor" `
        --subscription $subscriptionId

    az role assignment create --assignee "$_" `
        --role "Storage Blob Data Contributor" `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageName" `
    }

write-Output "SPN properties from Azure to Create Service Connection in Azure DevOps AzDO"
Write-Output "Subscription Name: $subscriptionName"
Write-Output "Subscription ID: $subscriptionId"
Write-Output "Service Principal Name: $AppName "
foreach($object_properties in $spnObj.psobject.properties) {
    If ($object_properties.Name -eq "appId") {
        Write-Output "Service Principal ID (AppId): $object_properties"
    }
    If ($object_properties.Name -eq "password") {
        Write-Output "Service Principal Key (Password): $object_properties"
    }
    If ($object_properties.Name -eq "tenant") {
        Write-Output "Tenant: $object_properties"
    }
}

## https://dev.to/pwd9000/multi-environment-azure-deployments-with-terraform-and-github-2450
## https://subhankarsarkar.com/simple-way-to-create-spn-and-service-connection-for-azure-devops-pipelines/
## https://github.com/Ba4bes/New-AzDoServiceConnection/blob/main/NewAzDoServiceConnection/NewAzDoServiceConnection.psm1
