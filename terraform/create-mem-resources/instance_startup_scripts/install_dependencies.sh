#################################################################################
#Install depedencies
#################################################################################
#!/bin/bash
sudo apt-get update
#wait 30
sudo apt-get install -yq build-essential python3-pip rsync python3-dev python3.11-venv libffi-dev gcc libc-dev cargo make musl-dev musl-tools musl curl git golang

# Install MUSL
sudo apt-get install -yq musl-dev musl-tools musl

# Set installation directory
cd $HOME

# Install Rust via rustup
sudo curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y 

# Update the env 
source "$HOME/.cargo/env"

# Finalize rustup config 
sudo /root/.cargo/bin/rustup update beta 
sudo /root/.cargo/bin/rustup update nightly

# Clone AVML
cd $HOME
git clone https://github.com/microsoft/avml.git 
cd avml
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl

# Install dwarf2json
# go version - https://ubuntu.pkgs.org/20.04/ubuntu-main-amd64/golang-1.14_1.14.2-1ubuntu1_all.deb.html
cd $HOME
git clone https://github.com/volatilityfoundation/dwarf2json.git
cd dwarf2json
# Install using the required go version
/usr/lib/go/bin/go build  
cd $HOME

# Install volatility3
git clone https://github.com/volatilityfoundation/volatility3.git
cd volatility3

# Build
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
python3 setup.py build
cd $HOME

# Install drgn
sudo apt install python3-drgn -y

# Install crash
sudo apt install crash