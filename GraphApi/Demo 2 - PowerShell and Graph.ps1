# Demo, request data
# Permissions "APP-Only" for Demo
# DeviceManagementConfiguration.ReadWrite.All
# DeviceManagementManagedDevices.ReadWrite.All
# DeviceManagementServiceConfig.ReadWrite.All
# User.ReadWrite.All

# Construct a request using GET method
# - Retrieve data from Graph API using Invoke-RestMethod
# - We need a proper Authentication Header first (see previous demos)
# Lets use the Native Rest API method to get the header again
$body = @{
    "client_id" = $ApplicationClientId
    "client_secret" = $ApplicationClientSecret
    "scope" = "https://graph.microsoft.com/.default"
    "grant_type" = "client_credentials"
}

$AuthenticationUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$Auth = Invoke-RestMethod -Method Post -Uri $AuthenticationUri -Body $body -ContentType "application/x-www-form-urlencoded"

$AuthenticationHeader = @{
    Authorization = "Bearer $($Auth.access_token)"
    "Content-Type" = "application/json"
}

$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$ManagedDevices = Invoke-RestMethod @Parameters
$ManagedDevices | Select-Object -ExpandProperty value | Select-Object id, deviceName, operatingSystem, complianceState, userPrincipalName| Format-Table -AutoSize

# Construct a request using POST method
# - Add a new item resource to Graph API
# - Create a new Assignment Filter in Intune
$BodyTable = @{
    displayName = "Hyper-V Devices"
    platform = "windows10AndLater"
    rule = '(device.model -startsWith "Virtual Machine") and (device.manufacturer -startsWith "Microsoft")'
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
    displayName = "ViaMonstra Hyper-V Devices"
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



# Using query parameters - Filtering
#
$SerialNumber = "<serialnumber>"
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($SerialNumber)')"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AutopilotDevice = Invoke-RestMethod @Parameters
$AutopilotDevice.value
$AutopilotDeviceIdentity = $AutopilotDevice.value.id
$ManagedDevicesID = $AutopilotDevice.value.managedDeviceId

#
# Using query parameters - Expanding data
#
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($ManagedDevicesID)"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$ManagedDevice = Invoke-RestMethod @Parameters
$ManagedDevice

$Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($AutopilotDeviceIdentity)?`$expand=deploymentProfile,intendedDeploymentProfile"
$Parameters = @{
    Method = "Get"
    Uri = $Uri
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$AutopilotDeviceDeploymentProfile = Invoke-RestMethod @Parameters
$AutopilotDeviceDeploymentProfile.deploymentProfile
$AutopilotDeviceDeploymentProfile.deploymentProfile.displayName


#BONUS DEMO - Moving to the dark side!! 
# Get and update a User object
$UserPrincipalName = "<user@domain.com>"
$Parameters = @{
    Method = "Get"
    Uri = "https://graph.microsoft.com/v1.0/users/$($UserPrincipalName)"
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
$User = Invoke-RestMethod @Parameters
$User

# Update the User object
$BodyTable = @{
    displayName = "Darth Vader"
    jobTitle = "Sith Lord"
    officeLocation = "Death Star"
}
$Parameters = @{
    Method = "Patch"
    Uri = "https://graph.microsoft.com/v1.0/users/$($UserPrincipalName)"
    Body = ($BodyTable | ConvertTo-Json)
    Headers = $AuthenticationHeader
    ContentType = "application/json"
}
Invoke-RestMethod @Parameters