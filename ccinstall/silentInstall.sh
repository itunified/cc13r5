#!/bin/bash



# do not etdit below this line
OMS_BASE=/u01/app/oracle/cc
OMS_SHARE=$OMS_BASE/share
BASETIME=$(date +%s%N)
GPG_KEY=ccadmin
SECRETS=$OMS_SHARE/secrets
RSP_VERSION="2.2.1.0.0"
HOST_DOMAIN=$(dnsdomainname)
OMS_HOSTNAME=$(hostname --fqdn)
OMS_MW_HOME=$OMS_BASE/cc13cR5/mw
ORACLE_HOME=$OMS_MW_HOME
ROOT_SH=$OMS_MW_HOME/allroot.sh
OMS_GC_INST=$OMS_BASE/cc13cR5/gc_inst
ORA_INV=/u01/app/oraInventory
AGENT_HOME=$OMS_BASE/agent
SW_HOME=$OMS_SHARE/software
STAGE_LOCATION_PATCHES=$OMS_SHARE/patches
OMSP=$ORACLE_HOME/OMSPatcher/omspatcher
OMSPU=$STAGE_LOCATION_PATCHES/OMSPatcher/latest
RUN_INSTALLER="$SW_HOME/em13500_linux64.bin -J-Djava.io.tmpdir=$OMS_BASE/tmp/"
INSTALLER_LOG=$PWD/logs/$(basename $0).$OMS_HOSTNAME.$BASETIME.log
SW_LIB=$OMS_SHARE/swlib
PORTS_INI=$OMS_SHARE/scripts/ccinstall/etc/portlist.ini
CONFIGURE=$OMS_MW_HOME/sysman/install/ConfigureGC.sh

### password
SYSMAN_SECRET=$(gpg --decrypt --recipient ccadmin $SECRETS/.sysman.gpg 2>/dev/null)
NODEMANAGER_SECRET=$(gpg --decrypt --recipient ccadmin $SECRETS/.nodemanager.gpg 2>/dev/null)
WEBLOGIC_SECRET=$(gpg --decrypt --recipient ccadmin $SECRETS/.weblogic.gpg 2>/dev/null)
AGENT_REGISTRATION_SECRET=$(gpg --decrypt --recipient ccadmin $SECRETS/.agentregistration.gpg 2>/dev/null)
OMRSYSDBA_SECRET=$(gpg --decrypt --recipient ccadmin $SECRETS/.omrsys.gpg 2>/dev/null)

### source
source $PWD/etc/.response




function create_empre_rsp() {
#cat > $myfile | gpg --encrypt --recipient ccadmin <<EOF
echo "RESPONSEFILE_VERSION=$RSP_VERSION
UNIX_GROUP_NAME=oinstall
DATABASE_HOSTNAME=$OMR_HOSTNAME.$HOST_DOMAIN
LISTENER_PORT=$OMR_LISTENER_PORT
SERVICENAME_OR_SID=$OMR_SERVICE_NAME
SYS_PASSWORD=$OMRSYSDBA_SECRET
SYSMAN_PASSWORD=$SYSMAN_SECRET
SYSMAN_CONFIRM_PASSWORD=$SYSMAN_SECRET
b_upgrade=false
EM_INSTALL_TYPE=NOSEED
CONFIGURATION_TYPE=ADVANCED" >> $myfile
#CONFIGURATION_TYPE=ADVANCED" |gpg --encrypt --recipient $GPGKEY >> $myfile
#EOF
}

function edit_response() {
echo "UX_GROUP=oinstall
OMS_DEPLOYMENT_SIZE=SMALL
OMR_HOSTNAME=vmopneufraad109
OMR_SERVICE_NAME=ccdev.sub05221230151.vncdefra.oraclevcn.com
OMR_LISTENER_PORT=1521
OMR_TS_CREATE_DEST=+DATA" > $PWD/.response
vi $PWD/etc/.response
}

function create_install_rsp() {
echo "RESPONSEFILE_VERSION=$RSP_VERSION
UNIX_GROUP_NAME=$UX_GROUP
INVENTORY_LOCATION=$ORA_INV
INSTALL_UPDATES_SELECTION=staged
STAGE_LOCATION=$STAGE_LOCATION_PATCHES
ORACLE_MIDDLEWARE_HOME_LOCATION=$OMS_MW_HOME
ORACLE_HOSTNAME=$OMS_HOSTNAME
AGENT_BASE_DIR=$AGENT_HOME
WLS_ADMIN_SERVER_USERNAME=weblogic
SYS_PASSWORD=$OMRSYSDBA_SECRET
SYSMAN_PASSWORD=$SYSMAN_SECRET
SYSMAN_CONFIRM_PASSWORD=$SYSMAN_SECRET
WLS_ADMIN_SERVER_PASSWORD=$WEBLOGIC_SECRET
WLS_ADMIN_SERVER_CONFIRM_PASSWORD=$WEBLOGIC_SECRET
NODE_MANAGER_PASSWORD=$NODEMANAGER_SECRET
NODE_MANAGER_CONFIRM_PASSWORD=$NODEMANAGER_SECRET
AGENT_REGISTRATION_PASSWORD=$AGENT_REGISTRATION_SECRET
AGENT_REGISTRATION_CONFIRM_PASSWORD=$AGENT_REGISTRATION_SECRET
EMPREREQ_AUTO_CORRECTION=true
CONFIGURE_ORACLE_SOFTWARE_LIBRARY=true
ORACLE_INSTANCE_HOME_LOCATION=$OMS_GC_INST
SOFTWARE_LIBRARY_LOCATION=$SW_LIB
DATABASE_HOSTNAME=$OMR_HOSTNAME
LISTENER_PORT=$OMR_LISTENER_PORT
SERVICENAME_OR_SID=$OMR_SERVICE_NAME
DEPLOYMENT_SIZE=$OMS_DEPLOYMENT_SIZE
MANAGEMENT_TABLESPACE_LOCATION=$OMR_TS_CREATE_DEST
CONFIGURATION_DATA_TABLESPACE_LOCATION=$OMR_TS_CREATE_DEST
JVM_DIAGNOSTICS_TABLESPACE_LOCATION=$OMR_TS_CREATE_DEST
STATIC_PORTS_FILE=$PORTS_INI
PLUGIN_SELECTION={}
b_upgrade=false
EM_INSTALL_TYPE=NOSEED
CONFIGURATION_TYPE=ADVANCED" >> $myfile

if [ ${add+x} ];then
        sed -i "s/CONFIGURATION_TYPE\=ADVANCED/CONFIGURATION_TYPE\=LATER/" $myfile
fi

if [ ${configure+x} ];then
        sed -i "s/CONFIGURE_ORACLE_SOFTWARE_LIBRARY\=true/CONFIGURE_ORACLE_SOFTWARE_LIBRARY\=false/" $myfile
fi

}

usage(){
>&2 cat <<EOF
        Usage: $0
        [ -p | --prereq_emrep ] -- checks prereq for OMR
        [ -i | --install ] -- install primary oms
        [ -s | --software_only ] -- install
        [ -u | --update [OMSPatcher|patch [zipFile]|list]
        [ -c | --configure ] -- configures oms
        [ -e | --edit_response ] -- configures additonal oms
EOF
exit 1
}



args=$(getopt -a -o u:pisceh --long update,prereq_emrep,install,install_software_only,configure,edit_response,help: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
fi



eval set -- ${args}
while :
do
  case $1 in
    #-u | --username)   username=$2    ; shift 2   ;;
    -p | --prereq_emrep)   prereq_emrep=true   ; shift  ;;
    -i | --install)   install=true  ; shift ;;
    -s | --software_only)   add=true  ; shift ;;
    -u | --update)   update=$(echo $2|tr A-Z a-z); file_name=$4; shift 2 ;;
    -c | --configure)   configure=true  ; shift ;;
    -e | --edit_response)   edit_response=true  ; shift ;;
    -h | --help)    usage      ; shift   ;;
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage ;;
  esac
done


# MAIN
echo "start ..."
mydir=$(mktemp -dt "$(basename $0).XXXXXXXX" --tmpdir=/run/user/$(id -u))
myfile=$(mktemp -t "$(basename $0).XXXXXXXX" --tmpdir=$mydir)
echo $mydir
echo $myfile
if [ -z ${prereq_emrep+x} ]; then echo "prereq_emrep is unset"; else echo "prereq_emrep is set to '$prereq_emrep'"; fi
if [ -z ${install+x} ]; then echo "install is unset"; else echo "install is set to '$install'"; fi
if [ -z ${add+x} ]; then echo "add is unset"; else echo "add is set to '$add'"; fi
if [ -z ${configure+x} ]; then echo "configure is unset"; else echo "configure is set to '$configure'"; fi
if [ -z ${update+x} ]; then echo "update is unset"; else echo "update is set to '$update'"; fi

if [ -z ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ -z ${add+x} ] && [ -z ${configure+x} ] && [ -z ${edit_response+x} ] && [ -z ${update+x} ];then
        usage
elif [ ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ -z ${add+x} ] && [ -z ${configure+x} ] && [ -z ${edit_response+x} ] && [ -z ${update+x} ];then
        echo "check prereqs omr"
        FEED=true
        create_empre_rsp
        $RUN_INSTALLER EMPREREQ_KIT=true  -silent -responseFile $myfile | tee -a $INSTALLER_LOG
        RC=$?
elif [ -z ${prereq_emrep+x} ] && [ ${install+x} ] && [ -z ${add+x} ] && [ -z ${configure+x} ] && [ -z ${edit_response+x} ] && [ -z ${update+x} ];then
        echo "install oms"
        FEED=true
        create_install_rsp
        $RUN_INSTALLER -silent -responseFile $myfile | tee -a $INSTALLER_LOG
        RC=$?
elif [ -z ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ ${add+x} ] && [ -z ${configure+x} ] && [ -z ${edit_response+x} ] && [ -z ${update+x} ];then
        echo "add oms"
        FEED=true
        create_install_rsp
        $RUN_INSTALLER -silent -responseFile $myfile | tee -a $INSTALLER_LOG
        RC=$?
        sudo $ROOT_SH
elif [ -z ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ -z ${add+x} ] && [ ${configure+x} ] && [ -z ${edit_response+x} ] && [ -z ${update+x} ];then
        echo "confgiure oms"
        FEED=true
        create_install_rsp
        $CONFIGURE -silent -responseFile $myfile
        RC=$?
elif [ -z ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ -z ${add+x} ] && [ -z ${configure+x} ] && [ ${edit_response+x} ] && [ -z ${update+x} ];then
        echo "edit response"
        FEED=false
        edit_response
        RC=$?
elif [ -z ${prereq_emrep+x} ] && [ -z ${install+x} ] && [ -z ${add+x} ] && [ -z ${configure+x} ] && [ -z ${edit_response+x} ] && [ ${update+x} ];then
        echo "update"
        FEED=false
        case $update in
                omspatcher)
                        echo "update omspatcher"
                        echo "ORACLE_HOME: $ORACLE_HOME"
                        export ORACLE_HOME
                        OMSPV=$($OMSP version | grep -i "omspatcher version"| awk -F":" '{print $2}'| sed -e 's/\.//g' |sed -e 's/ //g')
                        ls -al $OMSPU
                        unzip -o $OMSPU -d $OMS_BASE/tmp/
                        mv $ORACLE_HOME/OMSPatcher $ORACLE_HOME/OMSPatcher_$OMSPV
                        mv $OMS_BASE/tmp/OMSPatcher $ORACLE_HOME/.
                        OMSPVU=$($OMSP version | grep -i "omspatcher version"| awk -F":" '{print $2}'| sed -e 's/\.//g' |sed -e 's/ //g')
                        echo "version: $OMSPV"
                        echo "update version: $OMSPVU"
                        RC=0
                        ;;
                patch)
                        if [ ! -f $STAGE_LOCATION_PATCHES/$file_name ] ; then
                                echo "patch file: $file_name does't exists in $STAGE_LOCATION_PATCHES"
                                exit 99
                        else
                                unzip -l $STAGE_LOCATION_PATCHES/$file_name
                                patchdir=$(mktemp -dt "$(basename $0).XXXXXXXX" --tmpdir=$OMS_BASE/tmp/)
                                unzip $STAGE_LOCATION_PATCHES/$file_name -d $patchdir 2>/dev/null
                                RC_UNZIP=$?
                                patchnumber=$(ls -d $patchdir/*/ | awk -F"$patchdir" '{print $2}' | sed -e 's/\///g')
                                if [ $RC_UNZIP -eq 0 ];then
                                        echo "installing patch number: $patchnumber"
                                        cd $patchdir/$patchnumber
                                        export ORACLE_HOME
                                        $OMSP apply -bitonly | tee -a $INSTALLER_LOG
                                        RC=$?
                                else
                                        echo "unzip failed"
                                fi
                                rm -rf $patchdir

                        fi
                        ;;
                list)
                        echo "DIR: $STAGE_LOCATION_PATCHES"
                        ls -al $STAGE_LOCATION_PATCHES/
                        RC=$?
                        ;;
                *)
                        echo "update option: $update uknown"
                        ;;
        esac
        RC=$?
else
        usage
fi


if [ $FEED ];then
        if [ $RC -ne 0 ];then
                echo "$0 failed: $RC"
        else
                echo "$0 successful: $RC"
        fi
        if [ -f $INSTALLER_LOG ] ; then
                echo "run_installer log: $INSTALLER_LOG"
        fi
fi
#rm -rf $mydir