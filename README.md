# USBGuard.github.io
Secure removable media instantly: an automated PowerShell script featuring real-time file interception, AES-256 compression, and tray notifications.

A lightweight, automated background PowerShell script that secures removable USB drives by intercepting file transfers and encrypting new files on-the-fly using AES-256 (via 7-Zip CLI). Built with a user-controlled hotkey toggle and native Windows toast notifications.

It works hand in hand with Windows Task Scheduler to run automatically without you having to switch it on and off all the time.

## Features
* **Automated File Interception:** Monitors connected removable drives in real-time using `FileSystemWatcher`.
* **AES-256 Encryption:** Securely compresses and encrypts unencrypted files into `.7z` archives using 7-Zip (`-mhe=on`).
* **Hotkey Control Toggle (`CTRL + ALT + U`):** Instantly toggle copy protection ON or OFF without killing the background process.
* **Visual Feedback:** Dynamic PowerShell window title updates and native Windows toast notifications for state changes.
* **Event Logging:** Records all encryption actions to a local log file (`C:\Scripts\USBGuard.log`).

## Tech Stack
* **Language:** PowerShell
* **Tools:** 7-Zip CLI, Windows Task Scheduler, Win32 API (`GetAsyncKeyState`)
