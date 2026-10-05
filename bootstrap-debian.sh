#!/bin/bash
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
# Debian 13 dropped software-properties-common, libncurses5-dev, and libncursesw5-dev.
# gnupg is required by llvm.sh; libncurses-dev replaces the ncurses 5 transitional -dev packages.
apt install -y build-essential git bash-completion fish zsh tmux vim sudo \
        curl wget lsb-release gnupg python3-pip procps \
        apt-transport-https ca-certificates universal-ctags global locales \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python3-openssl libtool-bin unzip gettext
bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
apt clean
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x nvim.appimage
./nvim.appimage --appimage-extract
rm nvim.appimage
cd squashfs-root/usr
find . -type f -exec install -D -m 755 {} /usr/local/{} \; > /dev/null
cd ../..
rm -r squashfs-root

git clone https://github.com/aceforeverd/dotfiles.git "$HOME/.dotfiles"
bash "$HOME/.dotfiles/setup.sh"

# tj/n via n-install; -y installs the latest LTS Node.js. SHELL selects fish's init file.
curl -L https://git.io/n-install | SHELL=/usr/bin/fish bash -s -- -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -c rust-src
rustup completions fish > ~/.config/fish/completions/rustup.fish
cargo install git-delta ripgrep bat cargo-cache cargo-update fd-find du-dust zoxide lsd ast-grep just

mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.config/fish/completions"
curl -sL https://git.io/fisher --create-dir -o ~/.config/fish/functions/fisher.fish

fish -c "fish_user_paths_add ~/.cargo/bin"

git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim"

rm -rf "$HOME/.cache" "$HOME/.npm"
