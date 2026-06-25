# Prepare environment

export NODE_VERSION="24.18.0"
export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Gather data
read -r -e -p "Enter the repo url: " REPO

repo_name="${REPO##*/}"        # Extracts "repo.git"
repo_name="${repo_name%.git}" # Removes ".git"

read -r -e -i "$repo_name" -p "Enter project name: " PROJECT
read -r -e -i "8080" -p "Enter port number: " PORT

# Fetch project

git clone $REPO $PROJECT
cd $PROJECT

npm install express --save


echo "Creating app.js file"

cat <<- EOF > app.js
#!/usr/bin/env node
const express = require('express')
const app = express()  
const port = $PORT;

app.get('/api/search', (req, res) => {  
	res.status(200).send('Search is now handled on the client side with FlexSearch.');  
})

app.use(express.static('dist'))

app.get('/{*any}', (req, res) => {  
	res.redirect("/404")  
})

app.listen(port, () => {  
	console.log(\`Digital garden running on port \${port}\`)  
})
EOF

chmod +x app.js

npm install
npm run build


echo "Create app service $PROJECT.service"

cat <<- EOF > /etc/systemd/system/$PROJECT.service
[Unit]
Description=$PROJECT digital garden

[Service]
ExecStart=/root/.nvm/nvm-exec $PWD/app.js
Restart=always
User=root
Group=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Environment=NODE_VERSION=24.18.0
WorkingDirectory=$PWD

[Install]
WantedBy=multi-user.target
EOF


echo "Create /opt/$PROJECT/update.sh"

mkdir -p /opt/$PROJECT

cat <<- EOF > /opt/$PROJECT/update.sh
#!/bin/bash
# /opt/$PROJECT/update.sh

REPO_DIR="$PWD/"
LOG_FILE="/var/log/$PROJECT-update.log"

cd "\$REPO_DIR" || exit 1

# Check for remote changes
git fetch origin

LOCAL=\$(git rev-parse HEAD)
REMOTE=\$(git rev-parse origin/main)

if [ "\$LOCAL" != "\$REMOTE" ]; then
	echo "[\$(date)] Changes detected, updating..." >> "\$LOG_FILE"

	git pull origin main >> "\$LOG_FILE" 2>&1

	export NODE_VERSION="24.18.0"
	export NVM_DIR="\$HOME/.nvm"

	[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
	npm run build >> "\$LOG_FILE" 2>&1

	# Adjust to however you run your server
	systemctl restart $PROJECT >> "\$LOG_FILE" 2>&1
	echo "[\$(date)] Update complete" >> "\$LOG_FILE"
else
	echo "[\$(date)] No changes" >> "\$LOG_FILE"
fi
EOF

chmod +x /opt/$PROJECT/update.sh



echo "Create update /etc/systemd/system/$PROJECT-update.service"

cat <<- EOF > /etc/systemd/system/$PROJECT-update.service
# /etc/systemd/system/<repo name>-update.service
[Unit]
Description=Check and update Digital Garden
After=network-online.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/opt/$PROJECT
ExecStart=/opt/$PROJECT/update.sh
EOF


echo "Create update timer /etc/systemd/system/$PROJECT-update.timer"

cat <<- EOF > /etc/systemd/system/$PROJECT-update.timer
# /etc/systemd/system/$PROJECT-update.timer
[Unit]
Description=Poll for Digital Garden updates
Requires=$PROJECT-update.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF


echo "enable services"
systemctl daemon-reload
systemctl enable --now $PROJECT
systemctl enable --now $PROJECT-update.timer

systemctl status $PROJECT
