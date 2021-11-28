# Load the System.Windows.Forms assembly into PowerShell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'SilentlyContinue'
[string]$n = "`r`n"

# Create a new Form object and assign to the variable $Form
$Form = New-Object System.Windows.Forms.Form
$Form.MinimizeBox = $false
$Form.MaximizeBox = $false
$Form.SizeGripStyle = "Hide"
# $Form.ShowInTaskbar = $false
# $Form.StartPosition = "CenterParent"     
$Form.BackColor = "#FFEEEEEE"
$Form.Size = New-Object System.Drawing.Size(500, 500)
# AutoSize ensures the Form size can contain the text
$Form.AutoSize = $true
$Form.AutoSizeMode = "GrowAndShrink"
$Form.Text = "Lighthouse Labs VM  Installer"

$FontFace = New-Object System.Drawing.Font(
  "Comic Sans MS", 14, [System.Drawing.FontStyle]::Regular
)
$Form.Font = $FontFace

# Create a Label object
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "This will deploy a LHL WSL Image on your system"
$Label.AutoSize = $true
$Form.Controls.Add($Label)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Size(10, 150)
$outputBox.Size = New-Object System.Drawing.Size(565, 200)
$outputBox.MultiLine = $True
$outputBox.Scrollbars = "Vertical"
$FontFace = New-Object System.Drawing.Font(
  "Lucida Console", 12, [System.Drawing.FontStyle]::Regular
)
$outputBox.Font = $FontFace
$outputBox.TabStop = $false
$outputBox.ReadOnly = $true

$Form.Controls.Add($OutputBox)

$DeployButton = New-Object System.Windows.Forms.Button
$DeployButton.Location = New-Object System.Drawing.Size(230, 50)
$DeployButton.Size = New-Object System.Drawing.Size(110, 80)
$DeployButton.Text = "Step 2: `r`nDownload VM Image"
$DeployButton.Add_Click( { Import-Image } )
$Form.Controls.Add($DeployButton)

$EnableButton = New-Object System.Windows.Forms.Button
$EnableButton.Location = New-Object System.Drawing.Size(40, 50)
$EnableButton.Size = New-Object System.Drawing.Size(110, 80)
$EnableButton.Text = "Step 1: `r`nEnable WSL2"
$EnableButton.Add_Click( { EnableWSL })
$Form.Controls.Add($EnableButton)

$CloseButton1 = New-Object System.Windows.Forms.Button
$CloseButton1.Location = New-Object System.Drawing.Size(40, 50)
$CloseButton1.Size = New-Object System.Drawing.Size(110, 80)
$CloseButton1.Text = "Exit"
$CloseButton1.Add_Click( { $Form.Close() } )

$CloseButton2 = New-Object System.Windows.Forms.Button
$CloseButton2.Location = New-Object System.Drawing.Size(230, 50)
$CloseButton2.Size = New-Object System.Drawing.Size(110, 80)
$CloseButton2.Text = "Exit"
$CloseButton2.Add_Click( { $Form.Close() } )

$started = $false;
$tarFile = "$env:temp\Lighthouse_wsl-v1.2.tar"

function Write-Textbox {
  param  ( [string]$text, [int] $nl = 0)

  [string]$txt = "$text$n"
  for ($i = 0; $i -lt $nl; $i++) {
    $txt += $n
  }
  $outputBox.text += "$txt"
}

function  EnableWSL {
  $error.Clear()
  # $EnableButton.Enabled = $false
  $DeployButton.Enabled = $false
  $EnableButton.Text = "Running"

  $isAdmin = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  Write-Textbox "Admin=$isAdmin" 1
  if (!$isAdmin) {
    Write-Textbox 'This Part of the process requires PowerShell to be started as Administrator' 1
    Write-Textbox 'Please run PowerShell as Administrator and re-run'
 
    $Form.Controls.Remove($EnableButton)
    $Form.Controls.Add($CloseButton1)
    return
  }

  # TODO: Download enable WSL cmd file

  Write-Textbox 'Enabling WSL ...'
  try {
    Invoke-Item 'D:\tmp\enable.cmd'
  }
  catch {
    Write-Textbox $out
  }

  Write-Textbox "Code = $LASTEXITCODE" 

  if (!$error) {
    $EnableButton.Text = "Done!"
    Write-Textbox 'Done'
  }
  Write-Textbox '$error'
}
function  Import-Image {
  if ($started) {
    return
  }
  $started = $true;
  $DeployButton.Enabled = $false
  $DeployButton.Text = "Running"
  Write-Host "started"

  $url = "https://www.dropbox.com/s/ybtx4cn1351z2pr/Lighthouse_wsl-v1.2.zip?dl=1"
  $TempFile = Download($url);
  $ZipFile = "$TempFile.zip"
  if (!$error) {
    Write-Host "Renaming: $ZipFile"
    Rename-Item -Path $TempFile -NewName $ZipFile
  }

  if (!$error) {
    UnPack($ZipFile);
  }

  if ($error) {
    Write-Textbox " `r`nDeploy Failed with errors"
  }

  Cleanup($ZipFile)
  $Form.Controls.Remove($DeployButton)
  $Form.Controls.Add($CloseButton2)

  Write-Textbox 'Done!'
}

function  Download {
  param ($url)

  $TempFile = New-TemporaryFile
  Write-Host "Downloading Archive: $url"
  Write-Host "Writing: $TempFile"
  
  try {
    Write-Textbox 'Downloading Archive ...'
    Invoke-WebRequest $url -OutFile  $TempFile
  }
  catch {
    Write-Textbox $error
  }

  return $TempFile 
}

function  UnPack {
  param ($Filename)
  Write-Textbox 'Extracting Archive ..'
  Write-Host "Unpacking: $Filename"
  
  try {
    Expand-Archive -Force  $Filename  -DestinationPath $env:temp
  }
  catch {
    Write-Textbox $error
  }
}

function  Cleanup {
  param ($ZipFile)
  Write-Textbox " `r`nCleaning up ..."
  Write-Host "Deleting: $ZipFile"
  Remove-Item $ZipFile
  # Remove-Item "$env:temp"

  Write-Host "Deleting: $tarFile"
  Remove-Item $tarFile
}

function Confirm-WSL-Version {
  # Detects if system has WSL version 5+ enabled
  # Note: this outputs multi-byte char response
  $output1 = Invoke-Expression 'c:\windows\system32\wsl.exe --status'
  foreach ($item in $output1) {
    $nstr = removeNulls($item)
    if ($nstr.length -gt 3) {
      Write-Host $nstr
      $match = ($nstr -Match "version: [4,5,6]")
      if ($match) {
        Write-Textbox  $nstr
      }
    }
  }
  return $match
}

function removeNulls {
  # Removes null chars from string
  param ($in)
  $out = $in -replace "`0" 
  return $out;
}

$wslEnabled = Confirm-WSL-Version 
Write-Host  "WSL2=$wslEnabled"
if ($wslEnabled) {
  Write-Textbox 'Your system has WSL2 enabled. Continue to Step 2'
  $DeployButton.Enabled = $true
  $EnableButton.Enabled = $false
  $EnableButton.text = "Step 1:`r`nDone"
}

[void] $Form.showDialog()