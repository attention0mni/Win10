@echo OFF
set host=host-ip
set zsend=E:\Distr\ZabbixAgent\zabbix_sender.exe -z %host% -s FortMonitor -k fm3-base-backup -o
set log=E:\logs\fm3-backup.log

echo %DATE% -%TIME% >> %log%
::Создаем дамп базы
"%ProgramFiles%\MySQL\MySQL Server 5.7\bin\mysqldump.exe" -ufm3 -P3306 -h127.0.0.1 --default-character-set=utf8 --single-transaction -pПАРОЛЬ fm3 > "E:\backup\fm3-base-%date%.sql" 2>> %log%
::Для лога и посылки в заббикс результата
::При успехе создания дампа переменная %errorlevel% будет хранить в себе 0, это и уйдет на заббикс. При неуспехе она будет хранить номер ошибки, что вызовет сработку триггера в заббиксе
if %errorlevel%==0 (echo "MySQL dump create - ok" >> %log% & %zsend% %errorlevel% 2>> %log%) else (echo "MySQL dump create - fail" >> %log% & %zsend% %errorlevel% 2>> %log%)

::Заливаем дамп 
scp E:\backup\fm3-base-%date%.sql isolovyev@%host%:\srv\backup\FortMonitor\ >> %log% 2>&1
::Для лога и посылки в заббикс результата, тут все так же как и в создании дампа
if %errorlevel%==0 (echo "MySQL dump download - ok" >> %log% & %zsend% %errorlevel% 2>> %log%) else (echo "MySQL dump download - fail" >> %log% & %zsend% %errorlevel% 2>> %log%)

::Удаляем из локальной папки файлы старше 7 дней
ForFiles /p "E:\backup" /s /d -7 /c "cmd /c del @file"
::Удаляем на удаленном хосте бекапы старше 7 дней
ssh isolovyev@%host% find /srv/backup/FortMonitor/ -type f -mtime +7 -exec rm -f {} \;
