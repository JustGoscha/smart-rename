#!/bin/bash

set -e

echo "🚀 Smart Document Renamer - Installer"
echo "======================================"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    echo "This installer supports macOS and Linux only."
    exit 1
fi

echo "✅ Detected OS: $OS"

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ Python 3 is not installed."
    if [[ "$OS" == "macos" ]]; then
        echo "Please install Python 3: brew install python3"
    else
        echo "Please install Python 3: sudo apt-get install python3 python3-pip"
    fi
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Install system dependencies (poppler for pdftotext)
echo "📦 Installing system dependencies..."

if [[ "$OS" == "macos" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew not found. Please install Homebrew first:"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    
    if ! command -v pdftotext >/dev/null 2>&1; then
        echo "Installing poppler..."
        brew install poppler
    else
        echo "✅ poppler already installed"
    fi
    
elif [[ "$OS" == "linux" ]]; then
    if ! command -v pdftotext >/dev/null 2>&1; then
        echo "Installing poppler-utils..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y poppler-utils
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y poppler-utils
        else
            echo "❌ Could not install poppler-utils. Please install manually."
            exit 1
        fi
    else
        echo "✅ poppler-utils already installed"
    fi
fi

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
if command -v pip3 >/dev/null 2>&1; then
    pip3 install -r requirements.txt
elif command -v pip >/dev/null 2>&1; then
    pip install -r requirements.txt
else
    python3 -m pip install -r requirements.txt
fi

echo "✅ Python packages installed"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x smart-rename.sh ai_rename.py

echo "✅ Scripts are now executable"

# Set up API key
if [[ ! -f .env ]]; then
    echo ""
    echo "🔑 OpenAI API Key Setup"
    echo "----------------------"
    echo "You need an OpenAI API key to use this tool."
    echo ""
    read -p "Do you want to set up your API key now? (y/n): " setup_key
    
    if [[ $setup_key =~ ^[Yy]$ ]]; then
        echo ""
        echo "Get your API key from: https://platform.openai.com/api-keys"
        echo ""
        read -s -p "Enter your OpenAI API key: " api_key
        echo ""
        
        if [[ -n "$api_key" ]]; then
            echo "OPENAI_API_KEY=$api_key" > .env
            echo "✅ API key saved to .env file"
        else
            echo "⚠️  No API key entered. You can set it up later by creating a .env file with:"
            echo "OPENAI_API_KEY=your-api-key-here"
        fi
    else
        echo "⚠️  Remember to create a .env file with your OpenAI API key:"
        echo "echo 'OPENAI_API_KEY=your-api-key-here' > .env"
    fi
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "Usage:"
echo "  ./smart-rename.sh <directory> \"<instruction>\""
echo ""
echo "Example:"
echo "  ./smart-rename.sh ~/Downloads/ \"Rename payslips as Payslip_YYYY-MM.pdf\""
echo ""
echo "For more help, see README.md" 