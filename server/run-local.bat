@echo off
REM =====================================================================
REM TrueReport backend - ONE file runner (testing only, no Docker needed)
REM Uses your local MySQL80 + Workbench. Production setup is separate.
REM
REM FIRST TIME ONLY:
REM   1. Start MySQL80: Windows Services -^> MySQL80 -^> Start
REM   2. Put YOUR MySQL root password after MYSQL_ROOT_PASSWORD= below
REM   3. Double-click this file. Done.
REM
REM IMPORTANT: run this file from the server folder. Do NOT run
REM `mvn spring-boot:run` directly: it needs DB_USER / DB_PASSWORD /
REM JWT_SECRET / APP_ENCRYPTION_KEY, which this file sets below.
REM If port 8080 is already in use, stop the other backend process first.
REM
REM Login: platform@truereport.test / <local DEV_SEED_PASSWORD>
REM App: http://localhost:8080  Swagger: http://localhost:8080/swagger-ui.html
REM =====================================================================

REM ---- EDIT THIS LINE ONLY (your MySQL root password) ----
set MYSQL_ROOT_PASSWORD=admin

REM ---- testing-only values, already filled, do not touch ----
set DB_USER=truereport
set DB_PASSWORD=truereport123
set DEV_SEED_PASSWORD=Truereport#Local123
set JWT_SECRET=IIKCjRAxRM0EzKjMi1rPIHZLLvo27SEw/TMYaGAqs7g=
set APP_ENCRYPTION_KEY=FkT7VyjXoZ+0Wv7lyjPBM8QYjiYFE2ZraqpAqyoSZsQ=
set JAVA_HOME=C:\Users\sanja\jdk-25.0.5+8
set MYSQL_CLIENT="C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"

cd /d "%~dp0"

REM ---- wait for MySQL80 (up to ~60s) ----
echo Waiting for MySQL on localhost:3306 ...
set TRIES=0
:waitmysql
powershell -NoProfile -Command "$c = New-Object Net.Sockets.TcpClient; try { $c.Connect('127.0.0.1', 3306); $c.Close(); exit 0 } catch { exit 1 }"
if %ERRORLEVEL%==0 goto mysqlup
set /a TRIES+=1
if %TRIES% GEQ 30 (
  echo.
  echo MySQL is not running. Start it: Windows Services -^> MySQL80 -^> Start, then re-run this file.
  goto end
)
powershell -NoProfile -Command "Start-Sleep -Seconds 2"
goto waitmysql

:mysqlup
echo MySQL is up. Creating database and user if needed ...
%MYSQL_CLIENT% --protocol=TCP -h 127.0.0.1 -uroot -p"%MYSQL_ROOT_PASSWORD%" -e "SET GLOBAL log_bin_trust_function_creators = 1; CREATE DATABASE IF NOT EXISTS truereport CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; CREATE USER IF NOT EXISTS 'truereport'@'localhost' IDENTIFIED BY '%DB_PASSWORD%'; GRANT ALL PRIVILEGES ON truereport.* TO 'truereport'@'localhost'; FLUSH PRIVILEGES;"
if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Could not set up the database. Check MYSQL_ROOT_PASSWORD at the top of this file.
  goto end
)

REM ---- backend env (same as Docker/prod, testing values) ----
set DB_URL=jdbc:mysql://localhost:3306/truereport?useSSL=false^&allowPublicKeyRetrieval=true^&serverTimezone=UTC^&characterEncoding=utf8
set DEV_SEED_ENABLED=true
set MANAGEMENT_HEALTH_MAIL_ENABLED=false
set SPRING_PROFILES_ACTIVE=dev

powershell -NoProfile -Command "$c = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue; if (-not $c) { exit 0 }; $owner = ($c.OwningProcess | Select-Object -First 1); $p = Get-Process -Id $owner -ErrorAction SilentlyContinue; if ($p -and $p.ProcessName -eq 'java') { Write-Output 'Stopping existing backend on port 8080 ...'; Stop-Process -Id $owner -Force; Start-Sleep -Seconds 2; exit 0 }; exit 1"
if %ERRORLEVEL%==1 (
  echo.
  echo Port 8080 is in use by a non-Java process. Stop it and re-run.
  goto end
)

echo Starting backend ...
mvn spring-boot:run

:end
echo.
echo Stopped. Press any key to close...
pause >nul
