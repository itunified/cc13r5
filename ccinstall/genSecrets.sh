#!/bin/bash


OMS_BASE=/u01/app/oracle/cc

# do not etdit below this line
GPGKEY=ccadmin
SECRETS=$OMS_BASE/share/secrets


usage(){
        >&2 cat <<EOF
                Usage: $0
                [ -u | --username input ]
                [ -p | --password ]
                [ -g | --generate ]
EOF
exit 1
}

secrets() {
        echo $pw |gpg --encrypt --recipient $GPGKEY > $SECRETS/.$username.gpg
        echo "secret for user $username securly stored in file: $SECRETS/.$username.gpg"
}



args=$(getopt -a -o upgh: --long username:,password,help,generate: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
fi



eval set -- ${args}
while :
do
  case $1 in
    -u | --username)   username=$2    ; shift 2   ;;
    -p | --password)   password=true   ; shift  ;;
    -g | --generate)   generate=true  ; shift ;;
    -h | --help)    usage      ; shift   ;;
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage ;;
  esac
done



# MAIN
if [ -z ${password+x} ]; then echo "password is unset"; else echo "password is set to '$password'"; fi
if [ -z ${generate+x} ]; then echo "generate is unset"; else echo "generate is set to '$generate'"; fi
if [ -z ${generate+x} ] && [ -z  ${password+x} ]; then
        usage
elif [ ${generate+x} ] && [ -z ${password+x} ]; then
        pw=$(openssl rand -base64 32)
        secrets
elif [ -z ${generate+x} ] && [ ${password+x} ]; then
        read -rsp "Please enter $username password: " pw
        echo
        secrets
fi
