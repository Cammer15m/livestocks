apt-get update
apt-get install jq -y

# docker-plgin
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

apt install snapd -y
snap install ttyd --classic

# Download RDI
export RDI_VERSION=1.10.0

# check file already exists
mkdir -p "/downloads"
chmod 744 "/downloads"
if [ ! -f "/downloads/rdi-installation-$RDI_VERSION.tar.gz" ]; then
    curl --output /downloads/rdi-installation-$RDI_VERSION.tar.gz -O https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz
else
    echo "File rdi-installation-$RDI_VERSION.tar.gz already exists."
fi
chmod -R 744 "/downloads"

#apt install nodejs -y
apt install npm -y
npm install -g n
n stable

#n stable messes with the path, so reset it so npm can install dependencies
export PATH="$PATH"
npm install

useradd -m -s /bin/bash labuser
echo "labuser:redislabs" | sudo chpasswd
sudo usermod -aG sudo labuser

chown -R labuser:labuser /downloads

echo 'labuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

npm run build

cp -r ./doc/ ./dist/client/

