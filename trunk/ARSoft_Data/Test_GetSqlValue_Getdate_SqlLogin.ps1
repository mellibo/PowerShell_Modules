./import-module.ps1
$fecha = get-sqlvalue -instance "(local)" -command "select getdate()" -login test -password test
$fecha.ToString("dd/MM/yyyy HH:mm:ss")

