# Demo, request data

# First things first, authenticate
$Parameters = @{
    TenantId = "contoso.onmicrosoft.com"
    ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
    RedirectUri = "http://localhost"
    Scopes = "https://graph.microsoft.com/DeviceManagementConfiguration.ReadWrite.All"
}
$AccessToken = Get-MsalToken @Parameters
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = $AccessToken.CreateAuthorizationHeader()
    "ExpiresOn" = $AccessToken.ExpiresOn.LocalDateTime
}

#
# Construct a request using GET method
# - Retrieve data from Graph API
#
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$ManagedDevices = Invoke-RestMethod @Parameters
$ManagedDevices.value.deviceName

#
# Construct a request using POST method
# - Add a new item resource to Graph API
#
$BodyTable = @{
    displayName = "HP Devices"
    platform = "windows10AndLater"
    rule = '(device.manufacturer -eq "HP")'
}
$Parameters = @{
    Method = "Post"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
    Body = ($BodyTable | ConvertTo-Json)
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$MyFilter = Invoke-RestMethod @Parameters
Write-Output $MyFilter


#
# Construct a request using PATCH method
# - Update an existing property of an item resource in Graph API
#
Invoke-RestMethod -Method "Get" -Uri "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($MyFilter.id)" -Headers $AuthenticationHeader -ContentType "application/json"

$BodyTable = @{
    displayName = "VIAMONSTRA HP Devices"
}
$Parameters = @{
    Method = "Patch"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($MyFilter.id)"
    Body = ($BodyTable | ConvertTo-Json)
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
Invoke-RestMethod @Parameters

#
# Construct a request using PATCH method, sometimes requires the @odata.type property with the value of the data type
#
$BodyTable = @{
    "@odata.type" = "#microsoft.graph.win32LobApp"
    "displayName" = "7-Zip"
}

#
# Construct a request using DELETE method
# - Remove an item resource from Graph API
#
$Parameters = @{
    Method = "Delete"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($MyFilter.id)"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
Invoke-RestMethod @Parameters

Invoke-RestMethod -Method "Get" -Uri "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($MyFilter.id)" -Headers $AuthenticationHeader -ContentType "application/json"




#
# Using query parameters - Filtering
#
$SerialNumber = "1604-3388-1498-6543-3908-1929-08"
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($SerialNumber)')"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AutopilotDevice = Invoke-RestMethod @Parameters
$AutopilotDevice.value

#
# Using query parameters - Expanding data
#
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/4f825105-901a-4f6f-8c0b-960f166b735c"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AutopilotDevice = Invoke-RestMethod @Parameters
$AutopilotDevice

$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/3692c6c0-a12a-4cfb-b28c-42afa8805703?`$expand=deploymentProfile,intendedDeploymentProfile"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AutopilotDeviceDeploymentProfile = Invoke-RestMethod @Parameters
$AutopilotDeviceDeploymentProfile.deploymentProfile
$AutopilotDeviceDeploymentProfile.deploymentProfile.displayName


#
# Using query parameters - Filtering on a collection property
#
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/v1.0/devices?`$filter=physicalIds/any(p:p eq '[OrderId]:VIAMONSTRA')"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AzureADDevice = Invoke-RestMethod @Parameters
$AzureADDevice.value | Select-Object -Property "id", "displayName", "physicalIds"


#
# Using query parameters - Filtering for a given @odata.type
#
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=(isof('microsoft.graph.windows10CustomConfiguration'))"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$CustomProfiles = Invoke-RestMethod @Parameters
$CustomProfiles.value | Select-Object -Property '@odata.type', "id", "displayName"
