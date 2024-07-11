@echo off
SET CURRENT_DIRECTORY=%CD%

REM Set the accelerator home
SET WSO2_OB_ACCELERATOR_HOME=%~dp0
cd "%WSO2_OB_ACCELERATOR_HOME%..\"
SET WSO2_OB_ACCELERATOR_HOME=%CD%
echo [INFO] Accelerator Home : %WSO2_OB_ACCELERATOR_HOME%

REM Set the base product home
cd "%WSO2_OB_ACCELERATOR_HOME%\..\"
SET WSO2_BASE_PRODUCT_HOME=%CD%
echo [INFO] Base Product Home : %WSO2_BASE_PRODUCT_HOME%

REM Validate product home
if not exist "%WSO2_BASE_PRODUCT_HOME%\repository\components" (
	  echo [ERROR] '%WSO2_BASE_PRODUCT_HOME%' is NOT a valid carbon home!
	  cd "%CURRENT_DIRECTORY%"
	  EXIT /B 1
	  
	) else (
	  echo [INFO] '%WSO2_BASE_PRODUCT_HOME%' is a valid carbon home!
	)

echo [INFO] Removing old open banking artifacts from base product...
DEL "%WSO2_BASE_PRODUCT_HOME%\repository\components\dropins\com.wso2.openbanking.*"
DEL "%WSO2_BASE_PRODUCT_HOME%\repository\components\lib\com.wso2.openbanking.*"

echo [INFO] Copying open banking artifacts...
XCOPY "%WSO2_OB_ACCELERATOR_HOME%\carbon-home" "%WSO2_BASE_PRODUCT_HOME%\" /E /F /Y /S

cd "%CURRENT_DIRECTORY%"
echo [SUCCESS] Complete!

