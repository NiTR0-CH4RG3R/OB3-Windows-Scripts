 # Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
 #
 # WSO2 LLC. licenses this file to you under the Apache License,
 # Version 2.0 (the "License"); you may not use this file except
 # in compliance with the License.
 # You may obtain a copy of the License at
 #
 #    http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing,
 # software distributed under the License is distributed on an
 # "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 # KIND, either express or implied. See the License for the
 # specific language governing permissions and limitations
 # under the License.

# How to execute :
#   If your accelerator is located inside of the base product you can just call .\configure.ps1
#   If your accelerator is in a different location you can call .\configure.ps1 <YOUR_BASE_PRODUCT_HOME_DIR>

# Get the current working directory of the powershell session, so we can set to this directory after the script finishes.
$CURRENT_DIRECTORY = (Get-Location).path

# Some black magic to get the fully qualified path of the WSO2 Base Product if it was given as an argument.
$WSO2_BASE_PRODUCT_HOME = $args[0]
if (-NOT($null -eq $WSO2_BASE_PRODUCT_HOME)) {
    if (Test-Path $WSO2_BASE_PRODUCT_HOME) {
        Set-Location $WSO2_BASE_PRODUCT_HOME
        $WSO2_BASE_PRODUCT_HOME = (Get-Location).path
        Set-Location $CURRENT_DIRECTORY
    }
}

Function Exit-Clean {
    Set-Location $CURRENT_DIRECTORY
    exit 1
}

# Get the root directory location of the accelerator. Which is <BASE_PRODUCT>/<ACCELERATOR>/
Set-Location (Join-Path $PSScriptRoot ".\..\")
$WSO2_OB_ACCELERATOR_HOME = (Get-Location).path
Write-Output "[INFO] Accelerator Home : $WSO2_OB_ACCELERATOR_HOME"

# Get the root directory of the base product.
if ($null -eq $WSO2_BASE_PRODUCT_HOME) {
    Set-Location (Join-Path $WSO2_OB_ACCELERATOR_HOME ".\..\")
    $WSO2_BASE_PRODUCT_HOME = (Get-Location).path
}
Write-Output "[INFO] Base Product Home : $WSO2_BASE_PRODUCT_HOME"

# Check whether the extracted base product location contains a valid WSO2 carbon product by checking whether this location
# contains the "repository/components" directory.
if (-NOT(Test-Path (Join-Path $WSO2_BASE_PRODUCT_HOME "repository\components"))) {
    Write-Output "[ERROR] $WSO2_BASE_PRODUCT_HOME does NOT contain a valid carbon product!"
    # The current path does not contain a valid carbon product.
    # Set the current working directory to the original location and exit.
    Exit-Clean
} else {
    Write-Output "[INFO] $WSO2_BASE_PRODUCT_HOME is a valid carbon product home."
}

# Get the location of the configure.properties
$CONFIG_PROPERTIES_PATH = Join-Path $WSO2_OB_ACCELERATOR_HOME "repository\conf\configure.properties"
Write-Output "[INFO] configure.properties location : $CONFIG_PROPERTIES_PATH"

# Load the variables in the configure.properties file
$PROPERTIES = ConvertFrom-StringData (Get-Content $CONFIG_PROPERTIES_PATH -raw)

$SELECTED_DEPLOYMENT_TOML_FILE = Join-Path $WSO2_OB_ACCELERATOR_HOME $PROPERTIES.'PRODUCT_CONF_PATH'
Write-Output "[INFO] Selected deployment.toml location : $SELECTED_DEPLOYMENT_TOML_FILE"

$DEPLOYMENT_TOML_FILE = Join-Path $WSO2_OB_ACCELERATOR_HOME "repository\resources\deployment.toml"
# Temporary copy the selected toml file so we can make changes to it.
Copy-Item -Path $SELECTED_DEPLOYMENT_TOML_FILE $DEPLOYMENT_TOML_FILE
Write-Output "[INFO] Temporary deployment.toml location : $DEPLOYMENT_TOML_FILE"

# A function to replace the database related variables in the temp deployment.toml with their actual values from configure.properties 
Function Set-Datasources
{
    if ($PROPERTIES.'DB_TYPE' -eq "mysql")
    {
        # MySQL
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_APIMGT_URL", "jdbc:mysql://$( $PROPERTIES.'DB_HOST' ):3306/$( $PROPERTIES.'DB_APIMGT' )?allowPublicKeyRetrieval=true&amp;autoReconnect=true&amp;useSSL=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_IS_CONFIG_URL", "jdbc:mysql://$( $PROPERTIES.'DB_HOST' ):3306/$( $PROPERTIES.'DB_IS_CONFIG' )?allowPublicKeyRetrieval=true&amp;autoReconnect=true&amp;useSSL=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_GOV_URL", "jdbc:mysql://$( $PROPERTIES.'DB_HOST' ):3306/$( $PROPERTIES.'DB_GOV' )?allowPublicKeyRetrieval=true&amp;autoReconnect=true&amp;useSSL=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_USER_STORE_URL", "jdbc:mysql://$( $PROPERTIES.'DB_HOST' ):3306/$( $PROPERTIES.'DB_USER_STORE' )?allowPublicKeyRetrieval=true&amp;autoReconnect=true&amp;useSSL=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_OB_STORE_URL", "jdbc:mysql://$( $PROPERTIES.'DB_HOST' ):3306/$( $PROPERTIES.'DB_OPEN_BANKING_STORE' )?allowPublicKeyRetrieval=true&amp;autoReconnect=true&amp;useSSL=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_USER", "$( $PROPERTIES.'DB_USER' )" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_PASS", "$( $PROPERTIES.'DB_PASS' )" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_DRIVER", "$( $PROPERTIES.'DB_DRIVER' )" })
    }
    elseif($PROPERTIES.'DB_TYPE' -eq "mssql")
    {
        # Microsoft SQL Server
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_APIMGT_URL", "jdbc:sqlserver://$( $PROPERTIES.'DB_HOST' ):1433;databaseName=$( $PROPERTIES.'DB_APIMGT' );encrypt=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_IS_CONFIG_URL", "jdbc:sqlserver://$( $PROPERTIES.'DB_HOST' ):1433;databaseName=$( $PROPERTIES.'DB_IS_CONFIG' );encrypt=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_GOV_URL", "jdbc:sqlserver://$( $PROPERTIES.'DB_HOST' ):1433;databaseName=$( $PROPERTIES.'DB_GOV' );encrypt=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_USER_STORE_URL", "jdbc:sqlserver://$( $PROPERTIES.'DB_HOST' ):1433;databaseName=$( $PROPERTIES.'DB_USER_STORE' );encrypt=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_OB_STORE_URL", "jdbc:sqlserver://$( $PROPERTIES.'DB_HOST' ):1433;databaseName=$( $PROPERTIES.'DB_OPEN_BANKING_STORE' );encrypt=false" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_USER", "$( $PROPERTIES.'DB_USER' )" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_PASS", "$( $PROPERTIES.'DB_PASS' )" })
        Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (Get-Content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "DB_DRIVER", "$( $PROPERTIES.'DB_DRIVER' )" })
    }
    else {
        Write-Output "[ERROR] Unsupported Database Type!"
        Exit-Clean
    }
}

# A function to replace the hostname related variables in the temp deployment.toml with their actual values from configure.properties 
Function Set-Hostnames {
    Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (get-content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "APIM_HOSTNAME", "$( $PROPERTIES.'APIM_HOSTNAME' )" })
    Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (get-content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "IS_HOSTNAME", "$( $PROPERTIES.'IS_HOSTNAME' )" })
    Set-Content -Path $DEPLOYMENT_TOML_FILE -Value (get-content $DEPLOYMENT_TOML_FILE | ForEach-Object{ $_ -replace "BI_HOSTNAME", "$( $PROPERTIES.'BI_HOSTNAME' )" })
}

# A function to create the databases. ONLY SUPPORTED FOR THE MYSQL
Function Add-Databases {
    if ($PROPERTIES.'DB_TYPE' -eq "mysql") {
        $DB_MYSQL_PASS = ""
        if (-NOT($PROPERTIES.'DB_PASS' -eq "")) {
            $DB_MYSQL_PASS = $PROPERTIES.'DB_PASS'
        }

        mysql -u"$( $PROPERTIES.'DB_USER' )" -p"$DB_MYSQL_PASS" -h"$( $PROPERTIES.'DB_HOST' )" -e "DROP DATABASE IF EXISTS $( $PROPERTIES.'DB_IS_CONFIG' ); CREATE DATABASE $( $PROPERTIES.'DB_IS_CONFIG' ) DEFAULT CHARACTER SET latin1;"
        Write-Output "Database Created: $( $PROPERTIES.'DB_IS_CONFIG' )"
        mysql -u"$( $PROPERTIES.'DB_USER' )" -p"$DB_MYSQL_PASS" -h"$( $PROPERTIES.'DB_HOST' )" -e "DROP DATABASE IF EXISTS $( $PROPERTIES.'DB_OPEN_BANKING_STORE' ); CREATE DATABASE $( $PROPERTIES.'DB_OPEN_BANKING_STORE' ) DEFAULT CHARACTER SET latin1;"
        Write-Output "Database Created: $( $PROPERTIES.'DB_OPEN_BANKING_STORE' )"
    }
    else {
        Write-Output "[INFO] The databases must be created manually for non mysql DBMSs."   
    }
}

# A function to create the database tables. ONLY SUPPORTED FOR THE MYSQL
Function Add-DatabaseTables {
    if ($PROPERTIES.'DB_TYPE' -eq "mysql") {
        $DB_MYSQL_PASS = ""
        if (-NOT($PROPERTIES.'DB_PASS' -eq "")) {
            $DB_MYSQL_PASS = $PROPERTIES.'DB_PASS'
        }

        mysql -u"$( $PROPERTIES.'DB_USER' )" -p"$DB_MYSQL_PASS" -D"$( $PROPERTIES.'DB_IS_CONFIG' )" -h"$( $PROPERTIES.'DB_HOST' )" -e "SOURCE $(Join-Path $WSO2_BASE_PRODUCT_HOME "dbscripts\mysql.sql")"
        Write-Output "Database tables Created for: $( $PROPERTIES.'DB_IS_CONFIG' )"
        mysql -u"$( $PROPERTIES.'DB_USER' )" -p"$DB_MYSQL_PASS" -D"$( $PROPERTIES.'DB_OPEN_BANKING_STORE' )" -h"$( $PROPERTIES.'DB_HOST' )" -e "SOURCE $(Join-Path $WSO2_BASE_PRODUCT_HOME "dbscripts\open-banking\consent\mysql.sql")"
        Write-Output "Database tables Created for: $( $PROPERTIES.'DB_OPEN_BANKING_STORE' )"
    }
    else {
        Write-Output "[INFO] The database tables must be created manually for non mysql DBMSs."
    }
}


Write-Output "============================================"
Write-Output "[INFO] Configuring the hostnames..."
Set-Hostnames
Write-Output "[INFO] Hostnames configurations completed!"

Write-Output "============================================"
Write-Output "[INFO] Configuring the datasources..."
Set-Datasources
Write-Output "[INFO] Datasources configurations completed!"

Write-Output "============================================"
Copy-Item $DEPLOYMENT_TOML_FILE (Join-Path $WSO2_BASE_PRODUCT_HOME "repository\conf\deployment.toml")
Write-Output "[INFO] Copied temp toml to the $(Join-Path $WSO2_BASE_PRODUCT_HOME "repository\conf\deployment.toml")"

Remove-Item $DEPLOYMENT_TOML_FILE
Write-Output "[INFO] Deleted temp toml $DEPLOYMENT_TOML_FILE"

Write-Output "============================================"
Add-Databases

Write-Output "============================================"
Add-DatabaseTables

Exit-Clean