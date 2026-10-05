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

usage() {
  cat <<'EOF'
Usage: bootstrap-debian.sh [--os] [--home] [--new-user USER PASSWORD]

  --os                  system packages, LLVM, locale, and Neovim
  --home                dotfiles, n, Rust, and Neovim config for the current user
  --new-user USER PASS  create USER with fish as the login shell and sudo access

Options can be combined. They run in this order: --os, --new-user, --home.
With both --new-user and --home, home setup runs as the new user.
EOF
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "this step must be run as root" >&2
    exit 1
  fi
}

os_setup() {
  require_root

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

  curl -Lo nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  chmod +x nvim.appimage
  ./nvim.appimage --appimage-extract
  rm nvim.appimage
  cd squashfs-root/usr
  find . -type f -exec install -D -m 755 {} /usr/local/{} \; > /dev/null
  cd ../..
  rm -r squashfs-root
}

home_setup() {
  git clone https://github.com/aceforeverd/dotfiles.git "$HOME/.dotfiles"
  bash "$HOME/.dotfiles/setup.sh"

  # tj/n via n-install; -y installs the latest LTS Node.js. SHELL selects fish's init file.
  curl -L https://git.io/n-install | SHELL=/usr/bin/fish bash -s -- -y

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y -c rust-src
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
  mkdir -p "$HOME/.ssh" "$HOME/.config/fish/completions"
  rustup completions fish > "$HOME/.config/fish/completions/rustup.fish"
  cargo install git-delta ripgrep bat cargo-cache cargo-update fd-find du-dust zoxide lsd ast-grep just

  curl -sL https://git.io/fisher --create-dir -o "$HOME/.config/fish/functions/fisher.fish"

  fish -c "fish_user_paths_add ~/.cargo/bin"

  git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim"

  rm -rf "$HOME/.cache" "$HOME/.npm"
}

create_user() {
  local user=$1
  local password=$2

  require_root
  apt-get install -y sudo openssl
  useradd -m -U -s /usr/bin/fish "$user" -p "$(openssl passwd -crypt "$password")"
  usermod -aG sudo "$user"
}

DO_OS=0
DO_HOME=0
NEW_USER=
NEW_PASS=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --os)
      DO_OS=1
      shift
      ;;
    --home)
      DO_HOME=1
      shift
      ;;
    --new-user)
      if [[ $# -lt 3 ]]; then
        echo "--new-user requires USER and PASSWORD" >&2
        usage >&2
        exit 1
      fi
      NEW_USER=$2
      NEW_PASS=$3
      shift 3
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ $DO_OS -eq 0 && $DO_HOME -eq 0 && -z $NEW_USER ]]; then
  usage >&2
  exit 1
fi

cd "$(realpath "$(dirname "$0")")"
SCRIPT=$(realpath "$0")

if [[ $DO_OS -eq 1 ]]; then
  os_setup
fi

if [[ -n $NEW_USER ]]; then
  create_user "$NEW_USER" "$NEW_PASS"
fi

if [[ $DO_HOME -eq 1 ]]; then
  if [[ -n $NEW_USER ]]; then
    runuser -u "$NEW_USER" -- bash "$SCRIPT" --home
  else
    home_setup
  fi
fi
