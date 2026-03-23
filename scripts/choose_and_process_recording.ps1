Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$batFile = Join-Path $scriptDir "process_recording.bat"

if (!(Test-Path $batFile)) {
    Write-Host "process_recording.bat not found"
    Read-Host "press enter to exit"
    exit
}

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Choose an audio or video file"
$dialog.Filter = "Media Files (*.mp4;*.mp3;*.wav;*.m4a)|*.mp4;*.mp3;*.wav;*.m4a|All Files (*.*)|*.*"
$dialog.Multiselect = $false

$result = $dialog.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected"
    Start-Sleep -Seconds 1
    exit
}

$selectedFile = $dialog.FileName
Write-Host "Selected file: $selectedFile"

& $batFile $selectedFile
Read-Host "press enter to exit"