# digital-garden-deploy
Script to deploy digital garden on a debian machine

# Prerequisites
- A ready to publish vault
- A ssh or gpg key setup between the host and your github account
- A debian server with:
	- install libatomic `apt install libatomic`
	- install npm through nvm:
		- `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash`
		- nvm install 24
		- nvm use 24

# Steps
1. Create repo from https://github.com/oleeskild/digitalgarden as a template
	- Don't include all branches (just main)
2. On the server:
	- `bash <(curl -s https://raw.githubusercontent.com/Dendrowen/digital-garden-deploy/refs/heads/main/script.sh)` 
4. Create a new fine-grained token (https://github.com/settings/personal-access-tokens/new)
	1. Add permissions:
		- Content: read and write
		- Pull requests: read and write
	2. Save token
5. In obsidian:
	1. Install the digital garden plugin
	2. Set your repo name, username, and created token
		- When refreshing the settings it should say that your site template is up to date.
	3. Add the dg-publish property to all files 
	4. Add the dg-home property to a single file
	5. `ctrl+p` in your homepage file
	6. `Digital garden: Publish All Notes Marked for Publish`
