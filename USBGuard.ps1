Add-Type -AssemblyName System.Windows.Forms

$Password = "EqualEarth111EncryptionKey2580"
$7ZipPath = "C:\Program Files\7-Zip\7z.exe"
$Global:Authorized = $false

# Import API to check key presses in the loop
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class Win32Key {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@
Add-Type -TypeDefinition $pinvoke

$host.UI.RawUI.WindowTitle = "USBGuard - ON [PROTECTED]"
Write-Host "USB Guard Running..." -ForegroundColor Cyan
Write-Host "Press [CTRL + ALT + U] to toggle Copy Protection ON/OFF." -ForegroundColor Yellow


# Define FileSystemWatcher to monitor USB drives
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Scripts"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $false

# Function to Toast Notifications so you get native desktop pop-up alerts whenever protection toggles or files are encrypted.
function Show-Toast {
    param($Title, $Message)
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
    $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)
    $text = $xml.GetElementsByTagName("text")
    $text[0].AppendChild($xml.CreateTextNode($Title)) | Out-Null
    $text[1].AppendChild($xml.CreateTextNode($Message)) | Out-Null
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("USBGuard").Show($toast)
}

# Function to encrypt newly created/copied files
$action = {
    param($sender, $eventArgs)
    $filePath = $eventArgs.FullPath

    if ($filePath -like "*.7z" -or $filePath -like "*.tmp") { return }
    Start-Sleep -Milliseconds 800

    if (-not $Global:Authorized) {
        if (Test-Path $filePath -PathType Leaf) {
            $encryptedPath = "$filePath.7z"
            $logMessage = "$(Get-Date): Encrypting $filePath"
            Write-Host $logMessage -ForegroundColor Green
            Add-Content -Path "C:\Scripts\USBGuard.log" -Value $logMessage

            & $7ZipPath a -t7z -p"$Password" -mhe=on "$encryptedPath" "$filePath" | Out-Null
            
            if (Test-Path $encryptedPath) {
                Remove-Item -Path $filePath -Force
            }
        }
    }
}

Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null

$wasPressed = $false

while ($true) {
    # Check for CTRL (0x11) + ALT (0x12) + U (0x55)
    $ctrl = [Win32Key]::GetAsyncKeyState(0x11) -band 0x8000
    $alt = [Win32Key]::GetAsyncKeyState(0x12) -band 0x8000
    $u = [Win32Key]::GetAsyncKeyState(0x55) -band 0x8000

    if ($ctrl -and $alt -and $u) {
        if (-not $wasPressed) {
            $Global:Authorized = -not $Global:Authorized
            $wasPressed = $true
            if ($Global:Authorized) {
                Show-Toast "USBGuard" "Protection is OFF"
                Write-Host "`n[PROTECTION: OFF - Files will NOT be encrypted]" -ForegroundColor Yellow
                $host.UI.RawUI.WindowTitle = "USBGuard - OFF [UNPROTECTED]"
            } else {
                Show-Toast "USBGuard" "Protection is ON"
                Write-Host "`n[PROTECTION: ON - Files will be encrypted]" -ForegroundColor Cyan
                $host.UI.RawUI.WindowTitle = "USBGuard - ON [PROTECTED]"
            }
        }
    } else {
        $wasPressed = $false
    }

    # Poll for USB Drives and attach watcher
    $usbDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter }
    if ($usbDrives) {
        foreach ($drive in $usbDrives) {
            $path = "$($drive.DriveLetter):\"
            if ($watcher.Path -ne $path) {
                $watcher.Path = $path
                $watcher.EnableRaisingEvents = $true
            }
        }
    } else {
        $watcher.EnableRaisingEvents = $false
    }

    Start-Sleep -Milliseconds 200
}