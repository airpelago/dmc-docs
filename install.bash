#!/bin/bash

echo "Checking docker and docker-compose installation"
echo "This might take a while if not installed"

if [ ! -x "$(command -v docker)" ]; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi
if [[ ! -f "/usr/local/bin/docker-compose" ]];
sudo -u pi bash -c 'pip install docker-compose'

echo Enter dronemissioncontrol.com login details:
read -p 'Email: ' uservar
read -sp 'Password: ' passvar
echo
echo Fetching drones for $uservar
echo
postDataJson="{\"email\":\"$uservar\",\"password\":\"$passvar\"}"
token=$( curl -s https://dev-api.dronemissioncontrol.com/drone/gettoken \
-H 'Content-Type: application/json' \
-d ${postDataJson} ) 

token=${token//\"}
if [ ! ${#token} -ge 10 ]; then 
echo
echo "could not fetch token" ; exit
fi

drones=$(curl -s -H "Authorization: $token" https://dev-api.dronemissioncontrol.com/user/drones/)
drones=${drones/'"drones":'}
drones=${drones//\{}
drones=${drones//\[}
drones=${drones//\]}
drones=${drones//\}}
drones=${drones//\"}}

delimiter=,
array=(); 
s=$drones$delimiter
while [[ $s ]]; do
    array+=( "${s%%"$delimiter"*}" );
    s=${s#*"$delimiter"};
done;
declare array
n=0
names=();
idLst=();
for value in "${array[@]}"
do 
    n=$((n+1))
    if [[ $value == *name* ]]; then
        value=${value/'name:'}
        names+=( "$value" )
        id=${array[$n]/'id:'} 
        idLst+=( $id )

    fi    
done
declare names
declare idLst

PS3='Please select your drone: '
select opt in "${names[@]}"
do
    break;
done

echo
read -p 'Enter drone verification key: ' dronepassvar
echo "ID=${idLst[$REPLY]}" > config.env
echo "PASSWORD=$dronepassvar" >> config.env
curl  -s https://raw.githubusercontent.com/airpelago/dmc-docs/master/docker-compose.yml > docker-compose.yml
docker-compose pull

read -p "do you wish to start [Y/n]? " -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]
then
   docker-compose up -d
fi
