#!/bin/bash
# bootstrap.sh
# Copyright (c) 2020 Ace <teapot@aceforeverd.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -eE
set -o nounset

cd "$(realpath "$(dirname "$0")")"

get_latest_release_version() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

apt update && apt full-upgrade -y
apt install -y build-essential git bash-completion fish zsh tmux vim sudo \
        curl wget lsb-release software-properties-common python-pip procps \
        apt-transport-https ca-certificates universal-ctags global locales \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python-openssl
bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
apt clean
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

NVM_VER=$(get_latest_release_version nvm-sh/nvm)
PY3_VER=3.9.1

curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
chmod +x nvim.appimage
./nvim.appimage --appimage-extract
rm nvim.appimage
cd squashfs-root/usr
find . -type f -exec install -D -m 755 {} /usr/local/{} \; > /dev/null
cd ../..
rm -rf squashfs

git clone https://github.com/aceforeverd/dotfiles.git "$HOME/.dotfiles"
bash "$HOME/.dotfiles/setup.sh"

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VER/install.sh" | bash

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly -c rust-src

mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.config/fish/completions"
curl -sL https://git.io/fisher --create-dir -o ~/.config/fish/functions/fisher.fish

# setup pyenv and rustup in fish
fish -c "fisher update
    fish_user_paths_add ~/.pyenv/bin
    set -Ux PYENV_ROOT ~/.pyenv
    echo 'pyenv init - | source' >> ~/.config/fish/config.fish"

fish -c "pyenv install $PY3_VER
    pyenv global $PY3_VER
    python3 -m pip install --upgrade pynvim msgpack vim-vint
    pip2 install --upgrade pynvim
    fish_user_paths_add ~/.cargo/bin
    rustup completions fish > ~/.config/fish/completions/rustup.fish"

git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim"

fish -c "nvm install lts/fermium; npm install -g neovim bash-language-server"

bash "$HOME/.config/nvim/scripts/setup.sh"

rm -rf "$HOME/.cache" "$HOME/.npm"
