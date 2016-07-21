# MS-SQL-2014_Database_Backup

Creates a Backup of all Databases on a Microsoft SQL-Server (MSSQL 2014)                       
and deletes older backups.   

You can set it up as one or more scheduled jobs (one for full and one for log backup)
                                                                          
                                                                          
PARAMETER                                                                
  -type { full | log }                                                     
                                                                         
Log backup is only possible, if the database is set to  
 "full" recovery mode (default is "simple", these databases will be skipped)     
                                                                          
You always NEED to run full backups. Log backups can be done between     
the full backups to reduce data loss.  
