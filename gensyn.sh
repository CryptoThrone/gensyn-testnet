#!/bin/bash

# Color codes from old script
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NC="\e[0m"

# Directory variables from old script
SWARM_DIR="$HOME/rl-swarm"
TEMP_DATA_PATH="$SWARM_DIR/modal-login/temp-data"
HOME_DIR="$HOME"

cd $HOME

# Clean up previous setup (from new script)
echo -e "${BOLD}${YELLOW}[✓] Cleaning up previous setup...${NC}"
screen -X -S gensyn quit 2>/dev/null

# Check and install Python >= 3.10 (from new script)
echo -e "${BOLD}${YELLOW}[✓] Checking Python version...${NC}"
PYTHON_VERSION=$(python3 --version 2>&1 | grep -Po '3\.([0-9]+)' | grep -Po '[0-9]+')
if [ -z "$PYTHON_VERSION" ] || [ "$PYTHON_VERSION" -lt 10 ]; then
    echo -e "${BOLD}${YELLOW}[✓] Python 3.10 or higher is required. Installing...${NC}"
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt install -y python3.10 python3.10-venv python3.10-dev python3-pip
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
fi

# Install other dependencies (from new script)
echo -e "${BOLD}${YELLOW}[✓] Installing dependencies...${NC}"
sudo apt install -y curl wget screen git lsof nano unzip nodejs npm

# Swarm.pem handling (from old script)
if [ -f "$SWARM_DIR/swarm.pem" ]; then
    echo -e "${BOLD}${YELLOW}You already have an existing ${GREEN}swarm.pem${YELLOW} file.${NC}\n"
    echo -e "${BOLD}${YELLOW}Do you want to:${NC}"
    echo -e "${BOLD}1) Use the existing swarm.pem${NC}"
    echo -e "${BOLD}${RED}2) Delete existing swarm.pem and start fresh${NC}"

    while true; do
        read -p $'\e[1mEnter your choice (1 or 2): \e[0m' choice
        if [ "$choice" == "1" ]; then
            echo -e "\n${BOLD}${YELLOW}[✓] Using existing swarm.pem...${NC}"
            mv "$SWARM_DIR/swarm.pem" "$HOME_DIR/"
            mv "$TEMP_DATA_PATH/userData.json" "$HOME_DIR/" 2>/dev/null
            mv "$TEMP_DATA_PATH/userApiKey.json" "$HOME_DIR/" 2>/dev/null

            rm -rf "$SWARM_DIR"

            echo -e "${BOLD}${YELLOW}[✓] Cloning fresh repository...${NC}"
            cd $HOME && git clone https://github.com/CryptoThrone/rl-swarm.git > /dev/null 2>&1

            mv "$HOME_DIR/swarm.pem" rl-swarm/
            mv "$HOME_DIR/userData.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            mv "$HOME_DIR/userApiKey.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            break
        elif [ "$choice" == "2" ]; then
            echo -e "${BOLD}${YELLOW}[✓] Removing existing folder and starting fresh...${NC}"
            rm -rf "$SWARM_DIR"
            cd $HOME && git clone https://github.com/CryptoThrone/rl-swarm.git > /dev/null 2>&1
            break
        else
            echo -e "\n${BOLD}${RED}[✗] Invalid choice. Please enter 1 or 2.${NC}"
        fi
    done
else
    echo -e "${BOLD}${YELLOW}[✓] No existing swarm.pem found. Cloning repository...${NC}"
    cd $HOME && [ -d rl-swarm ] && rm -rf rl-swarm; git clone https://github.com/CryptoThrone/rl-swarm.git > /dev/null 2>&1
fi

cd rl-swarm || { echo -e "${BOLD}${RED}[✗] Failed to enter rl-swarm directory. Exiting.${NC}"; exit 1; }

# Setup .env files (from new script)
echo -e "${BOLD}${YELLOW}[✓] Setting up .env files...${NC}"
mkdir -p modal-login
cat <<EOL > modal-login/.env
NEXT_PUBLIC_ALCHEMY_API_KEY=RL2EtY6LXx2XCLPV3JZriJAB9mnELa2U
NEXT_PUBLIC_PAYMASTER_POLICY_ID=4c37387c-2a55-4edd-b188-b5c44eb71e96
SMART_CONTRACT_ADDRESS=0x2fC68a233EF9E9509f034DD551FF90A79a0B8F82
EOL

mkdir -p web/ui
cp modal-login/.env web/ui/.env

# Virtual environment setup (from both scripts, merged)
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${BOLD}${YELLOW}[✓] Deactivating existing virtual environment...${NC}"
    deactivate
fi

echo -e "${BOLD}${YELLOW}[✓] Setting up Python virtual environment...${NC}"
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies (from new script)
echo -e "${BOLD}${YELLOW}[✓] Installing Python dependencies...${NC}"
pip install -r requirements-hivemind.txt || pip install torch numpy hivemind

# Run the script with automatic 'y' for testnet prompt (from new script)
echo -e "${BOLD}${YELLOW}[✓] Running rl-swarm...${NC}"
echo "y" | ./run_rl_swarm.sh

echo -e "${BOLD}${GREEN}[✓] Setup complete! Check the screen session with: screen -r gensyn${NC}"
