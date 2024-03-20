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
mkdir -p $OMS_BASE/share/swlib
mkdir -p $OMS_BASE/share/patches
mkdir -p $OMS_BASE/share/software
mkdir -p $OMS_BASE/share/secrets
mkdir -p $OMS_BASE/share/env
mkdir -p $OMS_BASE/share/instantclient19.19
mkdir -p $OMS_BASE/tmp
```
### download oracle cloud control binaries
### scp binaries to target server
### download clout control patches 
### copy patches to target server
### create secretes
```bash
gpg --batch --gen-key $OMS_BASE/share/scripts/ccinstall/etc/keygen.ccadmin.batch
gpg --export ccadmin > $OMS_BASE/share/secrets/public.ccadmin.key
gpg --export-secret-key ccadmin > $OMS_BASE/share/secrets/private.ccadmin.key
import (only multiple oms)
gpg --import $OMS_BASE/share/secrets/private.ccadmin.key
```
### check cloud control pre requirements
```bash
$OMS_BASE/share/scripts/ccinstall/silentInstall.sh -p
```
### cloud control intallation (admin server)
```bash
$OMS_BASE/share/scripts/ccinstall/silentInstall.sh -i
```
