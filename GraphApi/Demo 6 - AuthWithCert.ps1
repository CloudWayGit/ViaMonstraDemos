<#
One form of credential that an application can use for authentication is a JSON Web Token (JWT) assertion
signed with a certificate that the application owns.
https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials#assertion-format
#>

$TenantName = "contoso.com"
$AppId = ""
$Certificate = Get-Item Cert:\CurrentUser\My\302FA0792DC36E2898AF7964D73AD13F0E19428F
$Scope = "https://graph.microsoft.com/.default"

# 1: Create a base64 hash of certificate
$CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())

# 2: Create JWT timestamp for expiration
$StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
$JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
$JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)
<#
The "exp" (expiration time) claim identifies the expiration time on or after which the JWT must not be accepted for processing. 
See RFC 7519, Section 4.1.4. This allows the assertion to be used until then, so keep it short - 5-10 minutes after nbf at most. 
Microsoft Entra ID does not place restrictions on the exp time currently.
#>

# Create JWT validity start timestamp
$NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
$NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)

<#
Using standard Base64 in URL requires encoding of '+', '/' and '=' characters into special percent-encoded hexadecimal sequences 
('+' becomes '%2B', '/' becomes '%2F' and '=' becomes '%3D'), which makes the string unnecessarily longer. 
For this reason, modified Base64 for URL variants exist, where the '+' and '/' characters of standard Base64 are respectively 
replaced by '-' and '_', so that using URL encoders/decoders is no longer necessary and have no impact on the length 
of the encoded value.
#>

# Create JWT header
$JWTHeader = @{
    alg = "RS256"
    typ = "JWT"
    # Use the CertificateBase64Hash and replace/strip to match web encoding of base64
    x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='
}

# Create JWT payload
$JWTPayLoad = @{
    # What endpoint is allowed to use this JWT
    aud = "https://login.microsoftonline.com/$TenantName/oauth2/token"
    # The "exp" (expiration time) claim identifies the expiration time on or after which the JWT must not be accepted for processing.
    exp = $JWTExpiration
    # The "iss" (issuer) claim identifies the principal that issued the JWT, in this case your client application.
    iss = $AppId
    # JWT ID: random guid - The "jti" (JWT ID) claim provides a unique identifier for the JWT. 
    jti = [guid]::NewGuid()
    # The "nbf" (not before) claim identifies the time before which the JWT MUST NOT be accepted for processing
    nbf = $NotBefore
    # The "sub" (subject) claim identifies the subject of the JWT, in this case also your application. Use the same value as iss
    sub = $AppId
}

# Convert header and payload to JSON/Bytes and then to base64
$JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
$EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)
$JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
$EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)

# Join header and Payload with "." to create a valid (unsigned) JWT
$JWT = $EncodedHeader + "." + $EncodedPayload

# Get the private key object of your certificate
$PrivateKey = $Certificate.PrivateKey

# Define RSA signature and hashing algorithm
$RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
$HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256

# Create a signature of the JWT
$Signature = [Convert]::ToBase64String(
    $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
) -replace '\+','-' -replace '/','_' -replace '='

# Join the signature to the JWT with "."
$JWT = $JWT + "." + $Signature

# Create a hash with body parameters
$Body = @{
    client_id = $AppId
    client_assertion = $JWT
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    scope = $Scope
    grant_type = "client_credentials"

}

$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

# Use the self-generated JWT as Authorization
$Header = @{
    Authorization = "Bearer $JWT"
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    Body = $Body
    Uri = $Url
    Headers = $Header
}

$AuthRequest = Invoke-RestMethod @PostSplat

$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "bearer $($AuthRequest.access_token)"
}

$uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?filter=(isof(%27microsoft.graph.iosVppApp%27))%20and%20(microsoft.graph.managedApp/appAvailability%20eq%20null%20or%20microsoft.graph.managedApp/appAvailability%20eq%20%27lineOfBusiness%27%20or%20isAssigned%20eq%20true)"



$MobileApps = Invoke-RestMethod -Method "Get" -Uri $uri -Headers $AuthenticationHeader -ContentType "application/json"
($MobileApps.value).displayName



# Using the AZ module
Connect-AzAccount -CertificateThumbprint $Certificate.Thumbprint -Tenant $TenantName -ApplicationId $AppId 
$MyToken = Get-AzAccessToken -ResourceTypeName MSGraph 
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "bearer $($NewToken.token)"
}