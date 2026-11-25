$env:JAVA_HOME='C:\Users\sanja\jdk-25.0.5+8'
$env:DB_URL='jdbc:mysql://localhost:3306/truereport?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8'
$env:DB_USER='truereport'
$env:DB_PASSWORD='truereport123'
$env:JWT_SECRET='IIKCjRAxRM0EzKjMi1rPIHZLLvo27SEw/TMYaGAqs7g='
$env:APP_ENCRYPTION_KEY='FkT7VyjXoZ+0Wv7lyjPBM8QYjiYFE2ZraqpAqyoSZsQ='
$env:DEV_SEED_ENABLED='true'
$env:DEV_SEED_PASSWORD='Truereport#Local123'
$env:SPRING_PROFILES_ACTIVE='dev'
$env:MANAGEMENT_HEALTH_MAIL_ENABLED='false'

# Content translation requires LibreTranslate. Start/reuse it before the API so
# the worker never falls back to the fake provider.
& (Join-Path $PSScriptRoot 'tools\ensure-libretranslate.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'LibreTranslate is required for content translation and could not be started.'
}
$env:I18N_TRANSLATION_PROVIDER='libretranslate'
$env:LIBRETRANSLATE_URL='http://localhost:5000'
$env:LIBRETRANSLATE_TIMEOUT='30s'

Set-Location 'E:\syed_moiz_ali\bitlogix\truereport\server'
mvn spring-boot:run
