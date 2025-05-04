#!/bin/bash

echo "🔐 Gerando nova chave SSH..."

read -p "Digite seu email do GitHub: " email

# Geração da chave SSH
ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""

# Iniciar ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "✅ Chave SSH gerada!"

# Mostrar chave pública
echo "🔑 Sua chave pública (adicione ao GitHub):"
cat ~/.ssh/id_ed25519.pub

echo ""
echo "👉 Vá para: https://github.com/settings/keys e adicione a chave acima."
read -p "Pressione ENTER para continuar depois de adicionar a chave no GitHub..."

# Instalar apps essenciais
echo "🛠️ Instalando ferramentas essenciais..."

sudo dnf update -y
sudo dnf install -y curl git zsh unzip wget

# Warp (via RPM)
echo "📦 Instalando Warp..."
wget https://app.warp.dev/download?package=rpm -O warp.rpm
sudo dnf install -y ./warp.rpm
rm warp.rpm

# VS Code
echo "📦 Instalando VS Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install -y code

# Cursor (manual)
echo "📦 Por favor instale Cursor manualmente: https://cursor.sh"

# Reativar shell config
if [ -f ~/.zshrc ]; then
    echo "🔄 Atualizando .zshrc"
    source ~/.zshrc
elif [ -f ~/.bashrc ]; then
    echo "🔄 Atualizando .bashrc"
    source ~/.bashrc
fi

echo ""
echo "✅ Setup finalizado com sucesso!"
echo "📌 Lembre-se de instalar o Flutter SDK e Android Studio manualmente."
