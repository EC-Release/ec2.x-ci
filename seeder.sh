#!/bin/bash

source <(wget -O - https://raw.githubusercontent.com/EC-Release/sdk/disty/scripts/cipher/crypto.sh)        
crdj=$(getCredJson "cred.json" "$EC_GITHUB_TOKEN")

#get sdc adm cred
CA_PPRS=$(echo $crdj | jq -r ".${INST_NAME}.ownerHash")          
EC_API_DEV_ID=$(echo $crdj | jq -r ".${INST_NAME}.devId")
EC_API_OA2=$(echo $crdj | jq -r ".${INST_NAME}.oauthURL")  
EC_SEED_NODE=$(echo $crdj | jq -r ".${INST_NAME}.instURL")  
DB_NAME=$(echo $crdj | jq -r ".${INST_NAME}.db")
INST_LOG=${INST_NAME}.log

EC_SEED_HOST="http://localhost${EC_PORT}"
ref=$(getURLHostnameAndPort "$EC_SEED_HOST")
ref2=$(getURLPort "$EC_SEED_HOST")
LOG_URL=$(printf 'ws://%s/v1.2beta/ec/log' "$ref")

mkdir -p ./.ec ./dbs
setDb "$DB_NAME" "$EC_GITHUB_TOKEN"
tree ./

#timeout -k 15 15 \
#timeout 15 \
docker run \
--network=host \
--name refc \
-e AGENT_REV=${AGENT_REV} \
-e CA_PPRS=${CA_PPRS} \
-e EC_AGT_GRP=${EC_AGT_GRP} \
-e EC_AGT_MODE=${EC_AGT_MODE} \
-e EC_API_APP_NAME=${EC_API_APP_NAME} \
-e EC_API_DEV_ID=${EC_API_DEV_ID} \
-e EC_API_OA2=${EC_API_OA2} \
-e EC_PORT=${EC_PORT} \
-e EC_SEED_HOST=${EC_SEED_HOST} \
-e EC_SEED_NODE=${EC_SEED_NODE} \
-v $(pwd)/.ec/.db:/root/.ec/.db \
-p $ref2:$ref2 \
-d ghcr.io/ec-release/api:1.2-b
#-t ghcr.io/ec-release/api:v1.2beta | tee -a ${INST_LOG} >/dev/null


x=1; count=20
while [ $x -le "$count" ]
do
  {
    {
      sleep 1
      echo - connecting log host: "$LOG_URL"
      agent -log -url "$LOG_URL" \
      -tkn $(getSdcTkn "$EC_API_DEV_ID" "$CA_PPRS" "$EC_API_OA2") \
      tee -a "$INST_LOG"
    } && {
      break
    }
  } || {
    x=$(( $x + 1 ))
  }
done          

if (( "$x" > "$count" )); then
  echo failed connecting to seeder 
  exit 0
fi

docker logs refc > ~tmp
${INST_LOG} >> ~tmp

ls -al ./.ec/.db
cp ./.ec/.db ./dbs/${DB_NAME}
cp ${INST_LOG} ./dbs/${INST_LOG}   
