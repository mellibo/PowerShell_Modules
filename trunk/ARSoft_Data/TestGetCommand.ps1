./import-module.ps1
$SqlConnection = Get-Connection "(local)" "msdb"
$SqlConnection.ConnectionString
$SqlConnection.Open()
$SqlCmd = Get-Command $SqlConnection "SELECT * FROM sysjobs" 
$SqlCmd.ExecuteNonQuery();
$SqlConnection.Close()
