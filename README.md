# Run Execution & Consensus Node for Aztec Network (Locally)

<img width="731" height="249" alt="Screenshot_2025-09-11_180859-removebg-preview" src="https://github.com/user-attachments/assets/0eda5e4e-1446-42e1-888e-cc911d0b3539" />


<img width="1536" height="1024" alt="Art 1" src="https://github.com/user-attachments/assets/1661b282-b149-4255-9952-3a7d6b2361a8" />

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
sudo usermod -aG docker $(whoami) && newgrp docker
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
aztec-up 2.0.3
```
#
## 2. Update Sequencer:
###  * Latest Aztec image is ``2.0.3``
- If you are using CLI:
```
docker ps -a
```
```
docker stop aztec && docker rm aztec
```
```
rm -rf /tmp/aztec-world-state-*
rm -rf ~/.aztec/alpha-testnet/data
```
```
aztec-up 2.0.3
```
- If You Are Using Docker Compose:
```
cd .aztec/alpha-testnet
```
```
aztec-up 2.0.3
```
```
rm -rf /tmp/aztec-world-state-*
rm -rf ~/.aztec/alpha-testnet/data
```
```
sed -i 's|image: aztecprotocol/aztec:.*|image: aztecprotocol/aztec:2.0.3|' docker-compose.yml
```
```
docker-compose down -v && docker-compose up -d 
```
###
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
sudo ufw allow 8880
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
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.16.5-737ffd1b.tar.gz
```
```
tar -xvf geth-linux-amd64-1.16.5-737ffd1b.tar.gz
```
```
sudo mv geth-linux-amd64-1.16.5-737ffd1b/geth /usr/bin/geth
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
## - Check 'geth' Version:
```
geth --version
```
## - Check `geth` Logs:
```
sudo journalctl -fu geth
```
## 10. Create `beacon` Directory & Configure `prysm`:
```
sudo -u beacon mkdir /home/beacon/bin
```
```
sudo -u beacon curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output /home/beacon/bin/prysm.sh
```
```
sudo -u beacon chmod +x /home/beacon/bin/prysm.sh
```
```
cd /home/beacon/bin/
```
```
./prysm.sh beacon-chain --version
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
  --subscribe-all-data-subnets \
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
  --network testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls CONSENSUS_HOST_URL \
  --sequencer.validatorPrivateKeys 0xPrivateKey \
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
## 13. Run Sequencer Using Docker Compose + Installing Auto Updater:
```
cd .aztec/alpha-testnet
```
```
nano .env
```
```
ETHEREUM_RPC_URL=http://your_IP:8545
CONSENSUS_BEACON_URL=http://your_IP:3500
VALIDATOR_PRIVATE_KEYS=0xPrivateKey
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
    image: aztecprotocol/aztec:2.0.3
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEYS: ${VALIDATOR_PRIVATE_KEYS}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: info
    entrypoint: >
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start \
      --network testnet \
      --node \
      --archiver \
      --sequencer \
      --port 8081
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/testnet/data/:/data
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
aztec-up 2.0.3
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
VALIDATOR_PRIVATE_KEYS=0xPrivateKey
COINBASE=0xPublicAddress
P2P_IP=your_IP
```
Save it and set Docker Compose:
```
nano docker-compose.yml
```
```
services:
  aztec-node:
    container_name: aztec
    image: aztecprotocol/aztec:2.0.3
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEYS: ${VALIDATOR_PRIVATE_KEYS}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: info
    entrypoint: >
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start \
      --network testnet \
      --node \
      --archiver \
      --sequencer \
      --port 8081
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/testnet/data/:/data
```
Run it by use this command:
```
docker compose up -d
```
#
## 15. [Update] if you are a validator and running the latest version ``2.0.3`` you can add more than 1 validator (10 validators max). You can add this to your command:
- For CLI Users:
```
--sequencer.validatorPrivateKeys 0xprivatekey1,0xprivatekey2,etc \
```
(Optional) If you are running more than 1 validator and want to use 1 validator address as a default funding transactions address for all of those addresses, add this:
```
--sequencer.publisherPrivateKey 0xPublisherPrivateKey \
```
Replace ``0xprivatekey1,0xprivatekey2,etc`` with your new generated private keys and separate it with comma ``,`` (10 MAX)

Change ``0xPublisherPrivateKey`` with your default/primary private key which has ETH Sepolia balance for funding the transactions
#
- For Docker-Compose Users:
```
cd .aztec/alpha-testnet
```
```
nano .env
```
```
ETHEREUM_RPC_URL=http:/your_IP:8545
CONSENSUS_BEACON_URL=http:/your_IP:3500
VALIDATOR_PRIVATE_KEYS=0xPrivateKey1,0xprivatekey2,0xprivatekey3,etc
COINBASE=0xPublicAddress
P2P_IP=your_IP
```
(Optional) if you run more than one validator, add this below the ``VALIDATOR_PRIVATE_KEYS=0xprivatekey1,0xprivatekey2,0xprivatekey3,etc``:
```
PUBLISHER_PRIVATE_KEY=0xprivatekey
```
```
nano docker-compose.yml
```
```
services:
  aztec-node:
    container_name: aztec
    image: aztecprotocol/aztec:2.0.3
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEYS: ${VALIDATOR_PRIVATE_KEYS}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: info
    entrypoint: >
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start \
      --network testnet \
      --node \
      --archiver \
      --sequencer \
      --port 8081
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/testnet/data/:/data
```
(Optional) if you run more than one validator, add this below the ``VALIDATOR_PRIVATE_KEYS: ${VALIDATOR_PRIVATE_KEYS}``:
```
SEQ_PUBLISHER_PRIVATE_KEY: ${PUBLISHER_PRIVATE_KEY}
```
## 16. Migration from ``alpha-testnet`` to ``testnet``
#
```
docker stop aztec && docker rm aztec
```
```
rm -rf /tmp/aztec-world-state-*
```
```
rm -rf $HOME/.aztec/alpha-testnet/data
```
```
mkdir -p $HOME/.aztec/testnet
```
```
cd .aztec/testnet
```
```
aztec-up 2.0.3 && sed -i 's/latest/2.0.3/' "$HOME/.aztec/bin/.aztec-run" && aztec -V
```
### - If you are using CLI: 
```
aztec start --node --archiver --sequencer \
  --network testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls BEACON_URL \
  --sequencer.validatorPrivateKeys 0xPK1,0xPK2,etc \
  --sequencer.publisherPrivateKey 0xYourPrivateKey \
  --sequencer.coinbase 0xYourAddress \
  --p2p.p2pIp Your_IP
```
#
### - If you are using Docker Compose: 
```
cd .aztec/testnet
```
```
nano .env
```
```
ETHEREUM_RPC_URL=RPC_IP:8545
CONSENSUS_BEACON_URL=RPC_IP:3500
VALIDATOR_PRIVATE_KEYS=0xPK1,0xPK2,etc
PUBLISHER_PRIVATE_KEY=0xYourPrivateKey
COINBASE=0xYourAddress
P2P_IP=Your_IP
```
### Ctrl + X + Y > Enter
```
nano docker-compose.yml
```
```
services:
  aztec-node:
    container_name: aztec
    image: aztecprotocol/aztec:2.0.3
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEYS: ${VALIDATOR_PRIVATE_KEYS}
      SEQ_PUBLISHER_PRIVATE_KEY: ${PUBLISHER_PRIVATE_KEY}
      COINBASE: ${COINBASE}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: info
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network testnet --node --archiver --sequencer'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8081:8081
    volumes:
      - /root/.aztec/testnet/data/:/data
```
### Ctrl + X + Y > Enter
```
docker-compose down -v && docker-compose up -d 
```
### Check Logs:
```
docker logs -f aztec 
```
## *Note: If you see this error ``WARN: sequencer Cannot propose block 1 at next L2 slot 385 since the committee does not exist on L1`` Just ignore it, all good. 
#
## 17. Update Geth & Prysm version due to Sepolia's Fusaka upgrade (Must Update Before October 14th):
- Geth:
```
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.16.5-737ffd1b.tar.gz
```
```
tar -xvf geth-linux-amd64-1.16.5-737ffd1b.tar.gz
```
```
sudo mv geth-linux-amd64-1.16.5-737ffd1b/geth /usr/bin/geth
```
```
sudo systemctl stop geth
sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl enable geth
```
```
geth --version
```
- Prysm:
```
sudo -u beacon curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output /home/beacon/bin/prysm.sh
```
```
sudo -u beacon chmod +x /home/beacon/bin/prysm.sh
```
```
cd /home/beacon/bin/
```
```
./prysm.sh beacon-chain --version
```
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
  --subscribe-all-data-subnets \
  --accept-terms-of-use

[Install]
WantedBy=multi-user.target
```
```
sudo systemctl stop beacon
sudo systemctl daemon-reload
sudo systemctl start beacon
sudo systemctl enable beacon
```
- Check if your Geth & Prysm working good:
```
sudo systemctl status geth
```
```
sudo systemctl status beacon
```
## 18. Add New Governance Proposal:
```
sudo ufw allow 8880
```
- For CLI users:
```
aztec start --node --archiver --sequencer \
  --network testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls BEACON_URL \
  --sequencer.validatorPrivateKeys 0xPK1,0xPK2,etc \
  --sequencer.publisherPrivateKey 0xYourPrivateKey \
  --sequencer.coinbase 0xYourAddress \
  --sequencer.governanceProposerPayload 0x9D8869D17Af6B899AFf1d93F23f863FF41ddc4fa \
  --p2p.p2pIp Your_IP
```
- For Docker Compose users:
```
cd .aztec/testnet
```
```
nano docker-compose.yml
```
- Add this on port part:
```
      - 8880:8880
```
# <img width="363" height="133" alt="image" src="https://github.com/user-attachments/assets/1afb9c4d-7166-42a3-b2d1-529ac65abdc7" />
- Add this to any of these lines:
```
      GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS: ${GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS}
```
<img width="915" height="257" alt="image" src="https://github.com/user-attachments/assets/d266228a-2ab6-454f-832c-3a3dafc56bf3" />

```
nano .env
```
- Add this to the new line:
```
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0x9d8869d17af6b899aff1d93f23f863ff41ddc4fa
```
- Restart the node:
```
docker-compose down -v && docker-compose up -d && cd
```
```
cd .aztec
```
- Now add the new Governance Proposal (for both CLI & Docker-Compose users):
```
curl -X POST http://localhost:8880 \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc":"2.0",
    "method":"nodeAdmin_setConfig",
    "params":[{"governanceProposerPayload":"0x9D8869D17Af6B899AFf1d93F23f863FF41ddc4fa"}],
    "id":1
  }'
```
- Change the ``localhost`` with your VPS IP since we don't use host mode.
![photo_2025-10-14_00-11-26](https://github.com/user-attachments/assets/fa7de7c9-fe13-443c-abd8-fbc5ba24e47a)
- To verify that it done, run this:
```
curl -X POST http://localhost:8880 \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc":"2.0",
    "method":"nodeAdmin_getConfig",
    "id":1
  }'
```
*change the ``localhost`` with your VPS IP
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
