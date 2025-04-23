# This script is designed to make sure that all required CLI tools for the pipeline are installed and on the system path

echo "Setting permissions for all files in current directory..."
sudo chmod -R a+rwx ./*

echo "Downloading required tools..."
wget -q https://go.dev/dl/go1.23.5.linux-amd64.tar.gz && echo "Downloaded Go."
wget -q https://github.com/genesis-community/genesis/releases/download/v3.0.13/genesis && echo "Downloaded Genesis."
wget -q https://github.com/geofffranks/spruce/releases/download/v1.31.1/spruce-linux-amd64 && echo "Downloaded Spruce."
wget -q https://github.com/egen/safe/releases/download/v1.8.0/safe-linux-amd64 && echo "Downloaded Safe."
wget -q https://github.com/cloudfoundry/credhub-cli/releases/download/2.9.41/credhub-linux-amd64-2.9.41.tgz && echo "Downloaded Credhub."
wget -q https://github.com/cloudfoundry/bosh-cli/releases/download/v7.8.6/bosh-cli-7.8.6-linux-amd64 && echo "Downloaded Bosh CLI."

echo "Extracting Credhub CLI..."
tar -xvf credhub-linux-amd64-2.9.41.tgz

echo "Moving binaries to appropriate locations..."
sudo mv ./bosh-cli-7.8.6-linux-amd64 /usr/local/bin/bosh && echo "Moved Bosh CLI."
sudo mv ./credhub /bin/credhub && echo "Moved Credhub."
sudo mv ./safe-linux-amd64 /bin/safe && echo "Moved Safe."
sudo mv ./spruce-linux-amd64 /bin/spruce && echo "Moved Spruce."
sudo mv ./genesis /bin/genesis && echo "Moved Genesis."

echo "Setting executable permissions..."
chmod u+x "$(dirname "$0")/compare-release-specs.sh"
chmod u+x /usr/local/bin/bosh
chmod u+x /bin/credhub
chmod u+x /bin/safe
chmod u+x /bin/spruce
chmod u+x /bin/genesis

echo "Installing Vault..."
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg | tee /dev/tty
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list | tee /dev/tty
sudo apt update | tee /dev/tty && sudo apt install vault -y | tee /dev/tty && echo "Installed Vault."

echo "Checking installed binaries..."
echo $(ls -la /usr/local/bin/bosh)

echo "Installed versions:"
echo "bosh: $(bosh --version)"
echo "credhub: $(credhub --version)"
echo "safe: $(safe --version)"
echo "spruce: $(spruce --version)"
echo "genesis: $(genesis --version)"
echo "vault: $(vault --version)"
