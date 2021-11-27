# Load the System.Windows.Forms assembly into PowerShell
Add-Type -AssemblyName System.Windows.Forms

# Create a new Form object and assign to the variable $Form
$Form = New-Object System.Windows.Forms.Form
$Form.MinimizeBox = $false
$Form.MaximizeBox = $false
# $Form.ShowInTaskbar = $false
# $Form.StartPosition = "CenterParent"     
$Form.BackColor = "#FFEEEEEE"
$Form.Size = New-Object System.Drawing.Size(600,400)
# AutoSize ensures the Form size can contain the text
# $Form.AutoSize = $true
$Form.AutoSizeMode = "GrowOnly"

$Form.Text = "Lighthouse Labs VM  Installer"

$FontFace = New-Object System.Drawing.Font(
  "Comic Sans MS",14,[System.Drawing.FontStyle]::Regular
  )
  
# Initialize the forms font
$Form.Font = $FontFace

# Create a Label object
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "This will deploy the LHL WSL Image on your system"
$Label.AutoSize = $true
$Form.Controls.Add($Label)


$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Size(10,150)
$outputBox.Size = New-Object System.Drawing.Size(565,200)
$outputBox.MultiLine = $True
$Form.Controls.Add($OutputBox)

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(200,60)
$Button.Size = New-Object System.Drawing.Size(110,80)
$Button.Text = "Click to Start"
$Button.Add_Click( { OnClick } )
$Form.Controls.Add($Button)



function  OnClick {
  Write-Host "started"
  
}

function getImage {
  # Download archive
  Write-Host "Downloading Archive"
  Invoke-WebRequest 'www.google.ca' -OutFile 'd:\tmp\test.html'
  
  # extract archive
  Write-Host "Extracting Archive"
  Expand-Archive d:\tmp\test.zip -DestinationPath d:\tmp
  
}





[void] $Form.showDialog()