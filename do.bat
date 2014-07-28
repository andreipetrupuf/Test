@echo off
SETLOCAL
SET PROJECTS_PATH=d:\AndreiI\EANProjects

SET BRAVO_PROJECT=%PROJECTS_PATH%\chamDev-bravo
SET BRAVO_TARGET=%BRAVO_PROJECT%\target

SET TRAVELNOW_PROJECT=%PROJECTS_PATH%\chamDev-travelnow
SET TRAVELNOW_TARGET=%TRAVELNOW_PROJECT%\target

SET CHAMDEV_PROJECT=%PROJECTS_PATH%\chamDev\

SET TEMPLATES_TARGET=%CHAMDEV_PROJECT%\ean-templates\target\
SET CP_TARGET=%CHAMDEV_PROJECT%\ean-controlpanel\target\

SET TEMPLATES_SERVER=C:\tomcat-templates\webapps\
SET CP_SERVER=C:\tomcat-cp\webapps\

SET THEMES_SERVER=C:\tomcat-templates\themes\jars
SET MATERIALIZED=C:\tomcat-templates\themes\materialized
PUSHD %CD%

:init_labels
if "%1"=="chk" (
	if "%2"=="all" (
		GOTO :check_all
	)
)

if "%1"=="start" (
	if "%2"=="tmp" (
		if "%3"=="debug" (
			GOTO :start_all_debug_tmp
		) else (
			GOTO :start_all_no_debug_tmp
		)
	) else if "%2"=="cp" (
		if "%3"=="debug" (
			GOTO :start_all_debug_cp
		) else (
			GOTO :start_all_no_debug_cp
		)
	)
)	
	
if "%1"=="deploy" (
	if "%2"=="-s" (
		SET BUILD_SOLO=1
		if "%3"=="temp" (
			if "%4"=="skt" (
				SET TEMPLATES_SKIP_TESTS=1
			)
			GOTO :deploy_templates
		) else if "%3"=="cp" (
			if "%4"=="skt" (
				SET CP_SKIP_TESTS=1
			)
			GOTO :deploy_cp
		)
	) else if "%2"=="temp" (
		if "%3"=="skt" (
			SET TEMPLATES_SKIP_TESTS=1
		)
		GOTO :deploy_templates
	) else if "%2"=="cp" (
		if "%3"=="skt" (
			SET CP_SKIP_TESTS=1
		)
		GOTO :deploy_cp
	) else if "%2"=="bv" (
		if "%3"=="skt" (
			SET BRAVO_SKIP_TESTS=1
		)
		GOTO :deploy_bravo
	) else if "%2"=="tnow" (
		if "%3"=="skip_tests" (
			SET TRAVELNOW_SKIP_TESTS=1
		)
		GOTO :deploy_travelnow
	) else if "%2"=="themes" (
		if "%3"=="skip_tests" (
			SET BRAVO_SKIP_TESTS=1
			SET TRAVELNOW_SKIP_TESTS=1
		)
		GOTO :deploy_themes
	)
	)
)

if "%1"=="continue" (
	if "%2"=="temp" (
		GOTO :deploy_templates_continue
	) else if "%2"=="cp" (
		GOTO :deploy_cp_continue
	)
)
		
if "%1"=="kill" GOTO :kill_all

if "%1"=="?" GOTO :help
GOTO :EOF

:help
call :PrintBright Available commands:
call :PrintBright -----------------------------------------------------------------------------
echo do deploy [-s] temp [skt] - Builds all expedia projects and deploys only EAN-TEMPLATES
echo                           - use -s if you want to build only EAN-TEMPLATES
echo                           - use "skt" if you want to skip tests
echo do deploy [-s] cp [skt] - Builds all expedia projects and deploys only EAN-CONTROLPANEL
echo                         - use -s if you want to build only EAN-CONTROLPANEL
echo                         - use "skt" if you want to skip tests
echo.
echo do deploy bv   [skt] - Builds the bravo theme and deploys it; Use "skt" as a second parameter if you want to skip tests
echo do deploy tnow [skt] - Builds the travelnow theme and deploys it; Use "skt" as a second parameter if you want to skip tests
echo do deploy themes     - Builds and deploys bravo and travelnow themes
echo.
echo do start tmp [debug] - Starts apache and tomcat-templates servers; if debug is used as a third parameters Tomcat6 Servers starts in debug mode
echo do start cp  [debug] - Starts apache and tomcat-cp servers; if debug is used as a third parameters Tomcat6 Servers starts in debug mode
echo.
echo do chk all - Check Apache and Tomcat servers to see if they are running
echo do kill    - Kills both servers
echo.
echo do continue temp - Use this command if you have a failed build to continue from your last good build
echo do continue cp   - Use this command if you have a failed build to continue from your last good build
echo.
echo do ? - Shows this help menu
call :PrintBright -----------------------------------------------------------------------------
call :PrintBright Beware the errors are not handled yet 
call :PrintBright Version 2.0 © v-aiacob and v-cdaraban
GOTO :EOF

:check_all
SET CHECK_ALL=1

:check_apache
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    call :PrintBright [DO] Apache Server is running...
) else (
    call :PrintBright [DO] Apache Server is not running...
)
if not "%CHECK_ALL%"=="1" GOTO :EOF

:check_tomcat
tasklist /FI "IMAGENAME eq java.exe" 2>NUL | find /I /N "java.exe">NUL
if "%ERRORLEVEL%"=="0" (
    call :PrintBright [DO] Tomcat 6 Server is running...
) else (
    call :PrintBright [DO] Tomcat 6 Server is not running...
)
GOTO :EOF

:start_all_no_debug_tmp
cd /D C:\tomcat-templates\bin\
start /b "Tomcat Templates Server No Debug" startup.bat || GOTO :error_start_all_no_debug_tomcat
start /b "Apache Server" c:\Apache24\bin\httpd.exe || GOTO :error_start_all_no_debug_apache
POPD
GOTO :EOF

:start_all_debug_tmp
cd /D C:\tomcat-templates\bin\
start /b "Tomcat Templates Server Debug" startup_debug.bat 
start /b "Apache Server" c:\Apache24\bin\httpd.exe 
POPD
GOTO :EOF

:start_all_no_debug_cp
cd /D C:\tomcat-cp\bin\
start /b "Tomcat Templates Server No Debug" startup.bat || GOTO :error_start_all_no_debug_tomcat
start /b "Apache Server" c:\Apache24\bin\httpd.exe || GOTO :error_start_all_no_debug_apache
POPD
GOTO :EOF

:start_all_debug_cp
cd /D C:\tomcat-cp\bin\
start /b "Tomcat Templates Server Debug" startup_debug.bat
start /b "Apache Server" c:\Apache24\bin\httpd.exe
POPD
GOTO :EOF

:kill_all
:: Kill Apache Server
call taskkill.exe /F /IM httpd.exe /T || GOTO :error_kill_all_apache
:: Kill Tomcat 6 Server
call taskkill.exe /F /IM java.exe /T || GOTO :error_kill_all_tomcat
GOTO :EOF


:deploy_themes
SET DEPLOY_ALL=1
:deploy_bravo
:: Delete existing jars and materialized
if exist %MATERIALIZED% (
call :PrintBright [DO] Deleting materialized...
rmdir /Q /S %MATERIALIZED% || GOTO :error_deleting_materialized
)
cd /D %BRAVO_TARGET%

:: Build files
call :PrintBright [DO] Building bravo theme...
cd /D %BRAVO_PROJECT%
if "%BRAVO_SKIP_TESTS%"=="1" (
	call :PrintBright [DO] Skipping tests... 
	call mvn clean package -Dmaven.test.skip=true -Dcheckstyle.skip=true || GOTO :error_build_bravo_skip
) else (
	call mvn clean package || GOTO :error_build_bravo
)
cd target
:: Rename the jar file
call :PrintBright [DO] Renaming bravo jar file...
ren ean-theme-bravo-*.jar bravo.jar || GOTO :error_deploy_bravo_rename
:: Move files to server
call :PrintBright [DO] Moving bravo jar file...
MOVE /Y "%BRAVO_TARGET%"\bravo.jar "%THEMES_SERVER%"\bravo.jar || GOTO :error_deploy_bravo_move

call :PrintBright [DO] Bravo jar has been deployed...
POPD
if not "%DEPLOY_ALL%"=="1" GOTO :EOF

:deploy_travelnow
:: Delete existing jars and materialized
if exist %MATERIALIZED% (
call :PrintBright [DO] Deleting materialized...
rmdir /Q /S %MATERIALIZED% || GOTO :error_deleting_materialized
)
cd /D %TRAVELNOW_TARGET%

:: Build files
call :PrintBright [DO] Building travelnow theme...
cd /D %TRAVELNOW_PROJECT%
if "%TRAVELNOW_SKIP_TESTS%"=="1" (
	call mvn clean package -Dmaven.test.skip=true -Dcheckstyle.skip=true || GOTO :error_build_travelnow_skip
) else (
	call mvn clean package || GOTO :error_build_travelnow
)
cd target
:: Rename the jar file
call :PrintBright [DO] Renaming travelnow jar file...
ren ean-theme-travelnow-*.jar travelnow.jar || GOTO :error_deploy_travelnow_rename
:: Move files to server
call :PrintBright [DO] Moving travelnow jar file...
MOVE /Y %TRAVELNOW_TARGET%\travelnow.jar %THEMES_SERVER%\travelnow.jar || GOTO :error_deploy_travelnow_move

call :PrintBright [DO] Travelnow jar has been deployed...
POPD
GOTO :EOF

:deploy_templates
:: Build files
call :PrintBright [DO] Building templates...
cd /D %CHAMDEV_PROJECT%
if "%BUILD_SOLO%"=="1" (
	cd /D ean-templates
)

if "%TEMPLATES_SKIP_TESTS%"=="1" (
	call :PrintBright [DO] Skipping tests... 
	call mvn install -Dmaven.test.skip=true -Dcheckstyle.skip=true || GOTO :error_build_all_skip
) else (
	call mvn clean install -Dcheckstyle.skip=true || GOTO :error_build_all
)
cd /D %TEMPLATES_TARGET%

:: Rename the war file
call :PrintBright [DO] Renaming templates war file...
ren ean-templates.war templates.war || GOTO :error_deploy_template_rename

:: Delete templates deploy
if exist "%TEMPLATES_SERVER%\templates" (
	call :PrintBright [DO] Deleting templates dir from server...
	rmdir /Q /S %TEMPLATES_SERVER%\templates || GOTO :error_deleting_templates_dir_from_server
)

:: Move files to server
call :PrintBright [DO] Moving templates war file...
MOVE /Y %TEMPLATES_TARGET%\templates.war %TEMPLATES_SERVER%\templates.war || GOTO :error_deploy_template_move
POPD
GOTO :EOF

:deploy_cp
:: Build files
call :PrintBright [DO] Building control panel...
cd /D %CHAMDEV_PROJECT%
if "%BUILD_SOLO%"=="1" (
	cd /D ean-controlpanel
)

if "%CP_SKIP_TESTS%"=="1" (
	call :PrintBright [DO] Skipping tests... 
	call mvn install -Dmaven.test.skip=true -Dcheckstyle.skip=true || GOTO :error_build_all_skip
) else (
	call mvn clean install -Dcheckstyle.skip=true || GOTO :error_build_all
)
cd /D %CP_TARGET%

:: Rename the war file
call :PrintBright [DO] Renaming  control panel war file...
ren ean-controlpanel-*.war cp.war || GOTO :error_deploy_cp_rename

:: Delete cp deploy
if exist "%CP_SERVER%\cp" (
	call :PrintBright [DO] Deleting cp dir from server...
	rmdir /Q /S %CP_SERVER%\cp || GOTO :error_deleting_cp_dir_from_server
)

:: Move files to server
call :PrintBright [DO] Moving control panel war file...
MOVE /Y %CP_TARGET%\cp.war %CP_SERVER%\cp.war || GOTO :error_deploy_cp_move

call :PrintBright [DO] CP war has been deployed...
POPD
GOTO :EOF

:deploy_templates_continue
cd /D %CHAMDEV_PROJECT%
call mvn clean install -rf :ean-templates
GOTO :EOF

:deploy_cp_continue
cd /D %CHAMDEV_PROJECT%
call mvn clean install -rf :ean-controlpanel
GOTO :EOF

:error_start_all_no_debug_tomcat
call :PrintBright [DO] Tomcat6 Server could not be started. 
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_start_all_no_debug_apache
call :PrintBright [DO] Apache Server could not be started. 
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_kill_all_apache
call :PrintBright [DO] Apache Server could not be killed. 
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_kill_all_tomcat
call :PrintBright [DO] Apache Server could not be killed. 
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_bravo_rename
call :PrintBright [DO] Error renaming the bravo theme
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deleting_materialized
call :PrintBright [DO] Error deleting materialized
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deleting_templates_dir_from_server
call :PrintBright [DO] Error deleting templates dir from server
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deleting_cp_dir_from_server
call :PrintBright [DO] Error deleting cp dir from server
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_bravo_move
call :PrintBright [DO] Error moving the bravo theme
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_bravo_skip
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_bravo
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_travelnow_rename
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_travelnow_move
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_travelnow
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_travelnow_skip
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_template_rename
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_template_move
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_cp_rename
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_deploy_cp_move
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_all
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:error_build_all_skip
call :PrintBright
call :PrintBright [DO] Aborting the process...
GOTO :EOF

:PrintBright
powershell -Command Write-Host "%*" -foreground "Red"

ENDLOCAL