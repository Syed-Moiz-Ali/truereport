Set-Location "E:\syed_moiz_ali\bitlogix\truereport\server"

$env:JAVA_HOME = "C:\Users\sanja\jdk-25.0.5+8"
$env:MYSQL_ROOT_PASSWORD = "admin"
$env:DB_USER = "truereport"
$env:DB_PASSWORD = "truereport123"
$env:DEV_SEED_PASSWORD = "Truereport#Local123"
$env:JWT_SECRET = "IIKCjRAxRM0EzKjMi1rPIHZLLvo27SEw/TMYaGAqs7g="
$env:APP_ENCRYPTION_KEY = "FkT7VyjXoZ+0Wv7lyjPBM8QYjiYFE2ZraqpAqyoSZsQ="
$env:DB_URL = "jdbc:mysql://localhost:3306/truereport?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8"
$env:DEV_SEED_ENABLED = "true"
$env:MANAGEMENT_HEALTH_MAIL_ENABLED = "false"
$env:SPRING_PROFILES_ACTIVE = "dev"

mvn spring-boot:run
