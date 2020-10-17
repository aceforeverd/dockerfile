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

set -e
set -o nounset

cd "$(realpath "$(dirname "$0")")"

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

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
tar xf nvim-linux64.tar.gz
cd nvim-linux64
find . -type f -exec install -D -m 755 {} /usr/local/{} \; > /dev/null
cd ..
rm -rf nvim*

git clone https://github.com/aceforeverd/dotfiles.git .dotfiles
.dotfiles/setup.sh

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly -c rust-src

mkdir -p "$HOME/.ssh"

# setup pyenv and rustup in fish
fish -c "addpaths ~/.pyenv/bin;
    set -Ux PYENV_ROOT ~/.pyenv
    echo 'pyenv init - | source' > ~/.config/fish/config.fish
    pyenv install 3.9.0
    pyenv global 3.9.0
    pip3 install --upgrade pynvim msgpack vim-vint
    pip2 install --upgrade pynvim
    addpaths ~/.cargo/bin
    rustup completions fish > ~/.config/fish/completions/rustup.fish"

mkdir -p "$HOME/.config/nvim"
git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim"

source "$HOME/.nvm/nvm.sh"
nvm install lts/erbium
npm install -g neovim typescript yarn bash-language-server eslint
.config/nvim/scripts/setup.sh
