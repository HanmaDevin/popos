#! /bin/bash
#    ____           __        ____   _____           _       __
#    /  _/___  _____/ /_____ _/ / /  / ___/__________(_)___  / /_
#    / // __ \/ ___/ __/ __ `/ / /   \__ \/ ___/ ___/ / __ \/ __/
#  _/ // / / (__  ) /_/ /_/ / / /   ___/ / /__/ /  / / /_/ / /_
# /___/_/ /_/____/\__/\__,_/_/_/   /____/\___/_/  /_/ .___/\__/
#                                                  /_/
clear

repo="$HOME/popos"
cfgPath="$repo/.config"

install_packages() {
    local packages=("golang" "python-pip" "libreoffice" "glow" "ntfs-3g" "ufw" "zsh" "gamemode" "mangohud" "bat" "openjdk-21-jdk" "docker-compose" "ripgrep" "cargo" "rustup" "fd-find" "wine" "openssh" "libpam-u2f" "libfido2-1" "xdg-desktop-portal-gtk" "xdg-desktop-portal-wlr" "xdg-desktop-portal" "texlive-full" "nala" "jq" "gamescope" "rustfmt" "rust-src" "nodejs" "npm")
    for pkg in "${packages[@]}"; do
        sudo dnf in -y "$pkg"
    done

    cargo install starship
    cargo install eza
    cargo install nu
    cargo install zoxide
    flatpak install qbittorrent
}

install_deepcool_driver() {
  read -r -p ":: Do you want to install DeepCool CPU-Fan driver (y/n)?: " deepcool
  if [[ "$deepcool" =~ [yY] ]]; then
    sudo cp "$repo/DeepCool/deepcool-digital-linux" "/usr/sbin"
    sudo cp "$repo/DeepCool/deepcool-digital.service" "/etc/systemd/system/"
sudo systemctl enable deepcool-digital
  fi
}

configure_git() {
  read -r -p ":: Do you want to setup git (y/n)?: " git
  if [[ "$git" =~ [yY] ]]; then
    read -r -p ":: What is your user name?: " username
    git config --global user.name "$username"
    read -r -p ":: What is your email?: " useremail
    git config --global user.email "$useremail"
    git config --global pull.rebase true
  fi

  read -r -p ":: Do you want to create a ssh-key (y/n)?: " ssh
  if [[ "$ssh" =~ [yY] ]]; then
    ssh-keygen -t ed25519 -C "$useremail"
  fi
}

detect_nvidia() {
  gpu=$(lspci | grep -i '.* vga .* nvidia .*')

  shopt -s nocasematch

  if [[ $gpu == *' nvidia '* ]]; then
    echo ":: Nvidia GPU is present"
    echo "Installaling nvidia drivers now..." -- sleep 2
    sudo apt-get install system76-driver-nvidia
  else
    echo ":: It seems you are not using a Nvidia GPU"
    echo ":: If you have a Nvidia GPU then install the drivers yourself please :)"
    sleep 2
  fi
}

config_ufw() {
  echo "Firewall will be configured with default values..." -- sleep 2
  sudo ufw enable
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw status verbose
}

copy_config() {
  read -r -p ":: Do you want to use my awesome configurations (y/n)?: " ans
  if [[ "$ans" =~ [yY] ]]; then
    echo "Creating bakups..." -- sleep 2

    if [[ -f "$HOME/.zshrc" ]]; then
      mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    if [[ -d "$HOME/.config" ]]; then
      mv "$HOME/.config" "$HOME/.config.bak"
    fi

    if [[ ! -d "$HOME/Pictures/Screenshots/" ]]; then
      mkdir -p "$HOME/Pictures/Screenshots/"
    fi

    cp "$repo/.zshrc" "$HOME/"
    cp -r "$cfgPath" "$HOME/"
    cp -r "$repo/Wallpaper/" "$HOME/Pictures/"

    sudo cp -r "$repo/Cursor/Bibata-Modern-Ice" "/usr/share/icons"
    sudo cp -r "$repo/fonts/" "/usr/share"

    sudo cp -r "$repo/icons/" "/usr/share/"

    echo "Trying to change the SHELL..." -- sleep 2
    chsh -s /bin/zsh
  fi
}

install_discord() {
  read -r -p ":: Do you want to install Discord (y/y)?: " discord
  if [[ "$discord" =~ [yY] ]]; then
    wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
    sudo apt install ./discord.deb
  fi
}

install_lazygit() {
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
}
install_fzf() {
  FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | \grep -Po '"tag_name": *"\K[^"]*')
  curl -Lo fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-0.65.2-linux_amd64.tar.gz"
  tar -xf ./fzf.tar.gz
  sudo cp ./fzf "/usr/bin"
}

install_fastfetch() {
  FASTFETCH_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | \grep -Po '"tag_name": *"\K[^"]*')
  curl -Lo fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
  sudo apt install ./fastfetch.deb
}

install_neovim() {
  NEOVIM_VERSION=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | \grep -Po '"tag_name": *"\K[^"]*')
  curl -Lo nvim "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.appimage"
  chmod +x ./nvim
  sudo cp ./nvim "/usr/bin"
}

install_ghcli() {
  read -r -p ":: Do you want to install GitHub CLI (y/n)?: " ghcli
  if [[ "$ghcli" =~ [yY] ]]; then
    (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
  fi
}

install_protonvpn() {
  read -r -p ":: Do you want to install Proton VPN (y/n)?: " vpn
  if [[ "$vpn" =~ [yY] ]]; then
    wget -O vpn.deb "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"
    sudo apt install ./vpn.deb
  fi
}

install_steam() {
  read -r -p ":: Do you want to install steam (y/n)?: " steam
  if [[ "$steam" =~ [yY] ]]; then
    wget "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"
    sudo apt install ./steam.deb
  fi
}

install_vencord() {
  read -r -p ":: Do you want to install Vencord (y/n)?: " ven
  if [[ "$ven" =~ [yY] ]]; then
    bash "$repo/Vencord/VencordInstaller.sh"
    cp -r "$repo/Vencord/themes" "$HOME/.config/Vencord"
  fi
}

install_vscode() {
  read -r -p ":: Do you want to install VS Code (y/n)?: " vs
  if [[ "$vs" =~ [yY] ]]; then
    wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    sudo apt install ./vscode.deb
  fi
}

install_proton_mail() {
  read -r -p ":: Do you want to install proton mail (y/n)?: " mail
  if [[ "$mail" =~ [yY] ]]; then
    wget -O mail.rpm "https://proton.me/download/mail/linux/1.9.1/ProtonMail-desktop-beta.deb"
    sudo apt install ./mail.deb
  fi
}

MAGENTA='\033[0;35m'
NONE='\033[0m'

# Header
echo -e "${MAGENTA}"
cat <<"EOF"
   ____         __       ____
  /  _/__  ___ / /____ _/ / /__ ____
 _/ // _ \(_-</ __/ _ `/ / / -_) __/
/___/_//_/___/\__/\_,_/_/_/\__/_/

EOF

echo "PopOS Setup"
echo -e "${NONE}"
while true; do
    read -r -p ":: Do you want to start the installation now? (y/n): " yn
    case $yn in
        [Yy]*)
            echo ":: Installation started."
            echo
            break
            ;;
        [Nn]*)
            echo ":: Installation canceled."
            exit
            ;;
        *)
            echo ":: Please answer yes or no."
            ;;
    esac
done

sudo apt update && sudo apt upgrade

# Install required packages
echo "Installing required packages..." -- sleep 2
install_packages
install_discord
install_lazygit
install_neovim
install_fastfetch
install_ghcli
install_fzf
install_vencord
install_protonvpn
install_vscode
install_steam
install_proton_mail

echo "Starting setup now..." -- sleep 2
copy_config
detect_nvidia
configure_git
config_ufw

echo -e "${MAGENTA}"
cat <<"EOF"
    ____  __                        ____       __                __
   / __ \/ /__  ____ _________     / __ \___  / /_  ____  ____  / /_
  / /_/ / / _ \/ __ `/ ___/ _ \   / /_/ / _ \/ __ \/ __ \/ __ \/ __/
 / ____/ /  __/ /_/ (__  )  __/  / _, _/  __/ /_/ / /_/ / /_/ / /_
/_/   /_/\___/\__,_/____/\___/  /_/ |_|\___/_.___/\____/\____/\__/
EOF
echo "and thank you for choosing my config :)"
echo -e "${NONE}"
