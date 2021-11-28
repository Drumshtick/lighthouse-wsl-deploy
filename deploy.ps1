# Load the System.Windows.Forms assembly into PowerShell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

$Form.Controls.Add($OutputBox)

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(230, 50)
$Button.Size = New-Object System.Drawing.Size(110, 80)
$Button.Text = "Click to Start"
$Button.Add_Click( { OnClick } )
$Form.Controls.Add($Button)

$CloseButton = New-Object System.Windows.Forms.Button
$CloseButton.Location = New-Object System.Drawing.Size(230, 50)
$CloseButton.Size = New-Object System.Drawing.Size(110, 80)
$CloseButton.Text = "Close"
$CloseButton.Add_Click( { $Form.Close() } )

$started = $false;
$ErrorActionPreference = 'Stop'

function  OnClick {
  if ($started) {
    return
  }
  $started = $true;
  $Button.Enabled = $false
  $Button.Text = "Running"

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
    $outputBox.text += " `r`nDeploy Failed with errors"
  }
  else {
    $outputBox.text += " `r`nDone!"
  }

  Cleanup($ZipFile)
  $Form.Controls.Remove($Button)
  $Form.Controls.Add($CloseButton)
}

function  Download {
  param ($url)

  $TempFile = New-TemporaryFile
  Write-Host "Downloading Archive: $url"
  Write-Host "Writing: $TempFile"
  
  try {
    $outputBox.text += "Downloading Archive ..."
    Invoke-WebRequest $url -OutFile  $TempFile
  }
  catch {
    $outputBox.text += " `r`n$error"  
  }

  return $TempFile 
}

function  UnPack {
  param ($Filename)
  $outputBox.text += " `r`nExtracting Archive ..."
  Write-Host "Unpacking: $Filename"
  
  try {
    Expand-Archive $Filename 
    # Expand-Archive -Force $Filename -DestinationPath d:\tmp
  }
  catch {
    $outputBox.text += " `r`n$error"  
  }
}


function  Cleanup {
  param ($ZipFile)
  $outputBox.text += " `r`nCleaning up ..."
  Write-Host "Deleting: $ZipFile"
  Remove-Item $ZipFile
}

[void] $Form.showDialog()