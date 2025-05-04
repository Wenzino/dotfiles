# 🛠️ dotfiles

Minha coleção pessoal de dotfiles e configurações para restaurar rapidamente meu ambiente de desenvolvimento Linux.  
Gerenciado com um repositório `bare` Git e um script de automação.

---

## ✨ Conteúdo

- Alias para terminal (`.bashrc`, `.zshrc`, etc)
- Configurações do Git (`.gitconfig`)
- Atalhos personalizados e aliases
- Configurações de VS Code, Warp, Cursor
- Setup de desenvolvimento com Flutter e Android Studio
- Script automatizado de instalação e restauração

---

## 🚀 Restauração em nova máquina

Clone os dotfiles como um repositório `bare`:

```bash
git clone --bare https://github.com/Wenzino/dotfiles.git $HOME/.dotfiles
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
config checkout
config config --local status.showUntrackedFiles no
