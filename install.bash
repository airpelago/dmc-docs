#!/bin/bash

echo Checking docker installation...
if [ ! -x "$(command -v docker)" ]; then
    echo Docker not installed, installing...
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null
    usermod -aG docker pi
    echo Please log out and in to apply changes!
    exit 0
fi
echo Done

echo Checking docker-compose installation...
if [[ ! -f "/home/pi/.local/bin/docker-compose" ]]; then
    echo Docker-compose not installed, installing...
    sudo -u pi bash -c 'pip install docker-compose' > /dev/null
    echo "export PATH=/home/pi/.local/bin:$PATH" >> /home/pi/.bashrc
fi
echo Done
echo

echo Enter dronemissioncontrol.com login details:
read -p 'Email: ' uservar
read -sp 'Password: ' passvar
echo
echo Fetching drones for $uservar
echo
postDataJson="{\"email\":\"$uservar\",\"password\":\"$passvar\"}"
token=$( curl -s https://api.dronemissioncontrol.com/drone/gettoken \
-H 'Content-Type: application/json' \
-d ${postDataJson} ) 

token=${token//\"}
if [ ! ${#token} -ge 10 ]; then 
echo
echo "Authorization failed" ; exit
fi

drones=$(curl -s -H "Authorization: $token" https://api.dronemissioncontrol.com/user/drones/)
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

index=$((REPLY-1))
read -p 'Enter drone verification key: ' dronepassvar
echo "ID=${idLst[$index]}" > config.env
echo "PASSWORD=$dronepassvar" >> config.env
curl  -s https://raw.githubusercontent.com/airpelago/dmc-docs/master/docker-compose.yml > docker-compose.yml
sudo -u pi bash -c '/home/pi/.local/bin/docker-compose pull'

read -p "Start drone? [Y/n]" -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]
then
   sudo -u pi bash -c '/home/pi/.local/bin/docker-compose up -d --force-recreate'
fi
