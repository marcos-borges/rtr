## SYNOPSIS
List local users

## PARAMETER Filter
Restrict list using a RegEx pattern

## PARAMETER Log
Save results within a Json file in the Rtr directory

## EXAMPLES

### REAL-TIME RESPONSE
```
runscript -CloudFile="get_local_user" -CommandLine=```'{"Filter":"Username"}'```
```
### PSFALCON
```
PS>$CommandLine = '```' + "'$(@{ Filter = 'Username' } | ConvertTo-Json -Compress)'" + '```'
PS>Invoke-FalconRtr runscript "-CloudFile='get_local_user' -CommandLine=$CommandLine" -HostIds <id>, <id>
```
### FALCONPY
