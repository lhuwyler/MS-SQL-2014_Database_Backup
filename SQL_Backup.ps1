#==========================================================================#
# Microsoft SQL 2014 Database Backup                                       #
#==========================================================================#
#                                                                          #
# Creates a Backup of all Databases on a SQL-Server                        #
# and deletes older backups.                                               #
#                                                                          #
#                                                                          #
# PARAMETER                                                                #
# -type { full | log }                                                     #
#                                                                          #
# Log backup is only possible, if the database is set to "full"            #
# recovery mode (default is "simple", these databases will be skipped)     #
#                                                                          #
# You always NEED to run full backups. Log backups can be done between     #
# the full backups to reduce data loss.                                    #
#                                                                          #
#                                                                          #
# Changelog:                                                               #
# 2015-06-25 Huwylerl: created                                             #
#                                                                          #
#==========================================================================#

param (
    [string]$type = "log"
)

#*************************
# Config
#*************************

# Backup Settings

$retentionDays    = 8
$backupPath       = "G:\Backup\"

# Server Settings

$sqlserver        = "localhost"

# Mail Settings

$mailadress       = "yourMail@mail.com"
$smtpserver       = "yourSMTPserver"

#*************************
# Functions
#*************************

# delete all files older than the retention time
function cleanup()
{
    $files = Get-ChildItem $backupPath  
    foreach ($file in $files)
    {
        if(($file.CreationTime -lt (get-date).AddDays($retentionDays * -1)) -and ($file.Name -like "*.bak" -or "*.log"))
        {
            remove-item $file.PSPath
        }
    }
}

# send exception as mail 
function sendErrorMail($exception)
{
    # create error mail message
    $errormessage =  ("SERVER:`t" + $env:COMPUTERNAME)
    $errormessage += ("`n`nBACKTYPE:`t" + $type)
    $errormessage += ("`n`nERROR:`t" + $exception.Exception)
    $errormessage += ("`n`nTRACE:`t" + $exception.ScriptStackTrace)

    # send error mail
    Send-MailMessage `
        -SmtpServer $smtpserver `
        -From ($env:COMPUTERNAME + "@berufzug.ch") `
        -To $mailadress `
        -Subject "SQL Backup failed" `
        -Body $errormessage
}

#*************************
# main
#*************************

try 
{
    
    # import sql commandset
    Import-Module SQLPS -erroraction stop 3> $null

    # get list of database Objects on target server
    $databases = Get-SqlDatabase -ServerInstance $sqlserver -ErrorAction stop

    #perform Full backup
    if ($type -eq "full")
    {
        foreach ($database in $databases)
        {
            # exclude tempdb (can not be backed up)
            if($database.Name -ne "tempdb")
            {
                $filename = ($backupPath + $database.Name + "_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + "_FULL.bak")

                Backup-SqlDatabase `
                    -ServerInstance $sqlserver `
                    -Database $database.Name `
                    -BackupFile $filename `
                    -BackupAction Database
            }
        }
    }

    #perform Log backup
    elseif ($type -eq "log")
    {
        foreach ($database in $databases)
        {
            # exclude databases in "simple"-Mode
            if($database.RecoveryModel -eq "Full")
            {
                $filename = ($backupPath + $database.Name + "_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + "_Log.log")

                Backup-SqlDatabase `
                    -ServerInstance $sqlserver `
                    -Database $database.Name `
                    -BackupFile $filename `
                    -BackupAction Log
            }
        }
    }

    #invalid parameter
    else 
    {
        throw ('Invalid parameter... type "full" or "log"')
    }

    cleanup
}

catch 
{
    sendErrorMail $_
}
