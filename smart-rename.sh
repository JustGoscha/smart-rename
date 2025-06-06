#!/bin/bash

# Usage: smart-rename.sh [-y|--yes] <directory> [instruction]

set -e

# Smart default instruction for general use cases
DEFAULT_INSTRUCTION="Analyze the document content (not just the filename) to create descriptive, well-organized filenames. Use chronological sorting when dates are relevant.

CRITICAL: Base the rename on CONTENT analysis, not the original filename. The original filename may be meaningless.

Format Guidelines:
- IF a meaningful date exists in content: YYYY-MM-DD_[ActualType]_Description
- IF no relevant date or date doesn't make sense: [ActualType]_Description
- Use underscores (_) as separators, no spaces or special characters
- DO NOT include file extensions - return only the filename part

IMPORTANT: Replace [ActualType] with the REAL document type you identify from content:
Invoice, Contract, Receipt, Payslip, Meeting, Report, CV, Ticket, Statement, Letter, Config, Script, Guide, Manual, etc.

Requirements:
1. Extract dates from document text ONLY when relevant (invoices, reports, meeting notes, etc.)
2. Identify the ACTUAL document type from content - never use 'DocumentType' literally
3. Extract key metadata: company names, vendor names, amounts, people names, topics, project names
4. Create concise but descriptive names that capture the document's purpose
5. Keep total length reasonable (under 100 characters)
6. Use common sense - not every file needs a date
7. Return ONLY the filename without any extension

Examples of correct transformations:
- Invoice with date → 2024-03-15_Invoice_ACME_Corp_Services
- Meeting notes with date → 2024-01-10_Meeting_Notes_Q1_Planning
- Ticket with price → 2024-03-27_Ticket_Sea_Las_Perlas_Georg_Graf_3_Passengers_98.00
- Configuration file → Config_Database_Settings
- Code script → Script_Data_Processing_Sales
- Generic document → Report_Market_Analysis
- CV/Resume → CV_John_Smith_Software_Engineer
- Letter → Letter_Customer_Service_Response

NEVER use 'DocumentType' as literal text - always replace with actual type like Letter, CV, Invoice, etc.
Return ONLY the filename part - no extensions like .pdf, .txt, .json etc."

# Parse arguments
AUTO_CONFIRM=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes)
      AUTO_CONFIRM=true
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      echo "Usage: $0 [-y|--yes] <directory> [instruction]"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

DIR="$1"
INSTRUCTION="$2"

if [[ -z "$DIR" ]]; then
  echo "Usage: $0 [-y|--yes] <directory> [instruction]"
  echo ""
  echo "Options:"
  echo "  -y, --yes    Non-interactive mode, automatically confirm all prompts"
  echo ""
  echo "Description:"
  echo "  Intelligently renames files based on their content analysis."
  echo "  If no instruction is provided, uses smart defaults for general organization."
  echo ""
  echo "Default Behavior (when no instruction given):"
  echo "  • Creates chronologically sortable filenames: YYYY-MM-DD_Type_Description"
  echo "  • Extracts dates from document content"
  echo "  • Identifies document types (Invoice, Contract, Report, Meeting, etc.)"
  echo "  • Generates concise but descriptive names"
  echo ""
  echo "Examples:"
  echo "  $0 ~/Downloads/                    # Uses smart defaults"
  echo "  $0 -y ./documents/                 # Uses smart defaults, no prompts"
  echo "  $0 ~/Downloads/ \"Rename and translate files to Spanish and make chronological\""
  echo "  $0 -y ./documents/ \"Categorize by type: Invoice_YYYY-MM, Receipt_YYYY-MM, Contract_YYYY-MM\""
  echo "  $0 ./notes/ \"Organize meeting notes as: Meeting_COMPANY_YYYY-MM-DD.md\""
  echo "  $0 -y ./receipts/ \"Transform to expense tracking format: Expense_VENDOR_AMOUNT_DATE.pdf\""
  echo "  $0 ./research/ \"Academic format: AuthorLastName_YYYY_ShortTitle.pdf\""
  echo "  $0 ./code/ \"Organize code files by project: ProjectName_YYYY-MM_filename.ext\""
  exit 1
fi

# Use default instruction if none provided
if [[ -z "$INSTRUCTION" ]]; then
  INSTRUCTION="$DEFAULT_INSTRUCTION"
  echo "ℹ️  No instruction provided, using smart defaults for general organization"
  echo ""
fi

# Auto-installer function
install_dependencies() {
    echo "🚀 Smart Document Renamer - Auto Setup"
    echo "======================================"
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        echo "❌ Unsupported OS: $OSTYPE"
        echo "This tool supports macOS and Linux only."
        exit 1
    fi
    
    echo "✅ Detected OS: $OS"
    
    # Install system dependencies (poppler for pdftotext)
    if ! command -v pdftotext >/dev/null 2>&1; then
        echo "📦 Installing system dependencies (pdftotext)..."
        
        if [[ "$OS" == "macos" ]]; then
            if ! command -v brew >/dev/null 2>&1; then
                echo "❌ Homebrew not found. Please install Homebrew first:"
                echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                exit 1
            fi
            brew install poppler
            
        elif [[ "$OS" == "linux" ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y poppler-utils
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y poppler-utils
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y poppler-utils
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm poppler
            else
                echo "❌ Could not install poppler-utils. Please install manually."
                exit 1
            fi
        fi
        echo "✅ pdftotext installed"
    fi
    
    # Check and install pip if needed
    echo "🐍 Checking Python and pip installation..."
    
    # Function to check if pip is working
    check_pip_working() {
        # Helper function to run commands with timeout (if available)
        run_with_timeout() {
            local cmd="$1"
            if command -v timeout >/dev/null 2>&1; then
                timeout 10s $cmd
            else
                # Fallback without timeout
                $cmd
            fi
        }
        
        echo "  Checking for pip3..." >&2
        if command -v pip3 >/dev/null 2>&1; then
            echo "  Found pip3, testing functionality..." >&2
            if run_with_timeout "pip3 --version" >/dev/null 2>&1; then
                echo "pip3"
                return 0
            else
                echo "  pip3 found but not working or timed out" >&2
            fi
        else
            echo "  pip3 not found" >&2
        fi
        
        echo "  Checking for pip..." >&2
        if command -v pip >/dev/null 2>&1; then
            echo "  Found pip, testing functionality..." >&2
            if run_with_timeout "pip --version" >/dev/null 2>&1; then
                echo "pip"
                return 0
            else
                echo "  pip found but not working or timed out" >&2
            fi
        else
            echo "  pip not found" >&2
        fi
        
        echo "  Checking for python3 -m pip..." >&2
        if run_with_timeout "python3 -m pip --version" >/dev/null 2>&1; then
            echo "python3 -m pip"
            return 0
        else
            echo "  python3 -m pip not working or timed out" >&2
        fi
        
        echo "  No working pip found" >&2
        return 1
    }
    
    # Try to find working pip
    echo "  Attempting to detect working pip..." >&2
    PIP_CMD=$(check_pip_working 2>&1 | tail -1)
    PIP_AVAILABLE=$?
    
    echo "  Detection result: PIP_CMD='$PIP_CMD', exit code=$PIP_AVAILABLE" >&2
    
    if [[ $PIP_AVAILABLE -ne 0 || "$PIP_CMD" == *"No working pip found"* ]]; then
        echo "⚠️  pip is not installed or not working. Installing pip..."
        
        if [[ "$OS" == "linux" ]]; then
            # Try different package managers
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing pip via apt..."
                sudo apt-get update && sudo apt-get install -y python3-pip
            elif command -v yum >/dev/null 2>&1; then
                echo "Installing pip via yum..."
                sudo yum install -y python3-pip
            elif command -v dnf >/dev/null 2>&1; then
                echo "Installing pip via dnf..."
                sudo dnf install -y python3-pip
            elif command -v pacman >/dev/null 2>&1; then
                echo "Installing pip via pacman..."
                sudo pacman -S --noconfirm python-pip
            elif command -v zypper >/dev/null 2>&1; then
                echo "Installing pip via zypper..."
                sudo zypper install -y python3-pip
            else
                echo "❌ Could not detect package manager. Trying to install pip via get-pip.py..."
                # Fallback: download and install pip manually
                if command -v curl >/dev/null 2>&1; then
                    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                    python3 get-pip.py --user
                    rm -f get-pip.py
                elif command -v wget >/dev/null 2>&1; then
                    wget https://bootstrap.pypa.io/get-pip.py
                    python3 get-pip.py --user
                    rm -f get-pip.py
                else
                    echo "❌ Could not install pip. Please install pip manually:"
                    echo "  Option 1: Use your system package manager"
                    echo "  Option 2: Download and run get-pip.py from https://bootstrap.pypa.io/get-pip.py"
                    exit 1
                fi
            fi
        elif [[ "$OS" == "macos" ]]; then
            echo "Installing pip via python3..."
            python3 -m ensurepip --upgrade
        fi
        
        # Re-check pip availability
        PIP_CMD=$(check_pip_working)
        PIP_AVAILABLE=$?
        
        if [[ $PIP_AVAILABLE -ne 0 ]]; then
            echo "❌ Failed to install or setup pip. Please install pip manually and try again."
            echo ""
            echo "Manual installation options:"
            echo "  Ubuntu/Debian: sudo apt install python3-pip"
            echo "  CentOS/RHEL:   sudo yum install python3-pip"
            echo "  Fedora:        sudo dnf install python3-pip"
            echo "  Arch:          sudo pacman -S python-pip"
            echo "  openSUSE:      sudo zypper install python3-pip"
            exit 1
        fi
        
        echo "✅ pip installed successfully"
    else
        echo "✅ pip is available: $PIP_CMD"
    fi
    
    # Install Python dependencies
    echo "📦 Installing Python dependencies..."
    
    # Function to install a package with multiple fallback strategies
    install_package() {
        local package="$1"
        echo "  Installing $package..."
        
        # Strategy 1: Try system packages first (Ubuntu/Debian)
        if [[ "$OS" == "linux" ]] && command -v apt-get >/dev/null 2>&1; then
            local sys_package=""
            case "$package" in
                "openai"*) sys_package="python3-openai" ;;
                "python-dotenv"*) sys_package="python3-dotenv" ;;
                "tokencost"*) sys_package="" ;; # Not available in repos
            esac
            
            if [[ -n "$sys_package" ]]; then
                echo "    Trying system package: $sys_package"
                if sudo apt-get install -y "$sys_package" >/dev/null 2>&1; then
                    echo "  ✅ $package installed via system package"
                    return 0
                else
                    echo "    System package not available, trying pip..."
                fi
            fi
        fi
        
        # Strategy 2: Try user installation with various approaches
        local pip_cmd=""
        if [[ "$PIP_CMD" == "pip3" ]]; then
            pip_cmd="pip3"
        elif [[ "$PIP_CMD" == "pip" ]]; then
            pip_cmd="pip"
        else
            pip_cmd="python3 -m pip"
        fi
        
        # Try --user first
        echo "    Trying user installation..."
        if $pip_cmd install --user "$package" >/dev/null 2>&1; then
            echo "  ✅ $package installed via user pip"
            return 0
        fi
        
        # Strategy 3: Create local virtual environment for this script
        local venv_dir=".smart-rename-venv"
        if [[ ! -d "$venv_dir" ]]; then
            echo "    Creating local virtual environment..."
            if python3 -m venv "$venv_dir" >/dev/null 2>&1; then
                echo "    ✅ Virtual environment created"
            else
                echo "    ❌ Failed to create virtual environment"
                return 1
            fi
        fi
        
        # Install in virtual environment
        echo "    Installing in virtual environment..."
        if "$venv_dir/bin/pip" install "$package" >/dev/null 2>&1; then
            echo "  ✅ $package installed in virtual environment"
            
            # Create a wrapper script that uses the venv
            if [[ ! -f "ai_rename_venv.py" ]]; then
                cat > ai_rename_venv.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess

# Get the directory of this script
script_dir = os.path.dirname(os.path.abspath(__file__))
venv_python = os.path.join(script_dir, '.smart-rename-venv', 'bin', 'python')
ai_rename_script = os.path.join(script_dir, 'ai_rename.py')

# If venv exists, use it; otherwise fall back to system python
if os.path.exists(venv_python):
    # Execute the original script with venv python
    subprocess.execv(venv_python, [venv_python, ai_rename_script] + sys.argv[1:])
else:
    # Fall back to system python
    subprocess.execv(sys.executable, [sys.executable, ai_rename_script] + sys.argv[1:])
EOF
                chmod +x ai_rename_venv.py
            fi
            return 0
        fi
        
        # Strategy 4: Last resort - break system packages (with warning)
        echo "    ⚠️  Trying --break-system-packages (last resort)..."
        if $pip_cmd install --break-system-packages "$package" >/dev/null 2>&1; then
            echo "  ⚠️  $package installed with --break-system-packages"
            echo "    Note: This may affect system stability"
            return 0
        fi
        
        echo "  ❌ Failed to install $package with all methods"
        return 1
    }
    
    # Install packages individually for better error handling
    if [[ -f requirements.txt ]]; then
        echo "Installing from requirements.txt..."
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" == \#* ]] && continue
            install_package "$package" || echo "⚠️  Continuing despite $package installation failure..."
        done < requirements.txt
    else
        # Fallback to individual packages
        echo "Installing individual packages..."
        install_package "openai" || echo "⚠️  Continuing despite openai installation failure..."
        install_package "python-dotenv" || echo "⚠️  Continuing despite python-dotenv installation failure..."
        install_package "tokencost" || echo "⚠️  Continuing despite tokencost installation failure..."
    fi
    
    echo "✅ Python package installation complete"
    
    # Make scripts executable
    chmod +x smart-rename.sh ai_rename.py 2>/dev/null || true
    
    # Set up API key if missing
    if [[ ! -f .env && -z "$OPENAI_API_KEY" ]]; then
        echo ""
        echo "🔑 OpenAI API Key Setup"
        echo "----------------------"
        echo "You need an OpenAI API key to use this tool."
        echo "Get your API key from: https://platform.openai.com/api-keys"
        echo ""
        
        if [[ "$AUTO_CONFIRM" == "true" ]]; then
            echo "❌ Running in non-interactive mode, but no API key found."
            echo "Please set up your API key first:"
            echo "  export OPENAI_API_KEY=your-api-key-here"
            echo "  OR"
            echo "  echo 'OPENAI_API_KEY=your-api-key-here' > .env"
            exit 1
        fi
        
        read -p "Do you want to set up your API key now? (y/n): " setup_key
        
        if [[ $setup_key =~ ^[Yy]$ ]]; then
            echo ""
            read -s -p "Enter your OpenAI API key: " api_key
            echo ""
            
            if [[ -n "$api_key" ]]; then
                echo "OPENAI_API_KEY=$api_key" > .env
                # Mask the key for confirmation (show first 2 and last 4 chars)
                masked_key="${api_key:0:2}****${api_key: -4}"
                echo "✅ API key saved to .env file as: ${masked_key}"
            else
                echo "⚠️  No API key entered. You can set it up later by creating a .env file."
                exit 1
            fi
        else
            echo "⚠️  You need to set up your API key before using this tool."
            echo "Create a .env file with: OPENAI_API_KEY=your-api-key-here"
            exit 1
        fi
    fi
    
    echo ""
    echo "🎉 Setup Complete! Continuing with file renaming..."
    echo ""
}

# Function to check if a file is text-based
is_text_file() {
  local file="$1"
  local mime_type
  
  # Use file command to get MIME type
  mime_type=$(file --mime-type "$file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
  
  # Check if it's a text-based MIME type
  case "$mime_type" in
    text/*)
      return 0  # It's a text file
      ;;
    application/json|\
    application/xml|\
    application/javascript|\
    application/x-sh|\
    application/x-shellscript|\
    application/x-python|\
    application/x-perl|\
    application/x-ruby|\
    application/x-php|\
    application/sql|\
    application/x-httpd-php|\
    application/x-yaml|\
    application/x-ini|\
    application/x-desktop|\
    application/x-wine-extension-ini)
      return 0  # These are text-based even with application/* MIME type
      ;;
    application/pdf)
      return 0  # PDF files (we handle these specially)
      ;;
    *)
      # Additional check: try to detect if file contains mostly text
      if command -v file >/dev/null 2>&1; then
        file_description=$(file "$file" 2>/dev/null)
        if [[ "$file_description" =~ (ASCII|UTF-8|text|script|source|JSON|XML|HTML|CSV) ]]; then
          return 0
        fi
      fi
      return 1  # Probably binary
      ;;
  esac
}

# Function to extract content from any supported file
extract_file_content() {
  local file="$1"
  local ext="${file##*.}"
  local content=""
  
  # Convert extension to lowercase for comparison
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  
  if [[ "$ext" == "pdf" ]]; then
    echo "  Extracting text from PDF..."
    content=$(pdftotext -f 1 -l 2 "$file" - 2>/dev/null || echo "")
  elif is_text_file "$file"; then
    echo "  Reading text-based file..."
    # Read first 2000 characters for consistency with current behavior
    content=$(head -c 2000 "$file" 2>/dev/null || echo "")
  else
    echo "  ⚠️  File type not supported for content extraction"
    return 1
  fi
  
  echo "$content"
  return 0
}

# Function to safely move file to trash
move_to_trash() {
  local file="$1"
  local filename=$(basename "$file")
  
  # Try platform-specific trash commands
  if command -v trash >/dev/null 2>&1; then
    # macOS with trash command installed
    trash "$file"
    return 0
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS fallback - move to Trash
    mv "$file" ~/.Trash/
    return 0
  elif command -v trash-cli >/dev/null 2>&1; then
    # Linux with trash-cli installed
    trash-put "$file"
    return 0
  elif [[ -d ~/.local/share/Trash/files ]]; then
    # Linux fallback - move to user trash
    mv "$file" ~/.local/share/Trash/files/
    return 0
  else
    # Create local backup folder as last resort
    local backup_dir="$DIR/.docrenamer_duplicates_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$file" "$backup_dir/"
    echo "  📁 Moved to local backup: $backup_dir/$filename" >&2
    return 0
  fi
}

# Function to safely rename a file without overwriting existing files
safe_rename() {
  local source_file="$1"
  local target_dir="$2"
  local new_basename="$3"
  
  local target_path="$target_dir/$new_basename"
  local final_name="$new_basename"
  local counter=1
  
  # Check if target already exists
  if [[ -e "$target_path" ]]; then
    # First check if the files are identical (byte-for-byte)
    if cmp -s "$source_file" "$target_path" 2>/dev/null; then
      # Files are identical - move source to trash since target already exists
      move_to_trash "$source_file"
      echo "$final_name|DUPLICATE"  # Special return to indicate duplicate removal
      return 0
    fi
    
    # Files are different, so we need to generate a unique name
    while [[ -e "$target_path" ]]; do
      # Extract name and extension
      local name_part="${new_basename%.*}"
      local ext_part=""
      
      if [[ "$new_basename" == *.* ]]; then
        ext_part=".${new_basename##*.}"
      fi
      
      # Generate new name with counter
      final_name="${name_part}_${counter}${ext_part}"
      target_path="$target_dir/$final_name"
      
      # Check if this numbered version is also identical to source
      if [[ -e "$target_path" ]] && cmp -s "$source_file" "$target_path" 2>/dev/null; then
        # Found an identical file with a number - move source to trash
        move_to_trash "$source_file"
        echo "$final_name|DUPLICATE"  # Return the name of the existing identical file
        return 0
      fi
      
      counter=$((counter + 1))
      
      # Safety check to prevent infinite loop
      if [[ $counter -gt 3 ]]; then
        echo "❌ Could not generate unique filename after 1000 attempts"
        return 1
      fi
    done
  fi
  
  # Perform the rename (no conflicts or duplicates found)
  mv "$source_file" "$target_path"
  
  # Return the final name used
  echo "$final_name|RENAMED"
  return 0
}

# Function to display progress bar/indicator
show_progress() {
  local current="$1"
  local total="$2"
  local filename="$3"
  local status="$4"  # "processing" or "completed" or "skipped" or "error" or "duplicate" or "unchanged"
  
  local percentage=$((current * 100 / total))
  
  case "$status" in
    "processing")
      printf "\r🔃 [%d/%d] (%d%%) Processing: %s" "$current" "$total" "$percentage" "$filename"
      ;;
    "completed")
      printf "\r✅ [%d/%d] (%d%%) Completed: %s\n" "$current" "$total" "$percentage" "$filename"
      ;;
    "duplicate")
      printf "\r♻️  [%d/%d] (%d%%) Duplicate removed: %s\n" "$current" "$total" "$percentage" "$filename"
      ;;
    "unchanged")
      printf "\rℹ️  [%d/%d] (%d%%) No change needed: %s\n" "$current" "$total" "$percentage" "$filename"
      ;;
    "skipped")
      printf "\r⚠️  [%d/%d] (%d%%) Skipped: %s\n" "$current" "$total" "$percentage" "$filename"
      ;;
    "error")
      printf "\r❌ [%d/%d] (%d%%) Error: %s\n" "$current" "$total" "$percentage" "$filename"
      ;;
  esac
}

# Pre-flight checks with auto-install option
missing_deps=false

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check for pdftotext
if ! command -v pdftotext >/dev/null 2>&1; then
    echo "⚠️  pdftotext is not installed."
    missing_deps=true
fi

# Check for Python packages
python_packages_missing=false

# Check each required package individually
if ! python3 -c "import openai" 2>/dev/null; then
    echo "⚠️  Python package 'openai' is not installed."
    python_packages_missing=true
fi

if ! python3 -c "import dotenv" 2>/dev/null; then
    echo "⚠️  Python package 'python-dotenv' is not installed."
    python_packages_missing=true
fi

if ! python3 -c "import tokencost" 2>/dev/null; then
    echo "⚠️  Python package 'tokencost' is not installed."
    python_packages_missing=true
fi

# Check for pip (needed to install Python packages)
pip_missing=false
if ! command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then
    # Also check if python3 -m pip works
    if ! python3 -m pip --version >/dev/null 2>&1; then
        echo "⚠️  pip is not installed (needed to install Python packages)."
        pip_missing=true
    fi
fi

if [[ "$python_packages_missing" == "true" || "$pip_missing" == "true" ]]; then
    missing_deps=true
fi

# Check for API key
api_key_available=false

# Check if API key is in environment
if [[ -n "$OPENAI_API_KEY" ]]; then
    api_key_available=true
fi

# Check if API key is in .env file
if [[ -f .env ]]; then
    if grep -q "^OPENAI_API_KEY=" .env && grep "^OPENAI_API_KEY=" .env | cut -d= -f2 | grep -q .; then
        api_key_available=true
    fi
fi

# If dependencies are missing (excluding API key), offer to install
if [[ "$missing_deps" == "true" ]]; then
    echo ""
    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        echo "🔧 Auto-installing missing dependencies (non-interactive mode)..."
        install_now="y"
    else
        read -p "Would you like to install missing dependencies automatically? (y/n): " install_now
    fi
    
    if [[ $install_now =~ ^[Yy]$ ]]; then
        install_dependencies
    else
        echo "❌ Cannot proceed without required dependencies."
        echo "Run with missing dependencies to see this installer again."
        exit 1
    fi
    # After install, re-check API key and prompt if still missing
    api_key_available=false
    if [[ -n "$OPENAI_API_KEY" ]]; then
        api_key_available=true
    fi
    if [[ -f .env ]]; then
        if grep -q "^OPENAI_API_KEY=" .env && grep "^OPENAI_API_KEY=" .env | cut -d= -f2 | grep -q .; then
            api_key_available=true
        fi
    fi
fi

# If dependencies are present but API key is missing, prompt for API key setup only
if [[ "$api_key_available" == "false" ]]; then
    echo ""
    echo "🔑 OpenAI API Key Setup"
    echo "----------------------"
    echo "You need an OpenAI API key to use this tool."
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""
    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        echo "❌ Running in non-interactive mode, but no API key found."
        echo "Please set up your API key first:"
        echo "  export OPENAI_API_KEY=your-api-key-here"
        echo "  OR"
        echo "  echo 'OPENAI_API_KEY=your-api-key-here' > .env"
        exit 1
    fi
    read -p "Do you want to set up your API key now? (y/n): " setup_key
    if [[ $setup_key =~ ^[Yy]$ ]]; then
        echo ""
        read -s -p "Enter your OpenAI API key: " api_key
        echo ""
        if [[ -n "$api_key" ]]; then
            echo "OPENAI_API_KEY=$api_key" > .env
            masked_key="${api_key:0:2}****${api_key: -4}"
            echo "✅ API key saved to .env file as: ${masked_key}"
        else
            echo "⚠️  No API key entered. You can set it up later by creating a .env file."
            exit 1
        fi
    else
        echo "⚠️  You need to set up your API key before using this tool."
        echo "Create a .env file with: OPENAI_API_KEY=your-api-key-here"
        exit 1
    fi
fi

# Cost estimation phase
echo ""
echo "🔍 Scanning files for cost estimation..."

# Initialize counters and tracking
total_files=0
total_estimated_tokens=0
estimated_total_cost=0
actual_total_cost=0
files_processed=0
files_to_process=()

# File type counters - using simple approach for better compatibility
total_supported=0
total_unsupported=0
supported_extensions=""
unsupported_extensions=""

# Function to count extension occurrences in a string
count_extension() {
  local ext="$1"
  local ext_list="$2"
  echo "$ext_list" | tr ' ' '\n' | grep -c "^$ext$" 2>/dev/null || echo "0"
}

# Shell-level filename validation (additional security layer)
validate_shell_filename() {
  local filename="$1"
  
  # Basic checks for shell safety (defense in depth)
  # Note: Main sanitization happens in Python, this is just extra protection
  
  # Check for extremely dangerous patterns
  if [[ "$filename" == *".."* ]] || [[ "$filename" == *"/"* ]] || [[ "$filename" == *"\\"* ]]; then
    echo "INVALID" >&2
    return 1
  fi
  
  # Check for shell metacharacters that survived Python sanitization
  if [[ "$filename" == *";"* ]] || [[ "$filename" == *"|"* ]] || [[ "$filename" == *"&"* ]] || [[ "$filename" == *\`* ]] || [[ "$filename" == *'$'* ]]; then
    echo "INVALID" >&2
    return 1
  fi
  
  # Check for empty or whitespace-only names
  if [[ -z "${filename// }" ]]; then
    echo "INVALID" >&2
    return 1
  fi
  
  # If all checks pass
  echo "VALID" >&2
  return 0
}

# Function to update the live summary display
update_summary_display() {
  local current_cost="$1"
  
  printf "\r🔍 Scanning: %d files" "$total_supported"
  
  # Show file type breakdown if we have extensions
  if [[ -n "$supported_extensions" ]]; then
    # Get unique extensions and their counts
    local unique_exts=$(echo "$supported_extensions" | tr ' ' '\n' | sort -u)
    local type_summary=""
    
    for ext in $unique_exts; do
      local count=$(count_extension "$ext" "$supported_extensions")
      if [[ -n "$type_summary" ]]; then
        type_summary="$type_summary, *.$ext ($count)"
      else
        type_summary="*.$ext ($count)"
      fi
    done
    
    printf " - %s" "$type_summary"
  fi
  
  printf " | Tokens: %s" "$(printf "%'d" $total_estimated_tokens)"
  
  if [[ -n "$current_cost" && "$current_cost" != "0" ]]; then
    printf " | Cost: \$%s" "$current_cost"
  fi
}

for FILE in "$DIR"/*; do
  EXT="${FILE##*.}"
  BASENAME="$(basename "$FILE")"
  
  # Only process files (not directories)
  if [[ -f "$FILE" ]]; then
    # Check if file type is supported (PDF or any text-based file)
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    if [[ "$EXT_LOWER" == "pdf" ]] || is_text_file "$FILE"; then
      files_to_process+=("$FILE")
      
      # Count supported file types
      supported_extensions="$supported_extensions $EXT_LOWER"
      total_supported=$((total_supported + 1))
      
      # Extract content for token estimation
      CONTENT=""
      if [[ "$EXT_LOWER" == "pdf" ]]; then
        CONTENT=$(pdftotext -f 1 -l 2 "$FILE" - 2>/dev/null || echo "")
      elif is_text_file "$FILE"; then
        CONTENT=$(head -c 2000 "$FILE" 2>/dev/null || echo "")
      fi
      
      # Conservative token estimation with safety margins
      # Build the full prompt structure that will actually be sent
      EXAMPLES_OVERHEAD=""
      if [[ $total_files -gt 0 ]]; then
        # Estimate examples overhead (assume ~10 examples of ~30 chars each)
        EXAMPLES_OVERHEAD="

Previous rename examples for consistency:
  example1.pdf -> Example_2024-01.pdf
  example2.pdf -> Example_2024-02.pdf
  example3.pdf -> Example_2024-03.pdf
  example4.pdf -> Example_2024-04.pdf
  example5.pdf -> Example_2024-05.pdf
  example6.pdf -> Example_2024-06.pdf
  example7.pdf -> Example_2024-07.pdf
  example8.pdf -> Example_2024-08.pdf
  example9.pdf -> Example_2024-09.pdf
  example10.pdf -> Example_2024-10.pdf
"
      fi
      
      FULL_PROMPT="Instruction: $INSTRUCTION
      
Previously renamed files: $EXAMPLES_OVERHEAD

Original filename: $BASENAME

File content (excerpt):
$CONTENT

Please provide only the new filename (with extension), nothing else."
      
      # Conservative token estimation:
      # - Use 2.5 chars per token (more conservative than 3.5)
      # - Add 20% safety margin for variations
      # - Account for tokenizer overhead
      CHAR_COUNT=${#FULL_PROMPT}
      BASE_INPUT_TOKENS=$((CHAR_COUNT * 100 / 250))  # 2.5 chars per token
      SAFETY_MARGIN_TOKENS=$((BASE_INPUT_TOKENS * 20 / 100))  # 20% safety margin
      ESTIMATED_INPUT_TOKENS=$((BASE_INPUT_TOKENS + SAFETY_MARGIN_TOKENS))
      
      # Conservative output estimation (up to 25 tokens for complex filenames)
      ESTIMATED_OUTPUT_TOKENS=25
      
      total_estimated_tokens=$((total_estimated_tokens + ESTIMATED_INPUT_TOKENS + ESTIMATED_OUTPUT_TOKENS))
      total_files=$((total_files + 1))
      
      # Quick cost estimate for live display
      if command -v bc >/dev/null 2>&1; then
        input_cost=$(echo "scale=4; $total_estimated_tokens * 0.9 * 0.0015 / 1000" | bc -l 2>/dev/null || echo "0")
        output_cost=$(echo "scale=4; $total_estimated_tokens * 0.1 * 0.002 / 1000" | bc -l 2>/dev/null || echo "0")
        live_cost=$(echo "scale=4; ($input_cost + $output_cost) * 1.3" | bc -l 2>/dev/null || echo "0")
        update_summary_display "$live_cost"
      else
        update_summary_display ""
      fi
    else
      # Count unsupported file types
      unsupported_extensions="$unsupported_extensions $EXT_LOWER"
      total_unsupported=$((total_unsupported + 1))
    fi
  fi
done

# Clear the progress line and show final summary
printf "\r\033[K"  # Clear entire line
echo "📊 Scan Complete"
echo "==============="

# Show supported files summary
echo -n "Total files: $total_supported"
if [[ $total_supported -gt 0 && -n "$supported_extensions" ]]; then
  echo -n " - "
  
  # Get unique extensions and their counts for final display
  unique_exts=$(echo "$supported_extensions" | tr ' ' '\n' | sort -u)
  file_type_summary=""
  
  for ext in $unique_exts; do
    count=$(count_extension "$ext" "$supported_extensions")
    if [[ -n "$file_type_summary" ]]; then
      file_type_summary="$file_type_summary, *.$ext ($count)"
    else
      file_type_summary="*.$ext ($count)"
    fi
  done
  
  echo "$file_type_summary"
else
  echo ""
fi

# Show unsupported files summary only if there are any
if [[ $total_unsupported -gt 0 ]]; then
  echo -n "Unsupported files: $total_unsupported ("
  
  # Get unique unsupported extensions
  unique_unsupported=$(echo "$unsupported_extensions" | tr ' ' '\n' | sort -u | tr '\n' ', ' | sed 's/,$//')
  echo "$unique_unsupported)"
fi

printf "Estimated tokens: %'d\n" $total_estimated_tokens

if [[ $total_files -eq 0 ]]; then
  echo ""
  echo "❌ No supported files found in $DIR"
  echo "Supported formats: PDF files and all text-based files"
  echo "Text-based files include: .txt, .md, .csv, .json, .xml, .html, .log, .py, .js, .sh, etc."
  exit 1
fi

# Calculate estimated cost using current pricing
echo ""

# Get pricing information
TEMP_COST_FILE=$(mktemp)
TEMP_ERROR_FILE=$(mktemp)

python3 -c "
import sys
sys.path.append('.')
from ai_rename import get_current_pricing

# Estimate roughly 90% input, 10% output tokens
input_tokens = int($total_estimated_tokens * 0.9)
output_tokens = int($total_estimated_tokens * 0.1)

pricing = get_current_pricing('gpt-4o-mini', input_tokens, output_tokens)

# Add additional 30% safety buffer to final estimate
safety_multiplier = 1.3
buffered_cost = pricing['total_cost'] * safety_multiplier

print(f'ESTIMATED_COST:{buffered_cost:.4f}')
print(f'COST_BREAKDOWN:Input: \${pricing[\"input_cost\"]:.4f} | Output: \${pricing[\"output_cost\"]:.4f} | Buffer (30%): \${buffered_cost:.4f}')
print(f'SOURCE:{pricing[\"source\"]}')
" > "$TEMP_COST_FILE" 2> "$TEMP_ERROR_FILE"
PYTHON_EXIT_CODE=$?

if [[ $PYTHON_EXIT_CODE -eq 0 && -s "$TEMP_COST_FILE" ]]; then
  estimated_total_cost=$(grep "ESTIMATED_COST:" "$TEMP_COST_FILE" | cut -d: -f2)
  cost_breakdown=$(grep "COST_BREAKDOWN:" "$TEMP_COST_FILE" | cut -d: -f2-)
  cost_source=$(grep "SOURCE:" "$TEMP_COST_FILE" | cut -d: -f2)
  
  printf "Estimated cost: \$%s (%s)\n" "$estimated_total_cost" "$cost_source"
  echo "$cost_breakdown"
else
  # Show any Python errors
  if [[ -s "$TEMP_ERROR_FILE" ]]; then
    echo "⚠️  Error getting pricing information:"
    cat "$TEMP_ERROR_FILE" | sed 's/^/   /'
  fi
  
  # Fallback calculation
  if command -v bc >/dev/null 2>&1; then
    INPUT_COST=$(echo "scale=6; $total_estimated_tokens * 0.9 * 0.0015 / 1000" | bc -l)
    OUTPUT_COST=$(echo "scale=6; $total_estimated_tokens * 0.1 * 0.002 / 1000" | bc -l)
    BASE_COST=$(echo "scale=6; $INPUT_COST + $OUTPUT_COST" | bc -l)
    estimated_total_cost=$(echo "scale=6; $BASE_COST * 1.3" | bc -l)  # Add 30% safety buffer
    printf "Estimated cost: \$%.4f (fallback pricing)\n" "$estimated_total_cost"
    printf "Input: \$%.4f | Output: \$%.4f | Buffer (30%%): \$%.4f\n" "$INPUT_COST" "$OUTPUT_COST" "$estimated_total_cost"
  else
    estimated_total_cost="0.003"  # Increased from 0.002
    echo "Estimated cost: \$$estimated_total_cost (basic estimate)"
  fi
fi

rm -f "$TEMP_COST_FILE" "$TEMP_ERROR_FILE"

echo ""
echo "💡 Cost includes 30% safety buffer - actual costs typically lower"
echo ""

# Ask for user confirmation
if [[ "$AUTO_CONFIRM" == "false" ]]; then
    read -p "Do you want to proceed with renaming? (y/n): " confirm
    echo ""
else
    confirm="y"
fi

if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "❌ Operation cancelled by user."
  exit 0
fi

echo "🚀 Proceeding with file renaming..."
echo ""

# Initialize rename examples for consistency (in-memory tracking)
RENAME_EXAMPLES=""
MAX_EXAMPLES=10
current_file_num=0

# Initialize operation counters
files_renamed=0
files_unchanged=0
duplicates_removed=0
files_skipped=0
files_errored=0

# Main processing starts here
for FILE in "${files_to_process[@]}"; do
  EXT="${FILE##*.}"
  BASENAME="$(basename "$FILE")"
  current_file_num=$((current_file_num + 1))
  
  # Show processing status
  show_progress "$current_file_num" "$total_files" "$BASENAME" "processing"
  
  # Extract content using the new function
  CONTENT=$(extract_file_content "$FILE" 2>/dev/null)
  EXTRACT_STATUS=$?
  
  if [[ $EXTRACT_STATUS -ne 0 ]]; then
    show_progress "$current_file_num" "$total_files" "$BASENAME (content extraction failed)" "skipped"
    files_skipped=$((files_skipped + 1))
    continue
  fi
  
  # Create temporary files for stdout and stderr
  TEMP_OUT=$(mktemp)
  TEMP_ERR=$(mktemp)
  
  # Run the command with separated outputs
  if [[ -f "ai_rename_venv.py" ]]; then
    # Use virtual environment wrapper if available
    python3 ai_rename_venv.py --instruction "$INSTRUCTION" --content "$CONTENT" --original "$BASENAME" --examples "$RENAME_EXAMPLES" > "$TEMP_OUT" 2> "$TEMP_ERR"
  else
    # Use regular Python
    python3 ai_rename.py --instruction "$INSTRUCTION" --content "$CONTENT" --original "$BASENAME" --examples "$RENAME_EXAMPLES" > "$TEMP_OUT" 2> "$TEMP_ERR"
  fi
  STATUS=$?
  
  # Read the outputs
  NEWNAME=$(cat "$TEMP_OUT")
  COST_INFO=$(cat "$TEMP_ERR")
  
  # Clean up temp files
  rm -f "$TEMP_OUT" "$TEMP_ERR"
  
  if [[ $STATUS -ne 0 ]]; then
    show_progress "$current_file_num" "$total_files" "$BASENAME (AI processing failed)" "error"
    # Show error details on next line
    echo "    Error details: $COST_INFO"
    files_errored=$((files_errored + 1))
    continue
  fi
  
  # Additional shell-level validation (defense in depth)
  if [[ -n "$NEWNAME" ]]; then
    validate_shell_filename "$NEWNAME" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      show_progress "$current_file_num" "$total_files" "$BASENAME (filename validation failed)" "error"
      echo "    ⚠️  Filename '$NEWNAME' failed shell validation (security protection)" >&2
      files_errored=$((files_errored + 1))
      continue
    fi
  fi
  
  if [[ -n "$NEWNAME" && "$NEWNAME" != "$BASENAME" ]]; then
    # Use safe rename to avoid overwrites
    RENAME_RESULT=$(safe_rename "$FILE" "$DIR" "$NEWNAME")
    RENAME_STATUS=$?
    
    if [[ $RENAME_STATUS -eq 0 ]]; then
      # Parse the result: "filename|ACTION"
      FINAL_NAME=$(echo "$RENAME_RESULT" | cut -d'|' -f1)
      ACTION=$(echo "$RENAME_RESULT" | cut -d'|' -f2)
      
      case "$ACTION" in
        "DUPLICATE")
          show_progress "$current_file_num" "$total_files" "$BASENAME → $FINAL_NAME" "duplicate"
          duplicates_removed=$((duplicates_removed + 1))
          ;;
        "RENAMED")
          if [[ "$FINAL_NAME" != "$NEWNAME" ]]; then
            # Name was changed to avoid conflict
            show_progress "$current_file_num" "$total_files" "$BASENAME → $FINAL_NAME (adjusted to avoid conflict)" "completed"
          else
            show_progress "$current_file_num" "$total_files" "$BASENAME → $NEWNAME" "completed"
          fi
          files_renamed=$((files_renamed + 1))
          ;;
      esac
      
      # Add this rename to examples for consistency in future renames
      if [[ -n "$RENAME_EXAMPLES" ]]; then
        RENAME_EXAMPLES="$RENAME_EXAMPLES"$'\n'"$BASENAME -> $NEWNAME"
      else
        RENAME_EXAMPLES="$BASENAME -> $NEWNAME"
      fi
      
      # Keep only the last MAX_EXAMPLES entries to avoid token bloat
      example_count=$(echo "$RENAME_EXAMPLES" | wc -l)
      if [[ $example_count -gt $MAX_EXAMPLES ]]; then
        RENAME_EXAMPLES=$(echo "$RENAME_EXAMPLES" | tail -n $MAX_EXAMPLES)
      fi
    else
      show_progress "$current_file_num" "$total_files" "$BASENAME (rename failed)" "error"
      files_errored=$((files_errored + 1))
    fi
  else
    show_progress "$current_file_num" "$total_files" "$BASENAME" "unchanged"
    files_unchanged=$((files_unchanged + 1))
  fi
  
  # Extract actual cost for tracking (but don't show it in progress - keep it clean)
  if [[ -n "$COST_INFO" ]]; then
    ACTUAL_COST=$(echo "$COST_INFO" | grep "Total cost:" | sed 's/.*\$\([0-9.]*\).*/\1/' | head -1)
    if [[ -n "$ACTUAL_COST" && "$ACTUAL_COST" != "$COST_INFO" ]]; then
      actual_total_cost=$(echo "scale=6; $actual_total_cost + $ACTUAL_COST" | bc -l 2>/dev/null || echo "$actual_total_cost")
    fi
  fi
done

# Clear the progress line and add some space
echo ""
echo ""

echo "✅ Processing complete!"
echo ""

# Define colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📊 Final Summary"
echo "==============="
echo "Files scanned: $total_files"
echo ""

# Detailed operation breakdown
echo "📋 Operations Performed:"
echo "  ✅ Renamed files: $files_renamed"
echo "  ♻️ Duplicates moved to trash: $duplicates_removed"
echo "  ℹ️ Files unchanged: $files_unchanged"

if [[ $files_skipped -gt 0 ]]; then
  echo "  ⚠️ Files skipped: $files_skipped"
fi

if [[ $files_errored -gt 0 ]]; then
  echo "  ❌ Files with errors: $files_errored"
fi

# Calculate total processed for verification
files_processed=$((files_renamed + duplicates_removed + files_unchanged))
echo ""
echo "Total files processed: $files_processed"
echo "Estimated tokens: $total_estimated_tokens"
echo ""

# Cost comparison section
echo "💰 Cost Analysis"
echo "---------------"

if [[ -n "$estimated_total_cost" && -n "$actual_total_cost" ]]; then
  # Calculate accuracy
  if command -v bc >/dev/null 2>&1; then
    # Calculate percentage difference: ((actual - estimated) / estimated) * 100
    if [[ $(echo "$estimated_total_cost > 0" | bc -l) -eq 1 ]]; then
      cost_diff=$(echo "scale=6; $actual_total_cost - $estimated_total_cost" | bc -l)
      percent_diff=$(echo "scale=2; ($cost_diff / $estimated_total_cost) * 100" | bc -l)
      abs_percent_diff=$(echo "$percent_diff" | sed 's/-//')
      
      echo "Estimated cost: \$$estimated_total_cost"
      echo "Actual cost:    \$$actual_total_cost"
      echo "Difference:     \$$cost_diff"
      
      # Color-coded accuracy assessment
      if [[ $(echo "$percent_diff >= -10 && $percent_diff <= 10" | bc -l) -eq 1 ]]; then
        echo -e "Accuracy: ${GREEN}Excellent${NC} (${percent_diff}% difference)"
      elif [[ $(echo "$abs_percent_diff <= 25" | bc -l) -eq 1 ]]; then
        echo -e "Accuracy: ${YELLOW}Good${NC} (${percent_diff}% difference)"
      else
        if [[ $(echo "$percent_diff > 0" | bc -l) -eq 1 ]]; then
          echo -e "Accuracy: ${RED}Over budget${NC} (+${percent_diff}% higher than estimated)"
        else
          echo -e "Accuracy: ${BLUE}Under budget${NC} (${percent_diff}% lower than estimated)"
        fi
      fi
    else
      echo "Estimated cost: \$0.000000"
      echo "Actual cost:    \$$actual_total_cost"
      echo -e "Note: ${YELLOW}No cost estimate available${NC}"
    fi
  else
    echo "Estimated cost: \$$estimated_total_cost"
    echo "Actual cost:    \$$actual_total_cost"
    echo "Note: Install 'bc' for detailed cost comparison"
  fi
else
  echo "Cost tracking incomplete - some data missing"
fi

echo ""
echo "💡 Tips:"
echo "   • Costs may vary based on actual content complexity"
echo "   • Token estimates are approximations (~4 chars per token)"
echo "   • Pricing is fetched in real-time when possible" 