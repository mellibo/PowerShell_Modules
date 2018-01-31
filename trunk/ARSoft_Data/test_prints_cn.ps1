import-module ARSOFT_SQL

$a= invoke-sqlcommand localhost "print 's'" 

$a= invoke-sqlcommand localhost "print 'pirulo'
print '2'
" 
