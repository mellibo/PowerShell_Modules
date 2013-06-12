./import-module.ps1
$fecha = get-sqlvalue -instance "(local)" -command "select getdate()" 
$fecha.ToString("dd/MM/yyyy HH:mm:ss")

