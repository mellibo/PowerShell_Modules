$p = [Environment]::GetEnvironmentVariable("PSModulePath") + ";"
$p += Get-Location
[Environment]::SetEnvironmentVariable("PSModulePath",$p)
[Environment]::GetEnvironmentVariable("PSModulePath")

import-module ARSoft_Data
