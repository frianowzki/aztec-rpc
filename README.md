# Run Execution & Consensus Node for Aztec Network (Locally)

![aztec-logo](https://github.com/user-attachments/assets/e2e679eb-86d3-4704-8395-aa91bea90c42)

![52E793D1-8A86-4EC8-A883-E01088AA8C20_4_5005_c](https://github.com/user-attachments/assets/bcd43031-b014-4610-b3fd-5c9831576f62)
#
## Hardware requirements to run Execution & Consensus Node:
- CPU 4+ Cores
- 16GB+ RAM
- 2TB SSD/NVMe
- Network: 25 Mbps up/down bandwidth
#
## - Stop & Remove Current Sequencer:
```
docker ps -a
```
```
docker stop [aztec-container-id]
```
```
rm -rf .aztec/alpha-testnet/data
```
```
aztec-up alpha-testnet
```
## - Installing Dependencies:
```
apt -y update && apt -y upgrade
apt dist-upgrade && sudo apt autoremove
```

## - Activate Firewall & Open Port:
```
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw allow 12000/udp
sudo ufw allow 13000/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```
```
sudo ufw status
```

## - Add New Users & Group:
```
sudo adduser --home /home/geth --disabled-password --gecos 'Geth Client' geth
sudo adduser --home /home/beacon --disabled-password --gecos 'Prysm Beacon Client' beacon
sudo groupadd eth
sudo usermod -a -G eth geth
sudo usermod -a -G eth beacon
```
## - Generate JWT Secret:
```
sudo mkdir -p /var/lib/secrets
sudo chgrp -R eth /var/lib/ /var/lib/secrets
sudo chmod 750 /var/lib/ /var/lib/secrets
sudo openssl rand -hex 32 | tr -d '\n' | sudo tee /var/lib/secrets/jwt.hex > /dev/null
```
```
sudo chown root:eth /var/lib/secrets/jwt.hex
sudo chmod 640 /var/lib/secrets/jwt.hex
```
## - Create Directory for `geth` and `beacon`:
```
sudo -u geth mkdir /home/geth/geth
sudo -u beacon mkdir /home/beacon/beacon
```
## - Install Ethereum:
```
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum
```
## - Create `geth` Service:
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
  --http \
  --http.api eth,net,engine,admin \
  --sepolia \
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
## - Create `beacon` Directory & Configure `prysm`:
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
  —-sepolia \
  --datadir /home/beacon/beacon \
  --execution-endpoint=http://127.0.0.1:8551 \
  --jwt-secret=/var/lib/secrets/jwt.hex \
  --suggested-fee-recipient=YourWalletAddress \
  --checkpoint-sync-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \
  --genesis-beacon-api-url=https://checkpoint-sync.sepolia.ethpandaops.io/ \
  --accept-terms-of-use

[Install]
WantedBy=multi-user.target
```
### *change `YourWalletAddress` with your validator public key
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
### *wait until both of `geth` and `beacon` are fully synced (could take a few hours or even a day). 
#
## - Now go back to my previous guide [here](https://github.com/frianowzki/aztec-sequencer-node) and look at this part, we're gonna edit `RPC_URL` and `CONSENSUS_HOST_URL`:

```
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls RPC_URL  \
  --l1-consensus-host-urls CONSENSUS_HOST_URL \
  --sequencer.validatorPrivateKey 0xPrivateKey \
  --sequencer.coinbase 0xPublicAddress \
  --p2p.p2pIp IP \
  --p2p.maxTxPoolSize 1000000000 \
  --port 8081
```
#
- Change `RPC_URL` with:
```
http://localhost:8545
```
Or if you run it from different machine use:
```
your_VPS_IP:8545
```
#
- Change `CONSENSUS_HOST_URL` with:
```
http://localhost:4000
```
Or if you run it from different machine use:
```
your_VPS_IP:4000
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
## If You Want Stop & Remove:
```
systemctl stop geth.service
systemctl disable geth.service
rm /etc/systemd/system/geth.service
```
```
systemctl stop beacon.service
systemctl disable beacon.service
rm /etc/systemd/system/beacon.service
```
## Good luck guys! 🤝🏼
