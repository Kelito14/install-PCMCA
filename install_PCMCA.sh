#!/bin/bash
# Estilos y Colores de letras
export NADA='\033[00m'
export ROJO='\033[01;31m'
export VERDE='\033[01;32m'
export AMARILLO='\033[01;33m'
export AZUL='\033[00;34m'
export CYAN='\033[00;36m'
export PURPURA='\033[00;35m'

## Verifica que el user que ejecute el script tenga permisos de administrador
ID_USER=`id -u`
if [  $ID_USER != "0" ] ; then
echo "El usuario no es root. Se abortará la ejecucion del script."
sleep 2
exit 0
fi

echo "${AMARILLO}*${NADA}${ROJO}  Instalador de la plataforma v2.6${NADA}"

## Devuelve la ruta actual donde esta el instalador
export ROOTDIR="$(pwd)"

LOGFILE="${ROOTDIR}/platform.log"

## Colocamos el entorno de instalacion en la carpeta de instalacion
cd ${ROOTDIR} >> ${LOGFILE}

echo "${ROJO}(:*** Asegurese de tener instalado y correctamente configurados los siguientes paquetes antes de continuar: ***:)"
echo "${PURPURA}--> augeas-lenses augeas-tools php5-curl php5-gd php5-intl postgresql pgadmin3 apache2 php5 php-soap php5-cgi php5-dev php5-cli php5-pgsql libapache2-mod-php5 php5-mysql mysql-server phpmyadmin mongodb <---${AZUL}"
read -p "Presione Enter para continuar..." X

## Descripimimos el codigo de fuente (Descomentar esta linea cuando se termine completo)
echo "${ROJO}*${AZUL} Descripimiendo el codigo de fuente...${NADA}"
#tar xzvf PCMCA.tar.gz >> ${LOGFILE}
#rm ${LOGFILE}

 ##Obtenemos la direccion IP de la maquina
#export IP_ADDRESS=`ip addr show dev eth0 | grep "inet " | awk '{ print $2 }' | cut -f1 -d'/'`

echo "${NADA}* Configurando el entorno para la plataforma."

## Realizando una configuracion en el servidor de aplicaciones
#* Configurando servidor de aplicaciones.
augtool <<-EOF
set /files/etc/php5/apache2/php.ini/PHP/display_errors  On
set /files/etc/php5/apache2/php.ini/PHP/default_socket_timeout  6000
save
EOF

echo "${AMARILLO}*${VERDE} Configurando las conexiones a las Bases de Datos"

echo "${ROJO}*${AZUL} Configurando la conexion de Postgresql${CYAN}"
read -p "Usuario de Postgresql: " pgsql_user
read -p "Password de Postgresql: " pgsql_pass
#stty echo
#read pgsql_pass
#stty echo
#echo ""  # force a carriage return to be output
read -p "Puerto de Postgresql: " pgsql_port

echo "${ROJO}*${AZUL} Configurando la conexion de MySQL${CYAN}"
read -p "Usuario de MySQL: " mysql_user
read -p "Password de MySQL: " mysql_pass
#read -p "Puerto de MySQL: " mysql_port

VARWWW="/var/www"
DIRSECURITY="pcmca/systems/security_backend/"
DIRCERTHW="pcmca/systems/certification_backend/"
DIRDIRSW="pcmca/systems/directory_backend/"
DIRGITI="pcmca/systems/giti_backend/"
DIRMIG="pcmca/systems/migration_backend/"
DIRPCS="pcmca/systems/pcs_backend/"
DIRSURVEY="pcmca/systems/survey_backend/"
DIRUI="pcmca/pcmcaUI/configs/"
DIRUIB_M="pcmca/pcmcaUI/modulos/"
DIRUIB="pcmca/pcmcaUI/"

echo "${ROJO}*${NADA} Preparando enlaces a los WSDL."
cat > ${DIRUI}wsdl.php <<EOF
<?php
\$listaWsdls['ssnpm'] = 'http://localhost/pcmca/systems/security_backend/web/ssnpmWS.wsdl';
\$listaWsdls['directoriosw'] = 'http://localhost/pcmca/systems/directory_backend/web/directorioWS.php?wsdl';
\$listaWsdls['cert_hw'] = 'http://localhost/pcmca/systems/certification_backend/web/cert_hwWS.wsdl';
\$listaWsdls['giti'] = 'http://localhost/pcmca/systems/giti_backend/web/gitiWS.wsdl';
\$listaWsdls['pcs'] = 'http://localhost/pcmca/systems/pcs_backend/web/pcsWS.wsdl';
\$listaWsdls['survey'] = 'http://localhost/pcmca/systems/survey_backend/web/surveyWS.wsdl';
?>
EOF
chmod 777 -R ${DIRUI} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Sistema de Seguridad."
##Configurar DATABASES
cat > ${DIRSECURITY}config/databases.yml <<EOF
all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_security
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRSECURITY}/install.sh <<EOF
#/bin/bash
php symfony doctrine:drop-db --no-confirmation
php symfony doctrine:create-db
php symfony doctrine:build-model
pg_restore -i -h localhost -p ${pgsql_port} -U ${pgsql_user} -d pcmca_security -v "data/backup/last/backup.backup"
php symfony webservice:generate-wsdl ssnpm ssnpmWS http://localhost/pcmca/systems/security_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*
EOF
chmod 777 -R ${DIRSECURITY} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Subsistema Directorio de Software"
##Configurar DATABASES
cat > ${DIRDIRSW}config/databases.yml <<EOF
all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_directory
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRDIRSW}/install.sh <<EOF
#/bin/bash
php symfony doctrine:drop-db --no-confirmation
php symfony doctrine:create-db
php symfony doctrine:build-model
pg_restore -i -h localhost -p ${pgsql_port} -U ${pgsql_user} -d pcmca_directory -v "data/backup/last/backup.backup"
php symfony webservice:generate-wsdl directory directorioWS http://localhost/pcmca/systems/directory_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*
EOF

##Configurar archivo config.php
cat > ${DIRUIB_M}dirSW/configs/config.php <<EOF
<?php
\$moduleConfiguration = array(
    'rutaImagenesDirSW' => 'http://localhost/pcmca/systems/directory_backend/web/uploads/',
    'rutaImagenesDirSWStatic' => RUTA_BASE . '/../systems/directory_backend/web/uploads/',
    'moduleNamespace' => array(
         'library' => RUTA_BASE . 'modulos/giti/lib/',  
        'fpdf' => RUTA_BASE . 'lib',
        'tcpdf' => RUTA_BASE . 'lib',
        'tcpdf_base' => RUTA_BASE . 'lib/tcpdf',
        'tcpdf_inc' => RUTA_BASE . 'lib/tcpdf/include',
    )
);
?>
EOF
chmod 777 -R ${DIRDIRSW} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Subsistema Certificación de Hardware"
##Configurar DATABASES
cat > ${DIRCERTHW}config/databases.yml <<EOF
all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_certification
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRCERTHW}/install.sh <<EOF
#/bin/bash
php symfony doctrine:drop-db --no-confirmation
php symfony doctrine:create-db
php symfony doctrine:build-model
pg_restore -i -h localhost -p ${pgsql_port} -U ${pgsql_user} -d pcmca_certification -v "data/backup/last/backup.backup"
php symfony webservice:generate-wsdl certification cert_hwWS http://localhost/pcmca/systems/certification_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*
EOF

##Configurar archivo Config de Certiicacion de Hardware
cat > ${DIRUIB_M}cert_hw/configs/config.php  <<EOF
<?php
include_once RUTA_BASE . 'modulos/cert_hw/lib/helper/DebugHelper.php';

\$moduleConfiguration = array(
    'moduleNamespace' => array(
        'modelWS' => RUTA_BASE . 'modulos/cert_hw/lib',
        'model' => RUTA_BASE . 'modulos/cert_hw/lib',
        'tcpdf' => RUTA_BASE . 'lib',
        'tcpdf_base' => RUTA_BASE . 'lib/tcpdf',
        'tcpdf_inc' => RUTA_BASE . 'lib/tcpdf/include'
    ),
    'rutaImagenesCertHW' => 'http://localhost/pcmca/systems/certification_backend/web/',
    'url_domain' => 'http://localhost/pcmca/systems/certification_backend/web/',
    'show_certification_images' => false,
    'web_uploads' => 'http://localhost/pcmca/systems/certification_backend/web/',
    'soap_options' => array(
        # for debug
//        'cache_wsdl' => WSDL_CACHE_NONE,
        # mapeo de clases
        'classmap' => array(
            'ArchMeta' => 'modelWS\\ArchMeta',
            'Category' => 'modelWS\\Category',
            'CategoryMeta' => 'modelWS\\CategoryMeta',
            'Certification' => 'modelWS\\Certification',
            'CertificationMeta' => 'modelWS\\CertificationMeta',
            'Comment' => 'modelWS\\Comment',
            'CommentMeta' => 'modelWS\\CommentMeta',
            'CertificationCategory' => 'modelWS\\CertificationCategory',
            'CertificationCategoryMeta' => 'modelWS\\CertificationCategoryMeta',
            'Compatibility' => 'modelWS\\Compatibility',
            'CompatibilityMeta' => 'modelWS\\CompatibilityMeta',
            'CompatibilityOS' => 'modelWS\\CompatibilityOS',
            'Distribution' => 'modelWS\\Distribution',
            'DistributionMeta' => 'modelWS\\DistributionMeta',
            'Driver' => 'modelWS\\Driver',
            'DriverMeta' => 'modelWS\\DriverMeta',
            'Especification' => 'modelWS\\Especification',
            'EspecificationMeta' => 'modelWS\\EspecificationMeta',
            'EspecificationTemplate' => 'modelWS\\EspecificationTemplate',
            'EspecificationTemplateMeta' => 'modelWS\\EspecificationTemplateMeta',
            'Hardware' => 'modelWS\\Hardware',
            'HardwareDriverOS' => 'modelWS\\HardwareDriverOS',
            'HardwareMeta' => 'modelWS\\HardwareMeta',
            'HardwarePartial' => 'modelWS\\HardwarePartial',
            'HardwarePartialMeta' => 'modelWS\\HardwarePartialMeta',
            'HostSecurityConfig' => 'modelWS\\HostSecurityConfig',
            'HostSecurityConfigMeta' => 'modelWS\\HostSecurityConfigMeta',
            'HardwareReport' => 'modelWS\\HardwareReport',
            'Item' => 'modelWS\\Item',
            'ItemMeta' => 'modelWS\\ItemMeta',
            'Manufacturer' => 'modelWS\\Manufacturer',
            'ManufacturerMeta' => 'modelWS\\ManufacturerMeta',
            'Notification' => 'modelWS\\Notification',
            'NotificationMeta' => 'modelWS\\NotificationMeta',
            'OperativeSystem' => 'modelWS\\OperativeSystem',
            'OperativeSystemMeta' => 'modelWS\\OperativeSystemMeta',
            'WhiteListItem' => 'modelWS\\WhiteListItem',
            'WhiteListMeta' => 'modelWS\\WhiteListMeta'
        ))
);
?>
EOF
chmod 777 -R ${DIRCERTHW} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Subsistema de Inventario"
##Configurar DATABASES
cat > ${DIRGITI}config/databases.yml <<EOF
all:
  giti:
    class: sfDoctrineDatabase
    param:
      dsn: 'pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_giti'
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
  ocs:
    class: sfDoctrineDatabase
    param:
      dsn: 'mysql:host=localhost;dbname=ocsweb'
      username: ${mysql_user}
      password: ${mysql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRGITI}/install.sh <<EOF
#/bin/bash
#Realizar las operaciones para instalar la base de datos de giti solamente
#Y solo generar las clases modelo de la conexion giti, o sea, la clase Tsource
#rm config/doctrine/schema.yml
#cd config/doctrine/
#tar -xvzpf schema-giti.yml.tar.gz
#cd ../../

php symfony doctrine:drop-db giti --no-confirmation
php symfony doctrine:build-db giti
php symfony doctrine:build-model
php symfony doctrine:build-sql

#rm config/doctrine/schema.yml
#cd config/doctrine/
#tar -xvzpf schema-latest.yml.tar.gz
#cd ../../lib/model/doctrine/
#tar -xvzpf models.tar.gz 
#cd ../../../

pg_restore -i -h localhost -p ${pgsql_port} -U ${pgsql_user} -d pcmca_giti -v "data/backup/last/backup.backup"
php symfony --name=ocs configure:database "mysql:host=localhost;dbname=ocsweb" ${mysql_user} ${mysql_pass}
php symfony doctrine:build-model
mysql -u ${mysql_user} -p${mysql_pass} -h localhost ocsweb < data/backup/ocsweb.sql
php symfony webservice:generate-wsdl giti gitiWS http://localhost/pcmca/systems/giti_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*
EOF
chmod 777 -R ${DIRGITI} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Subsistema de Planificación Control y Seguimiento"
##Configurar DATABASES
cat > ${DIRPCS}config/databases.yml <<EOF
all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_pcs
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRPCS}/install.sh <<EOF
#/bin/bash
php symfony doctrine:drop-db --no-confirmation
php symfony doctrine:create-db
php symfony doctrine:create-model-tables --application="pcs"
php symfony doctrine:build-model
pg_restore -i -h localhost -p ${pgsql_port} -U ${pgsql_user} -d pcmca_pcs -v "data/backup/schema.backup"
php symfony webservice:generate-wsdl pcs pcsWS http://localhost/pcmca/systems/pcs_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*
EOF
chmod 777 -R ${DIRPCS} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
echo "${ROJO}*${NADA} Preparando el Subsistema Survey"
##Configurar DATABASES
cat > ${DIRSURVEY}config/databases.yml <<EOF
all:
  survey_mysql:
    class: sfDoctrineDatabase
    param:
      dsn: 'mysql:host=localhost;dbname=pcmca_survey'
      username: ${mysql_user}
      password: ${mysql_pass}
  survey_postgres:
    class: sfDoctrineDatabase
    param:
      dsn: 'pgsql:host=localhost;port=${pgsql_port};dbname=pcmca_survey'
      username: ${pgsql_user}
      password: ${pgsql_pass}
      persistent: true
EOF

##Configurar install.sh
cat > ${DIRSURVEY}/install.sh <<EOF
#/bin/bash
php symfony doctrine:drop-db survey_postgres --no-confirmation
php symfony doctrine:build-db survey_postgres
php symfony doctrine:build-model
php symfony doctrine:build-sql

#Realizar las operaciones para obtener los modelos asociados al esquema o base de datos Survey
php symfony doctrine:drop-db survey_mysql --no-confirmation
php symfony --name=survey_mysql configure:database "mysql:host=localhost;dbname=pcmca_survey" ${mysql_user} ${mysql_pass}
php symfony doctrine:build-db survey_mysql
php symfony doctrine:build-model
mysql -u ${mysql_user} -p${mysql_pass} -h localhost pcmca_survey < data/backup/limesurvey.sql
php symfony webservice:generate-wsdl survey surveyWS http://localhost/pcmca/systems/survey_backend/web/
php symfony cc
rm -rf cache/*
rm -rf log/*

#esto es necesario porque el chema tiene atributos en
#los modelos de survey que son palabras reservadas de
#mysql
# attribute en LimeQuestionAttributes (en el chema se puso attributo)
# use en LimeTemplatesRights (en el chema se puso uso)
cp models/BaseLimeQuestionAttributes.class.php lib/model/doctrine/base/
cp models/BaseLimeTemplatesRights.class.php lib/model/doctrine/base/
EOF
chmod 777 -R ${DIRSURVEY} >> ${LOGFILE}

#-------------------------------------------------------------------------------#
chmod 777 -R ${DIRUIB} >> ${LOGFILE}
rm -rf ${DIRUIB}cache/*
rm -rf ${DIRUIB}log/*
rm -rf ${DIRUIB_M}apm/cache/*
#-------------------------------------------------------------------------------#

echo "${AMARILLO}*${VERDE} Copiando sistema base. ${AZUL}"
read -p "Ruta de la PCMCA: " PCMCA_DIR
if [ ! -d ${PCMCA_DIR} ]; then 
	mkdir -p ${PCMCA_DIR}
fi

#rm -rf /var/www/pcmca
echo $ROOTDIR
echo $VARWWW
if [ "${ROOTDIR}" != "${VARWWW}" ]; then
cp -R pcmca/* ${PCMCA_DIR} >> ${LOGFILE}
fi
chmod 777 -R ${PCMCA_DIR}
chmod 777 -R /var/www >> ${LOGFILE}
#sudo ln -s ${PCMCA_DIR} /var/www/pcmca >> ${LOGFILE}
chmod 777 -R /var/www >> ${LOGFILE}
#rm -rf PCMCA


#Creando el VirtualHost
echo "${AMARILLO}*${VERDE} Crando el VirtualHost."
export NAME_HOST="pcmca"
export PATH_PCMCA="/etc/apache2/sites-available/${NAME_HOST}"
read -p "Inserte el ServerName para el VirtualHost: " SERVER_NAME
cat > ${PATH_PCMCA} <<EOF
<VirtualHost *:80>
   DocumentRoot "${PCMCA_DIR}/pcmcaUI/web"
   DirectoryIndex index.php
   ServerName ${SERVER_NAME}
   <Directory "${PCMCA_DIR}/pcmcaUI/web">
      AllowOverride All
      Allow from All
   </Directory>
   ErrorLog ${APACHE_LOG_DIR}/error.log
   CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

##Activando el nombre en el archivo hosts
echo "127.0.1.1 ${SERVER_NAME}" >> /etc/hosts

##Activando el Virtual Host
echo "${AMARILLO}*${VERDE} Activando el Virtual Host"
cd /etc/apache2/sites-available >> ${LOGFILE}
a2ensite ${NAME_HOST} >> ${LOGFILE}
a2enmod rewrite >> ${LOGFILE}

echo "${AMARILLO}*${VERDE} Reiniciando apache2"
sudo /etc/init.d/apache2 restart >> ${LOGFILE}


echo "${ROJO}*${NADA} Instalando el Sistema de Seguridad."
cd ${PCMCA_DIR}/systems/security_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

echo "${ROJO}*${NADA} Instalando el Directorio de Aplicaciones."
cd ${PCMCA_DIR}/systems/directory_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

echo "${ROJO}*${NADA} Instalando el subsistema de Certificación de Hardware."
cd ${PCMCA_DIR}/systems/certification_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

echo "${ROJO}*${NADA} Instalando el subsistema de Inventario."
cd ${PCMCA_DIR}/systems/giti_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

echo "${ROJO}*${NADA} Instalando el subsistema de Planificación Control y Seguimiento."
cd ${PCMCA_DIR}/systems/pcs_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

echo "${ROJO}*${NADA} Instalando el subsistema Survey."
cd ${PCMCA_DIR}/systems/survey_backend/ >> ${LOGFILE}
sh install.sh >> ${LOGFILE}

chmod 777 ${LOGFILE}

echo "${AZUL} Si la Plataforma ya fue instalada con anterioridad verifique el archivo ${ROJO} /etc/hosts ${AZUL}"
echo "borre el nombre del ServerName en caso de que este se repita"
echo "${VERDE} La plataforma de ha instalado correctamente${NADA}"
echo "${ROJO} Acceder en: ${AZUL} http://localhost/pcmca/pcmcaUI/web/  o  http://${SERVER_NAME}"
echo "${NADA}"
sleep 2

exit 0
