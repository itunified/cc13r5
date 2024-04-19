# installation cc13r5
## pre-requirements

### check if gpg is installed
```bash
gpg --version
```
### create OMS filesystem structure
```bash
OMS_BASE=/u01/app/oracle/cc
export OMS_BASE
mkdir -p $OMS_BASE/cc13cR5/mw
mkdir -p $OMS_BASE/cc13cR5/gc_inst
mkdir -p $OMS_BASE/oraInventory
mkdir -p $OMS_BASE/backup/latest
mkdir -p $OMS_BASE/agent
mkdir -p $OMS_BASE/instantclient19.19
mkdir -p $OMS_BASE/share/agent_download
mkdir -p $OMS_BASE/share/scripts
mkdir -p $OMS_BASE/share/scripts/ccinstall/logs
mkdir -p $OMS_BASE/share/swlib
mkdir -p $OMS_BASE/share/patches
mkdir -p $OMS_BASE/share/software
mkdir -p $OMS_BASE/share/secrets
mkdir -p $OMS_BASE/share/env
mkdir -p $OMS_BASE/share/instantclient19.19
mkdir -p $OMS_BASE/tmp
```
### git clone
```bash
$OMS_BASE/share/scripts
git clone git@github.com:itunified/cc13r5.git
mv cc13r5-main/ccinstall/ .
rm -rf cc13r5-main
cd ccinstall/
chmod +x *.sh
```
#### 
### download oracle cloud control binaries
### scp binaries to target server
### download clout control patches 
### copy patches to target server
### create gpg key
```bash
gpg --batch --gen-key $OMS_BASE/share/scripts/ccinstall/etc/keygen.ccadmin.batch
gpg --export ccadmin > $OMS_BASE/share/secrets/public.ccadmin.key
gpg --export-secret-key ccadmin > $OMS_BASE/share/secrets/private.ccadmin.key
import (only multiple oms)
gpg --import $OMS_BASE/share/secrets/private.ccadmin.key
```
### create secrets
```bash
$OMS_BASE/share/scripts/ccinstall/genSecrets.sh -username=sysman -g
$OMS_BASE/share/scripts/ccinstall/genSecrets.sh -username=omrsys -g
$OMS_BASE/share/scripts/ccinstall/genSecrets.sh -username=weblogic -g
$OMS_BASE/share/scripts/ccinstall/genSecrets.sh -username=nodemanager -g
$OMS_BASE/share/scripts/ccinstall/genSecrets.sh -username=agentregistration -g
```
### edit etc/.response
```markdown
OMR_HOSTNAME without domain name
```

### check cloud control pre requirements
```bash
$OMS_BASE/share/scripts/ccinstall/silentInstall.sh -p
```
### cloud control intallation (admin server)
```bash
$OMS_BASE/share/scripts/ccinstall/silentInstall.sh -i
```
### patching
```
├── OMSPatcher
│   ├── latest -> p19999993_135000_Generic.zip
│   └── p19999993_135000_Generic.zip
├── p35437906_135000_Generic.zip
├── PatchSearch.xml
└── readme.txt
```
## list available patches
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -u list
```

## update OMSPatcher
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -u omspatcher
```

## apply RU
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -u patch p35437906_135000_Generic.zip
```

## backup OMS configuraiton ot /u01/app/oracle/cc/share/backup
```
<OMS_HOME>/bin/emctl exportconfig oms [-sysman_pwd <sysman password>]
[-dir <backup dir>] Specify directory to store backup file
[-keep_host] Specify this parameter if the OMS was installed using a virtual hostname (using
ORACLE_HOSTNAME=<virtual_hostname>)
```

### add additional OMS
install cloud control software on additional OMS 
this will only install the software binaries
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -s
```

copy response file to /u01/app/oracle/cc/share/backup/omsca.rsp
this will be needed later for recover additional oms

## update OMSPatcher
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -u omspatcher
```

## apply RU
```
cd /u01/app/oracle/cc/share/scripts/ccinstall
./silentInstall.sh -u patch p35437906_135000_Generic.zip
```

## configure additional OMS

## backup and edit the OMS_HOME/bin/EMomsCmds.pm file
```
- Look for this subroutine:

sub getCommonJavaOptions

- Change this line:

$systemProps = " -Djava.security.egd=file:///dev/./urandom -Dweblogic.log.FileName=$INSTANCE_HOME/sysman/log/wls.log ";
to:

$systemProps = " -Djava.security.egd=file:///dev/./urandom -Dweblogic.log.FileName=$INSTANCE_HOME/sysman/log/wls.log -Doracle.jdbc.fanEnabled=false ";
```

## recover OMS from backup file
```
$ORACLE_HOME/bin/omsca recover -ms -backup_file /u01/app/oracle/cc/share/backup/opf_ADMIN_20230725_183726.bka -silent -RESPONSE_FILE /u01/app/oracle/cc/share/scripts/ccinstall/omsca.rsp
```

## verify installation

### configure loadbalance

## secure oms

## secure agent



