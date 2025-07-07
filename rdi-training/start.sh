#!/bin/bash

# ---------------------------------------------------------------------------
: ${DOMAIN?"Need to set DOMAIN"}
[ -z "$PASSWORD" ] && export PASSWORD=redislabs

sudo chmod -R 777 grafana/


export HOSTNAME=$(hostname -s)
export PASSWORD=$PASSWORD
export HOST_IP=$(hostname -I | awk '{print $1}')

export RDI_VERSION=1.10.0

envsubst < ./grafana_config/grafana.ini.template > ./grafana_config/grafana.ini
envsubst < ./prometheus/prometheus.yml.template > ./prometheus/prometheus.yml

export RE_USER=admin@rl.org

#Total hack.  There are instances where /snap/bin is not ready before docker-compose leading to error
#So sleep a little.

while [ ! -x /snap/bin ]; do
    sleep 5
done

docker-compose up -d --build 

main_nodes=( re-n1 )
all_nodes=( re-n1 )
ssh_nodes=( re-n1 )

for i in "${all_nodes[@]}"
do
   #wait for admin port
   docker cp wait-for-code.sh $i:/tmp/wait-for-code.sh
   docker exec -e URL=https://$i:9443/v1/bootstrap -e CODE=200 $i /bin/bash /tmp/wait-for-code.sh

   #enable port 53
   docker exec --user root --privileged $i /bin/bash /tmp/init_script.sh
done

#create cluster 1
export CLUSTER=re-cluster1.ps-redislabs.org
export IP=172.16.22.21
server="re-n1"

cluster_file="redis/create_cluster.json.template"

envsubst < $cluster_file > create_cluster.json
docker cp create_cluster.json $server:/tmp/create_cluster.json
docker exec $server curl -k -v --silent --fail -H 'Content-Type: application/json' -d @/tmp/create_cluster.json  https://$server:9443/v1/bootstrap/create_cluster

#wait for admin port
docker cp wait-for-code.sh $server:/tmp/wait-for-code.sh
docker exec -e URL=https://$server:9443/v1/bootstrap -e CODE=200 $server /bin/bash /tmp/wait-for-code.sh


#update license
if [[ -n $RE1_LICENSE ]];
then
   docker exec re-n1 curl -v -k -d "{\"license\": \"$(echo $RE1_LICENSE | sed -z 's/\n/\\n/g')\"}" -u $RE_USER:$PASSWORD -H "Content-Type: application/json" -X PUT https://localhost:9443/v1/license
fi

sleep 20
docker-compose up -d
sleep 20

#configure Grafana
cd grafana
bash config_grafana.sh
cd ..


#export GRAFANA_VERSION=$(docker exec grafana grafana server -v | grep -oP 'Version \K[^\s]+')
#export RE_VERSION=$(docker exec re-n1 bash -c "curl -u $RE_USER:$PASSWORD https://localhost:9443/v1/nodes -k --fail | jq '.'" | grep software_version | uniq | awk -F ":" '{print $2}' | awk -F '\"' '{print $2}')

#export HOST_IP=$(hostname -I | awk '{print $1}')
#export REDIS_INSIGHT_VERSION=2.64


#create instructions
#cd about
#bash create_about.sh
#cd ..

#nohup npm run dev &

echo '----------------------------------'
echo "Starting ttyd with labuser on port 7681..."

sudo -u labuser nohup ttyd -W -p 7681 -t disableLeaveAlert=true -t fontSize=14 -t 'cursorStyle=bar' --client-option reconnect=true bash -c "cd /home/labuser && exec bash" &

echo '----------------------------------'

wait $!
