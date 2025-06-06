param(
    [string]$CertName = "WebServerCert", # Name des Zertifikats
    [string]$CertPath = "Cert:\CurrentUser\My", # Speicherort des Zertifikats
    [string]$DnsName = "*.northeurope.cloudapp.azure.com", # DNS-Name des Webservers
    [string]$ExportPath = "$([System.IO.Path]::Combine($env:USERPROFILE, "Downloads"))\WebServerCert.pfx", # Exportpfad für das Zertifikat
    [string]$ExportPassword = "YourPassword" # Passwort für den Export
)

Write-Output "Erstelle selbstsigniertes Zertifikat für $DnsName..."
$cert = New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation $CertPath `
    -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 `
    -FriendlyName $CertName -NotAfter (Get-Date).AddYears(1)
Export-PfxCertificate -Cert $cert -FilePath $ExportPath -Password (ConvertTo-SecureString -String $ExportPassword -Force -AsPlainText)
Write-Output "Zertifikat erfolgreich erstellt und exportiert nach $ExportPath."
