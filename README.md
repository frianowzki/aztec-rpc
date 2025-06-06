# Run Execution & Consensus Node for Aztec Network (Locally)

![aztec-logo](https://github.com/user-attachments/assets/e2e679eb-86d3-4704-8395-aa91bea90c42)

![8980F4C8-4ED7-43DE-B928-C8D99AB2EC4D_1_201_a](https://github.com/user-attachments/assets/e174c074-4a4a-44c0-8f68-65995fbf84b9)

#
## Hardware requirements to run Execution & Consensus Node:
- CPU 4+ Cores
- 16GB+ RAM
- 2TB SSD/NVMe
- Network: 25 Mbps up/down bandwidth
#
## 1. Follow This Step If It's Your First Time Running Aztec Sequencer (Otherwise Just Next To Step 2):
```
sudo apt-get update && sudo apt-get upgrade -y
```
```
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen  -y
```
```
source <(wget -O - https://raw.githubusercontent.com/frianowzki/installer/main/docker.sh)
```
```
sudo groupadd docker && sudo usermod -aG docker $(whoami) && newgrp docker
```
```
bash -i <(curl -s https://install.aztec.network)
```
```
echo 'export PATH=$PATH:/root/.aztec/bin' >> ~/.bashrc
```
```
source ~/.bashrc
```
```
aztec-up alpha-testnet
```
#
## 2. Stop, Remove & Update Current Sequencer:
```
docker ps -a
```
```
docker stop [aztec-container-id] && docker rm [aztec-container-id]
```
```
rm -rf .aztec/alpha-testnet/data
```
```
aztec-up latest
```
If You Are Using Docker Compose:
```
cd .aztec/alpha-testnet
```
```
docker-compose down -v
```
```
rm -rf ~/.aztec/alpha-testnet/data/
```
```
aztec-up latest
```
```
docker-compose up -d
```
### * Latest Aztec image is 0.87.7
## 3. Installing Dependencies:
```
apt -y update && apt -y upgrade
apt-get install coreutils curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
apt dist-upgrade && sudo apt autoremove
```

## 4. Activate Firewall & Open Port:
```
sudo ufw allow 8545/tcp
sudo ufw allow 3500/tcp
sudo ufw allow 4000/tcp
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw allow 12000/udp
sudo ufw allow 13000/tcp
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```
```
sudo ufw status
```

## 5. Add New Users & Group:
```
sudo adduser --home /home/geth --disabled-password --gecos 'Geth Client' geth
sudo adduser --home /home/beacon --disabled-password --gecos 'Prysm Beacon Client' beacon
sudo groupadd eth
sudo usermod -a -G eth geth
sudo usermod -a -G eth beacon
```
## 6. Generate JWT Secret:
```
sudo mkdir -p /var/lib/secrets
```
```
sudo chgrp -R eth /var/lib/ /var/lib/secrets
```
```
sudo chmod 750 /var/lib/ /var/lib/secrets
```
```
sudo openssl rand -hex 32 | tr -d '\n' | sudo tee /var/lib/secrets/jwt.hex > /dev/null
```
```
sudo chown root:eth /var/lib/secrets/jwt.hex
sudo chmod 640 /var/lib/secrets/jwt.hex
```
## 7. Create Directory for `geth` and `beacon`:
```
sudo -u geth mkdir /home/geth/geth
sudo -u beacon mkdir /home/beacon/beacon
```
## 8. Install Ethereum & geth:
```
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum
```
```
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.15.11-36b2371c.tar.gz
```
```
tar -xvf geth-linux-amd64-1.15.11-36b2371c.tar.gz
```
```
sudo mv geth-linux-amd64-1.15.11-36b2371c/geth /usr/bin/geth
```
## 9. Create `geth` Service:
```
sudo nano /etc/systemd/system/geth.service
```
```
[Unit]

Description=Geth
After=network-online.target
Wants=network-online.target

[Service]

Type=simple
Restart=always
RestartSec=5s
User=geth
WorkingDirectory=/home/geth
ExecStart=/usr/bin/geth \
  --sepolia \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 8545 \
  --http.api "eth,net,engine,admin" \
  --authrpc.addr "127.0.0.1" --authrpc.port 8551 \
  --http.corsdomain "*" \
  --http.vhosts "*" \
  --datadir /home/geth/geth \
  --authrpc.jwtsecret /var/lib/secrets/jwt.hex

[Install]
WantedBy=multi-user.target
```
## - Start & Enable `geth` Service:
```
sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl enable geth
```
## - Check `geth` Status:
```
sudo systemctl status geth
```
## - Check `geth` Logs:
```
sudo journalctl -fu geth
```
## 10. Create `beacon` Directory & Configure `prysm`:
```
sudo -u beacon mkdir /home/beacon/bin
sudo -u beacon curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output /home/beacon/bin/prysm.sh
sudo -u beacon chmod +x /home/beacon/bin/prysm.sh
```
## - Create `beacon` Service:
```
sudo nano /etc/systemd/system/beacon.service
```
```
[Unit]

Description=Prysm Beacon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=5s
User=beacon
ExecStart=/home/beacon/bin/prysm.sh beacon-chain \
  --sepolia \
  --http-modules=beacon,config,node,validator \
  --rpc-host=0.0.0.0 --rpc-port=4000 \
  --grpc-gateway-host=0.0.0.0 --grpc-gateway-port=3500 \
  --datadir /home/beacon/beacon \
  --execution-endpoint=http://127.0.0.1:8551 \
  --jwt-secret=/var/lib/secrets/jwt.hex \
  --checkpoint-sync-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \
  --genesis-beacon-api-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \
  --accept-terms-of-use

[Install]
WantedBy=multi-user.target
```
#
## - Start & Enable `beacon` Service:
```
sudo systemctl daemon-reload
sudo systemctl start beacon
sudo systemctl enable beacon
```
## - Check `beacon` Status:
```
sudo systemctl status beacon
```
## - Check `beacon` Logs:
```
sudo journalctl -fu beacon
```
#
#### *wait until both of `geth` and `beacon` are fully synced (could take a few hours or even a day). 
#
## 11. You can check your sync by running this script:
```
nano sync.sh
```
```
#!/bin/bash

echo "=== GETH SYNC STATUS ==="
curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
     -H "Content-Type: application/json" http://localhost:8545 | jq

echo ""
echo "=== BEACON SYNC STATUS ==="
curl -s http://localhost:3500/eth/v1/node/syncing | jq
```
```
chmod +x sync.sh
```
```
./sync.sh
```

#
## 12. Now let's run Aztec Sequencer again:

```
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls CONSENSUS_HOST_URL \
  --sequencer.validatorPrivateKey 0xPrivateKey \
  --sequencer.coinbase 0xPublicAddress \
  --p2p.p2pIp IP \
  --port 8081 
```
#
- Change `RPC_URL` with:
```
http://Your_VPS_IP:8545
```
#
- Change `CONSENSUS_HOST_URL` with:
```
http://Your_VPS_IP:3500
```
#
- Enter and wait until it fully synced, you can check the logs using:
```
docker ps -a
```
```
docker logs -f [aztec-container-ID]
```
#
## 13. Run Sequencer Using Docker Compose:
```
cd .aztec/alpha-testnet
```
```
nano .env
```
```
ETHEREUM_RPC_URL=http://your_IP:8545
CONSENSUS_BEACON_URL=http://your_IP:3500
VALIDATOR_PRIVATE_KEY=0xPrivateKey
COINBASE=0xPublicAddress
P2P_IP=your_IP
```
```
nano docker-compose.yml
```
```
services:
  aztec-node:
    container_name: aztec
    image: aztecprotocol/aztec:latest
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEY: ${VALIDATOR_PRIVATE_KEY}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: debug
    entrypoint: >
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start \
      --network alpha-testnet \
      --node \
      --archiver \
      --sequencer \
      --auto-update config \
      --port 8081
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/alpha-testnet/data/:/data
```
```
docker-compose up -d
```
Check the Logs with
```
docker logs -f aztec
```
#
## 14. Update Aztec Governance (Only for Validators):
```
docker ps -a
```
```
docker stop [aztec-container-id] && docker rm [aztec-container-id]
```
```
rm -rf .aztec/alpha-testnet/data
```
```
aztec-up latest
```
If you are using CLI you can just add this line
```
--sequencer.governanceProposerPayload 0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef
```
Or if you use Docker Compose you can use this on your .env 
```
cd .aztec/alpha-testnet
```
```
nano .env
```
```
ETHEREUM_RPC_URL=http:/your_IP:8545
CONSENSUS_BEACON_URL=http:/your_IP:3500
VALIDATOR_PRIVATE_KEY=0xPrivateKey
COINBASE=0xPublicAddress
P2P_IP=your_IP
GOVERNANCE_PAYLOAD=0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef
```
Save it and set Docker Compose:
```
nano docker-compose.yml
```
```
services:
  aztec-node:
    container_name: aztec
    image: aztecprotocol/aztec:latest
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEY: ${VALIDATOR_PRIVATE_KEY}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: debug
      GOVERNANCE_PAYLOAD: ${GOVERNANCE_PAYLOAD}
    entrypoint: >
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start \
      --network alpha-testnet \
      --node \
      --archiver \
      --sequencer \
      --auto-update config \
      --port 8081 \
      --sequencer.governanceProposerPayload ${GOVERNANCE_PAYLOAD}"
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/alpha-testnet/data/:/data
```
Run it by use this command:
```
docker compose up -d
```
#
## If You Want Stop & Remove:
```
systemctl stop geth.service
systemctl disable geth.service
```
```
rm /etc/systemd/system/geth.service
```
```
rm -rf /home/geth
```
```
systemctl stop beacon.service
systemctl disable beacon.service
```
```
rm /etc/systemd/system/beacon.service
```
```
rm -rf /home/beacon
```
```
docker stop aztec && docker rm aztec
```
```
rm -rf .aztec
```

## Good luck guys! 🤝🏼
