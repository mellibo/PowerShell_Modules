./import-module.ps1
get-content instancias.txt | execute-command -command "SELECT GETdate() date into #tmp"
