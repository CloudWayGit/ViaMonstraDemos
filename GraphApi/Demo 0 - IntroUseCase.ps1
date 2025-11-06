# User story : 
# User quits and you want to wipe their device and remove it from Intune, Autopilot and Entra ID
# 
# Prerequisites:
# You have the user principal name (UPN) of the user who is leaving 
$UPN = "<user@domain.com>"

# Connect to Microsoft Graph with the correct scopes
Connect-MgGraph -Scopes "User.Read.All", "Device.Read.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All"

# Lets start with getting all the devices for that user using Microsoft Graph SDK
# Get-MgUserOwnedDevice doesn't support server-side filtering with the -Filter parameter. 
# You need to retrieve all devices and then filter them in PowerShell

$UserDevices = Get-MgUserOwnedDevice -UserId $UPN 

# The issue is that Get-MgUserOwnedDevice returns minimal properties by default. 
# You need access properties through AdditionalProperties, this is the only way. 
# The SDK Approach have limitations compared to REST API 

# Lets us create a loop to show all devices for that user that is running Window and return displayName, id, operatingSystem and physicalIds

$DeviceArray = @()
foreach ($Device in $UserDevices) {
    $DeviceProps = $Device.AdditionalProperties
    if ($DeviceProps.operatingSystem -like "Windows*") {
        $DeviceInfo = [PSCustomObject]@{
            DisplayName     = $DeviceProps.displayName
            Id              = $Device.Id
            OperatingSystem = $DeviceProps.operatingSystem
            PhysicalIds     = $DeviceProps.physicalIds
        }
        $DeviceArray += $DeviceInfo
    }
}
Write-Output $DeviceArray

# Let's do the same using REST API
# First we need to get the authentication headers 

#Extract RAW token from current session to use for Native REST API calls
$Request = @{
  Method = "GET"
  URI = "/v1.0/me"
  OutputType = "HttpResponseMessage"
}
$Response = Invoke-GraphRequest @Request
$Headers = $Response.RequestMessage.Headers
$Token = $Headers.Authorization.Parameter
#$Token | Set-Clipboard

# Create proper header with the extracted token
$AuthenticationHeaders = @{
    Authorization = "Bearer $Token"
    'Content-Type' = 'application/json'
}
Write-Output $AuthenticationHeaders

# Lets start with getting all the devices for that user using REST API
# Rest API supports server-side selecting properties but not filtering on device type directly in this endpoint
$URL = "https://graph.microsoft.com/v1.0/users/$($UPN)/ownedDevices"
$Select = "?`$select=id,displayName,operatingSystem,physicalIds"

$Parameters = @{
    Method = "Get"
    Uri = "$($URL)$($Select)"
    Headers = $AuthenticationHeaders
    ContentType = "application/json"
}

$UserDevices = (Invoke-RestMethod @Parameters).value

 #Filter out the Windows devices 
$WindowsDevices = $UserDevices | Where-Object { $_.operatingSystem -like "Windows*" }

# Now we have all the Windows devices for that user, 
# We can loop through them and wipe them and remove them from Autopilot if they are registered there before we delete them from Entra ID
# First we need to check if the device is actually Intune managed
# We can do that by checking if the device is found in Intune managed devices by looking for the Entra ID Device ID.

# Lets start with adding Entra Device ID to each device in our WindowsDevices array
foreach ($Device in $WindowsDevices) {
    # Get the device details to extract the Entra Device ID
    $DeviceDetailsURL = "https://graph.microsoft.com/v1.0/devices/$($Device.id)?`$select=deviceId"
    $DeviceDetailsParameters = @{
        Method = "GET"
        Uri = $DeviceDetailsURL
        Headers = $AuthenticationHeaders
    }
    $DeviceDetails = Invoke-RestMethod @DeviceDetailsParameters
    $Device | Add-Member -MemberType NoteProperty -Name "EntraIDDeviceId" -Value $DeviceDetails.deviceId
}
 
# Loop through each Windows device
foreach ($Device in $WindowsDevices) {
    # As we might have several thousands of managed devices we need to match based on Entra Device ID
    $URL = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=azureADDeviceId eq '$($Device.EntraIDDeviceId)'"
    $ManagedDevice = (Invoke-RestMethod -Uri $URL -Headers $AuthenticationHeaders).value

    if ($ManagedDevice -and $ManagedDevice.Count -gt 0) {
        Write-Output "Device $($Device.displayName) is Intune managed. Initiating wipe..."
        # Lets fake the wipe command
        #$WipeURL = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($ManagedDevice.id)/wipe"
        #$WipeParameters = @{
        #    Method = "POST"
        #    Uri = $WipeURL
        #    Headers = $AuthenticationHeaders
        #    Body = @{
        #        keepEnrollmentData = $false
        #        keepUserData = $false
        #        macOsUnlockCode = $null
        #    } | ConvertTo-Json
        #}
        #Invoke-RestMethod @WipeParameters
        Write-Output "Wipe command sent for device $($Device.displayName)"
    } else {
        Write-Output "Device $($Device.displayName) is NOT Intune managed."
    }
}

# Even though we have wiped the device we still need to remove it from Autopilot and Entra ID
# Loop through each Windows device again to check Autopilot registration
# We should do this later on in the lifecycle but for demo purposes we do it here


foreach ($Device in $WindowsDevices) {
   if ($Device.physicalIds -match "ZTDID") {
        Write-Output "Device $($Device.displayName) is registered in Autopilot"
        # lets find the autopilot id from https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/
        # First we need to extract the autopilot ID from physicalIds
        $ZTDIDEntry = $Device.physicalIds | Where-Object { $_ -match '\[ZTDID\]' }
        $AutoPilotID = ($ZTDIDEntry -split ':')[1]
        Write-Output "Autopilot ID for device $($Device.displayName) is $AutoPilotID"
        #Lets fake that we delete the autopilot device 
        #$DeleteURL = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$AutoPilotID"
        #$DeleteParameters = @{
        #    Method = "DELETE"
        #    Uri = $DeleteURL
        #    Headers = $AuthenticationHeaders
        #}
        #Invoke-RestMethod @DeleteParameters
        # and lets get the autopilot device to confirm its the right one
        $GetAutoPilotURL = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$AutoPilotID"
        $GetAutoPilotParameters = @{
            Method = "GET"
            Uri = $GetAutoPilotURL
            Headers = $AuthenticationHeaders
        }
        $AutoPilotDevice = Invoke-RestMethod @GetAutoPilotParameters
        Write-Output "Autopilot Device Info:"
        Write-Output "  ID: $($AutoPilotDevice.id)"
        Write-Output "  EntraID_DeviceID: $($AutoPilotDevice.azureActiveDirectoryDeviceId)"
        Write-Output "  SerialNumber: $($AutoPilotDevice.serialNumber)"
    } else {
        Write-Output "Device $($Device.displayName) is NOT registered in Autopilot"
        # Device is not in Autopilot, so lets continue to just delete the device from Entra ID 
        $EntraDeviceObjectID = $Device.id
        Write-Output "Entra Device ObjectID for device $($Device.displayName) is $EntraDeviceObjectID"
        # Lets fake that we delete the Entra device
        #$DeleteEntraURL = "https://graph.microsoft.com/v1.0/devices/$EntraDeviceObjectID"
        #$DeleteEntraParameters = @{
        #    Method = "DELETE"
        #    Uri = $DeleteEntraURL
        #    Headers = $AuthenticationHeaders
        #}
        #Invoke-RestMethod @DeleteEntraParameters

        # Just to confirm we have the right device, lets get the device info
        $GetEntraDeviceURL = "https://graph.microsoft.com/v1.0/devices/$EntraDeviceObjectID"
        $GetEntraDeviceParameters = @{
            Method = "GET"
            Uri = $GetEntraDeviceURL
            Headers = $AuthenticationHeaders
        }
        $EntraDevice = Invoke-RestMethod @GetEntraDeviceParameters
        Write-Output "Entra Device Info:"
        Write-Output "  ID: $($EntraDevice.id)"
        Write-Output "  DisplayName: $($EntraDevice.displayName)"
    }
}



