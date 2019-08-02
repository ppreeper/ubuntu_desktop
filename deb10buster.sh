#!/bin/bash

function spause {
    read -n 1 -r -p "Press any key to continue..." key
}

echo -e "\n# Adjust NSSwitch"

spause

sudo sed -e 's_ \[NOTFOUND=return\]__g' -i /etc/nsswitch.conf
sudo sed -e 's_ winbind__g' -i /etc/nsswitch.conf
sudo sed -e 's_^hosts: .*_& [NOTFOUND=return]_' -i /etc/nsswitch.conf
sudo sed -e 's_^passwd: .*_& winbind_' -i /etc/nsswitch.conf
sudo sed -e 's_^group: .*_& winbind_' -i /etc/nsswitch.conf

sudo sed -e 's/enabled=*$/enabled=0/' -i /etc/default/apport

cat << _EOF_ | sudo tee /etc/sysctl.d/20-custom.conf
fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_user_watches = 1048576
vm.max_map_count=262144
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
vm.swappiness=10
_EOF_

sudo sysctl --system

cat << _EOF_ | sudo tee /usr/local/bin/update
sudo bash -c "apt update; apt -y upgrade; apt -y autoremove; apt -y autoclean; flatpak update"
_EOF_
sudo chmod +x /usr/local/bin/update
update

cat << _EOF_ | sudo tee /root/crontab.root
5   */3 *   *   *   /usr/local/bin/update > /dev/null
_EOF_
sudo crontab -u root /root/crontab.root

echo -e "\n# Make common dirs"

spause

sudo chmod 777 /mnt
mkdir ${HOME}/app
mkdir ${HOME}/mnt
mkdir ${HOME}/.cfg

sed -e 's_^#alias_alias_' -i ${HOME}/.bashrc

cat << _EOF_ >> ${HOME}/.bashrc
for f in \${HOME}/.cfg/*cfg
do
    source \${f}
done
_EOF_

source ${HOME}/.bashrc

echo -e "\n# Install base"

spause

# application installation helpers
sudo apt -y install apt-transport-https pkg-config flatpak gnome-software-plugin-flatpak git ;
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# downloaders
sudo apt -y install curl wget aria2 ;
# file utils
sudo apt -y install mc fdupes tree gddrescue rename ;
# editor
sudo apt -y install vim ;
# compression
sudo apt -y install lzop pigz unrar cabextract ;
# benchmarking
sudo apt -y install fio sysbench siege ;
# mail utils
sudo apt -y install swaks ;
# remote file systems
sudo apt -y install curlftpfs sshfs nfs-common samba cifs-utils krb5-user ;
# monitoring
sudo apt -y install htop nmon ;
# backup
sudo apt -y install duplicity syncthing;
sudo cp /lib/systemd/system/syncthing@.service /lib/systemd/system/syncthing@${USER}.service
sudo systemctl daemon-reload
sudo systemctl enable syncthing@${USER}.service
sudo systemctl start syncthing@${USER}.service
# desktop utils
sudo apt -y install gnome-tweaks ;
# web browsers
sudo apt -y install chromium epiphany-browser ;
# basic codecs
sudo apt -y install ffmpeg ;

echo -e "\n# Clone bin"

spause

git clone https://github.com/ppreeper/bin.git ${HOME}/bin

cp ${HOME}/bin/vimrc ${HOME}/.vimrc

# kerberos defaults
sudo cp /etc/krb5.conf /etc/krb5.conf.orig
sudo cp ${HOME}/bin/krb5.conf /etc/krb5.conf

echo -e "\n#Nextcloud desktop"

sudo apt -y install nextcloud-desktop ;

echo -e "\n# Install utils"

spause

sudo apt -y install nmap zenmap ;
sudo apt -y install remmina remmina-plugin-nx remmina-plugin-spice ;
sudo apt -y install minicom ;
sudo usermod -a -G tty ${USER}
sudo usermod -a -G dialout ${USER}
cp ${HOME}/bin/minirc.dfl ${HOME}/.minirc.dfl

echo -e "\n# Install codecs"

spause

# xiph codecs
sudo apt -y install oggz-tools ogmtools opus-tools vorbis-tools flac ;
sudo apt -y install mkvtoolnix ;
sudo apt -y install vpx-tools ;
sudo apt -y install cuetools shntool ;
sudo apt -y install sox ;
sudo apt -y install libavcodec-extra;
sudo apt -y install libdvdread4 dvdbackup ;
sudo apt -y install gstreamer1.0-libav gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly ;

echo -e "\n# Install media"

spause

sudo apt -y install gnome-mpv

echo -e "\n# Install programming languages"

echo -e "\n## python3"

spause

sudo apt -y install python3-pip python3-dev pypy3

spause

sudo -H apt install direnv
sudo -H pip3 install pipenv

echo -e "PATH=\"\${HOME}/.local/bin:\${PATH}\"" | tee ${HOME}/.cfg/20_python.cfg

source ${HOME}/.bashrc

cat << _EOF_ > ${HOME}/.cfg/99_direnv.cfg
eval "\$(direnv hook bash)"
_EOF_

source ${HOME}/.bashrc

echo -e "\n## java"

#spause

#sudo apt -y install openjdk-8-jdk openjfx ;

echo -e "\n## javascript"

spause

mkdir ${HOME}/.local/npm-packages

echo -e "prefix=\${HOME}/.local/npm-packages" | tee ${HOME}/.npmrc

cat << _EOF_ > ${HOME}/.cfg/20_js.cfg
export NPM_PACKAGES="\${HOME}/.local/npm-packages"
PATH="\${NPM_PACKAGES}/bin:\${PATH}"
export MANPATH="\$NPM_PACKAGES/share/man:\${MANPATH}"
_EOF_

source ${HOME}/.bashrc

echo -e "\n## yarn repo"

wget -O- https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update

echo -e "\n## nodejs repo"

#curl -sSL https://deb.nodesource.com/setup_10.x | sudo -E bash -

echo -e "\n## nodejs"

sudo apt -y install nodejs npm

echo -e "\n## yarn"

sudo apt -y install yarn

echo -e "\n## css scss"

spause

yarn global add sass
yarn global add prettier

echo -e "\n## go"

spause

${HOME}/bin/goup

echo -e "PATH=\"\${HOME}/go/bin:\${PATH}\"" | tee ${HOME}/.cfg/20_go.cfg

source ${HOME}/.bashrc

echo -e "\n## rust"

spause

curl https://sh.rustup.rs -sSf | sh

echo -e "\n# Install database support"

echo -e "\n## sqlite"

spause

sudo apt -y install sqlite3

echo -e "\n## postgresql"

spause

sudo apt -y install postgresql-client postgresql-server-dev-all

echo -e "\n## freetds"

spause

sudo apt -y install freetds-bin freetds-dev tdsodbc unixodbc unixodbc-bin unixodbc-dev

echo -e "\n## mariadb"

spause

sudo apt -y install mariadb-client

echo -e "\n# Install docker"

spause

sudo apt -y install docker.io

apt update

sudo usermod -aG docker ${USER}

echo -e "\n# Install docker-compose"

spause

sudo -H pip3 install docker-compose

echo -e "\n# Install virtualization"

sudo apt -y install qemu-kvm virt-viewer vagrant-libvirt

echo -e "\n# Install desktop apps"

sudo flatpak install -y org.gnome.Books org.gnome.Games org.gnome.Evolution

echo -e "\n# Install network vpn connectors"

sudo apt -y install network-manager-openconnect-gnome network-manager-openvpn-gnome network-manager-pptp-gnome network-manager-ssh-gnome network-manager-vpnc-gnome

echo -e "\n## email client"

spause

sudo flatpak install -y org.gnome.Evolution

echo -e "\n## libreoffice"

spause

sudo apt purge -y libreoffice*

sudo flatpak install -y org.libreoffice.LibreOffice

echo -e "\n# Install deskpub"

spause

sudo apt -y install pdfshuffler
sudo apt -y install posterazor
sudo apt -y install cmark
sudo apt -y install asciidoc
sudo apt -y install texmaker

curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
sudo apt -y install ./wkhtmltox.deb
rm wkhtmltox.deb
sudo apt -y install -f

echo -e "\n# Install cad"

spause

sudo apt -y install freecad librecad dxf2gcode ;

echo -e "\n# Install wine"

spause

sudo apt -y install wine ;

echo -e "\n# Hugo"

spause

sudo apt -y install hugo ;

echo -e "\n# eclipse"

spause

sudo flatpak install -y io.dbeaver.DBeaverCommunity ;

echo -e "\n# vscode"

spause

wget -O code.deb https://go.microsoft.com/fwlink/?LinkID=760868
sudo apt -y install ./code.deb ;
rm code.deb ;

spause

code --install-extension aaron-bond.better-comments
code --install-extension akmittal.hugofy
code --install-extension bibhasdn.django-snippets
code --install-extension ckolkman.vscode-postgres
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension dbaeumer.jshint
code --install-extension dbaeumer.vscode-eslint
code --install-extension ecmel.vscode-html-css
code --install-extension eg2.tslint
code --install-extension eriklynd.json-tools
code --install-extension esbenp.prettier-vscode
code --install-extension formulahendry.vscode-mysql
code --install-extension GrapeCity.gc-excelviewer
code --install-extension gruntfuggly.todo-tree
code --install-extension HookyQR.beautify
code --install-extension joaompinto.asciidoctor-vscode
code --install-extension mdickin.markdown-shortcuts
code --install-extension ms-mssql.mssql
code --install-extension ms-python.python
code --install-extension ms-vscode.Go
code --install-extension octref.vetur
code --install-extension PeterJausovec.vscode-docker
code --install-extension redhat.vscode-yaml
code --install-extension robinbentley.sass-indented
code --install-extension saviorisdead.RustyCode
code --install-extension shd101wyy.markdown-preview-enhanced
code --install-extension yzhang.markdown-all-in-one
code --install-extension Zignd.html-css-class-completion

