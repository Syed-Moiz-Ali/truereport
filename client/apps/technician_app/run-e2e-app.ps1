$env:JAVA_HOME='C:\Users\sanja\jdk-25.0.5+8'
Set-Location 'E:\syed_moiz_ali\bitlogix\truereport\client\apps\technician_app'
flutter run -d web-server --web-port 8145 --web-hostname 127.0.0.1 --dart-define=API_BASE_URL=http://127.0.0.1:8080 -t lib/main.dart
