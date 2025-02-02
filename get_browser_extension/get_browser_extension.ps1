function Write-Output ([object] $Object, [object] $Param, [string] $Json) {
    if ($Object -and $Param.Log -eq $true) {
        $Rtr = Join-Path $env:SystemRoot 'system32\drivers\CrowdStrike\Rtr'
        if ((Test-Path $Rtr) -eq $false) { New-Item $Rtr -ItemType Directory }
        $Object | ForEach-Object { $_ | ConvertTo-Json -Compress >> "$Rtr\$Json" }
    }
    $Object | ForEach-Object { $_ | ConvertTo-Json -Compress }
}
$Param = if ($args[0]) { $args[0] | ConvertFrom-Json }
$Output = foreach ($User in (Get-WmiObject Win32_UserProfile | Where-Object {
$_.localpath -notmatch 'Windows' }).localpath) {
    foreach ($ExtPath in @('AppData\Local\Google\Chrome\User Data\Default\Extensions',
    'AppData\Local\Microsoft\Edge\User Data\Default\Extensions')) {
        $Path = Join-Path $User $ExtPath
        if (Test-Path $Path) {
            foreach ($Folder in (Get-ChildItem $Path | Where-Object { $_.Name -ne 'Temp' })) {
                foreach ($Item in (Get-ChildItem $Folder.FullName)) {
                    $Json = Join-Path $Item.FullName manifest.json
                    if (Test-Path $Json) {
                        Get-Content $Json | ConvertFrom-Json | ForEach-Object {
                            [PSCustomObject] @{
                                Username = $User | Split-Path -Leaf
                                Browser = if ($ExtPath -match 'Chrome') { 'Chrome' } else { 'Edge' }
                                Name = if ($_.name -notlike '__MSG*') { $_.name } else {
                                    $Id = ($_.name -replace '__MSG_','').Trim('_')
                                    @('_locales\en_US','_locales\en').foreach{
                                        $Msg = Join-Path (Join-Path $Item.Fullname $_) messages.json
                                        if (Test-Path -Path $Msg) {
                                            $App = Get-Content $Msg | ConvertFrom-Json
                                            (@('appName','extName','extensionName','app_name',
                                            'application_title',$Id).foreach{
                                                if ($App.$_.message) {  $App.$_.message }
                                            }) | Select-Object -First 1
                                        }
                                    }
                                }
                                Id = $Folder.Name
                                Version = $_.version
                                ManifestVersion = $_.manifest_version
                                ContentSecurityPolicy = $_.content_security_policy
                                OfflineEnabled = if ($_.offline_enabled) { $_.offline_enabled } else { $false }
                                Permissions = $_.permissions
                            } | ForEach-Object { if ($Param.Filter) {
                                $_ | Where-Object { $_.Extension -match $Param.Filter }} else { $_ }
                            }
                        }
                    }
                }
            }
        }
    }
}
Write-Output $Output $Param "get_browser_extension_$((Get-Date).ToFileTimeUtc()).json"