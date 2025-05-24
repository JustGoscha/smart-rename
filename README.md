# Smart Document Renamer

An AI-powered tool that intelligently renames files by analyzing their content, not just their filenames. Transform messy file names into organized, consistent, and meaningful names using OpenAI's advanced language models.

🧠 **Goes beyond simple renaming** - understands document content, extracts metadata, translates languages, and maintains consistent patterns across your entire file collection.

## ⚡ Zero-Setup Usage

Just download and run! The script will automatically install everything it needs and use intelligent defaults:

```bash
git clone <repository-url>
cd docrenamer
./smart-rename.sh ~/Downloads/
```

**That's it!** The tool will:
- ✅ Detect your OS and install system dependencies
- ✅ Install Python packages automatically  
- ✅ Help you set up your OpenAI API key
- ✅ **Use smart defaults** to create chronologically sortable, content-based filenames
- ✅ Apply format: `YYYY-MM-DD_Type_Description.ext`

### 🧠 Smart Default Behavior

When no custom instruction is provided, the tool automatically:
- **📅 Extracts dates** from document content (any format)
- **🏷️ Identifies document types** (Invoice, Contract, Report, Meeting, Payslip, Receipt, etc.)
- **📝 Creates descriptive names** based on content analysis
- **⏰ Ensures chronological sorting** with YYYY-MM-DD prefix
- **🎯 Maintains consistency** across your entire file collection

**Example transformations:**
```
random_file_001.pdf → 2024-03-15_Invoice_ACME_Corp_Services.pdf
IMG_20240401.json → 2024-04-01_Employee_Salary_Information.json
untitled.md → 2024-03-15_Meeting_Notes_Q1_Planning.md
script.py → 2024-01-01_Script_Data_Processing_Sales_Analysis.py
```

### 🤖 Non-Interactive Mode

For automation and batch processing, use the `-y` or `--yes` flag:

```bash
./smart-rename.sh -y ~/Downloads/ "Rename documents with date format YYYY-MM"
```

This will:
- ✅ Automatically install missing dependencies
- ✅ Skip all confirmation prompts
- ✅ Perfect for scripts and automation
- ⚠️  Requires API key to be already set up (via `.env` file or environment variable)

## Features

- 📄 **PDF Support**: Extracts text from PDF files
- 📝 **Text File Support**: Reads plain text files
- 🤖 **AI-Powered**: Uses OpenAI GPT to generate smart, contextual filenames
- 🎯 **Custom Instructions**: Provide specific naming patterns and rules
- 🔄 **Consistency**: Maintains consistent naming patterns within each batch operation
- 🚀 **Auto-Install**: Installs dependencies automatically on first run
- 🔍 **Pre-flight Checks**: Validates all dependencies before running
- 📊 **Detailed Logging**: Shows progress and status for each file

### 🔄 Consistency Feature

The tool automatically maintains consistent naming patterns during each batch operation:

- **Learning from examples**: As files are renamed, the AI learns from previous renames in the same session
- **Pattern consistency**: If the first file gets renamed from `invoice_jan_2024.pdf` → `Invoice_2024-01.pdf`, subsequent files will follow the same pattern
- **In-memory tracking**: Examples are kept in memory during execution (not persisted to disk)
- **Smart limiting**: Only the last 10 examples are used to avoid token bloat while maintaining consistency

**Example workflow:**
```bash
# First file: report_march_2024.pdf → Report_2024-03.pdf
# Second file: report_april_2024.pdf → Report_2024-04.pdf  
# Third file: summary_may_2024.pdf → Summary_2024-05.pdf
# Pattern is established and maintained automatically!
```

## 🧠 AI Superpowers

What makes this tool special? It's not just renaming - it's intelligent document understanding:

- 🌍 **Multi-language**: Translate filenames to any language while organizing
- 🔍 **Content Analysis**: Reads PDF and text file content to understand context (not just filename)
- 📊 **Smart Categorization**: Automatically identifies document types (invoices, contracts, reports, etc.)
- 📅 **Date Extraction**: Finds dates in various formats within document text and standardizes them
- 💰 **Text-based Metadata**: Extracts vendor names, amounts, company names, and more from document content
- 🎨 **Creative Formatting**: Academic citations, expense tracking, legal documents, meeting notes
- 🧩 **Pattern Recognition**: Learns and maintains consistent naming patterns within each batch
- 🎯 **Context-Aware**: Understands the relationship between filename, document content, and desired format

### Real Examples of AI Intelligence:

```
📄 "2023_nov_payslip_final.pdf" (contains: "ACME Corp Salary Statement November 2023")
→ "ACME_Payslip_2023-11.pdf"

📄 "contract.pdf" (contains: "Service Agreement between XYZ Inc and John Smith dated March 15, 2024")
→ "Contract_XYZInc_JohnSmith_2024-03-15.pdf"

📄 "random_receipt.pdf" (contains: "Starbucks Receipt $4.50 Transaction Date: 01/15/2024")
→ "Expense_Starbucks_4.50_2024-01-15.pdf"

📄 "paper.pdf" (contains: "Machine Learning in Healthcare by Smith et al. 2023")
→ "Smith_2023_MachineLearningHealthcare.pdf"

📄 "notes.txt" (contains: "Meeting with Acme Corp on January 10th about Q1 planning")
→ "Meeting_AcmeCorp_2024-01-10.txt"
```

## Requirements

- **Python 3.6+** (must be installed manually)
- **macOS** (with Homebrew) or **Linux** (Ubuntu/Debian/RedHat)
- **OpenAI API Key** (script will help you set this up)

Everything else installs automatically!

## Alternative: Manual Setup

If you prefer the traditional approach or want to use the standalone installer:

```bash
git clone <repository-url>
cd docrenamer
./install.sh  # Optional standalone installer
```

## Usage Examples

### 🎯 Smart Defaults (Recommended)

**Just point and shoot - no instruction needed:**
```bash
./smart-rename.sh ~/Downloads/                    # Intelligent organization
./smart-rename.sh -y ./documents/                 # Same, but non-interactive
```
Results in chronologically sortable, content-based names like:
- `2024-03-15_Invoice_ACME_Corp_Services.pdf`
- `2024-01-15_Payslip_CompanyName_January.pdf`
- `2024-02-20_Meeting_Notes_Budget_Planning.md`
- `2023-12-01_Contract_Service_Agreement.pdf`

### 🌟 Custom Instructions (Advanced)

**Translate and organize chronologically:**
```bash
./smart-rename.sh ~/Downloads/ "Rename and translate files to Spanish and make chronological"
```

**Smart categorization by document type:**
```bash
./smart-rename.sh -y ./documents/ "Categorize by type: Invoice_YYYY-MM, Receipt_YYYY-MM, Contract_YYYY-MM"
```

**Expense tracking format:**
```bash
./smart-rename.sh -y ./receipts/ "Transform to expense tracking format: Expense_VENDOR_AMOUNT_DATE.pdf"
```

**Academic paper organization:**
```bash
./smart-rename.sh ./research/ "Academic format: AuthorLastName_YYYY_ShortTitle.pdf"
```

**Meeting notes and reports:**
```bash
./smart-rename.sh ./notes/ "Organize meeting notes as: Meeting_COMPANY_YYYY-MM-DD.txt"
```

**Legal documents:**
```bash
./smart-rename.sh ./legal/ "Organize as: DocumentType_PartyName_YYYY-MM.pdf"
```

### 📋 Traditional Examples

**Rename payslips:**
```bash
./smart-rename.sh ~/Downloads/payslips/ "Most files here are payslips, please rename all files like this: Deed_Payslip_YYYY-MM.pdf"
```

**Rename invoices:**
```bash
./smart-rename.sh ./invoices/ "These are invoices, rename them as Invoice_CompanyName_YYYY-MM-DD.pdf"
```

**Mixed document types:**
```bash
./smart-rename.sh ./documents/ "Rename files based on content: contracts as Contract_YYYY-MM.pdf, reports as Report_Topic_YYYY.pdf, other files with descriptive names"
```

**Non-interactive batch processing:**
```bash
# For automation/scripts - no prompts, auto-confirm everything
./smart-rename.sh -y ~/Downloads/batch/ "Rename documents with consistent YYYY-MM format"

# Can also use --yes
./smart-rename.sh --yes ./reports/ "Rename reports as Report_YYYY-MM-DD.pdf"
```

## File Types Supported

- **PDF files** (`.pdf`) - Text is extracted using `pdftotext`
- **All text-based files** - Content is read directly, including:
  - **Plain text**: `.txt`, `.log`, `.conf`, `.ini`
  - **Markup/Documentation**: `.md`, `.html`, `.xml`, `.rst`
  - **Data formats**: `.csv`, `.json`, `.yaml`, `.yml`
  - **Code files**: `.py`, `.js`, `.sh`, `.sql`, `.php`, `.rb`, `.pl`
  - **Configuration**: `.cfg`, `.toml`, `.properties`
  - **And many more** - automatically detected using MIME type analysis

## How It Works

1. **Auto-setup**: Installs missing dependencies on first run
2. **Pre-flight checks**: Validates all dependencies and API key
3. **File discovery**: Scans the target directory for supported files
4. **Content extraction**: Extracts text from PDFs or reads text files
5. **AI processing**: Sends content + instruction to OpenAI GPT-3.5-turbo
6. **Smart renaming**: Renames files based on AI suggestions

## Configuration

### AI Model Settings

Edit `ai_rename.py` to customize:
- **Model**: Change `gpt-3.5-turbo` to `gpt-4` for better results (higher cost)
- **Temperature**: Adjust creativity (0.0 = deterministic, 1.0 = creative)
- **Max tokens**: Increase for longer filenames

### Text Extraction Limits

- **PDFs**: First 2 pages only (for cost efficiency)
- **Text files**: First 2000 characters

## Troubleshooting

### Missing Python 3
The only thing you need to install manually is Python 3:

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get install python3

# Check installation
python3 --version
```

### Other Issues
Just re-run the script! It will detect and fix most dependency issues automatically:

```bash
./smart-rename.sh ~/Downloads/ "your instruction"
```

### OpenAI API Errors
- Get your API key at: https://platform.openai.com/api-keys
- The script will help you set it up on first run
- Make sure your OpenAI account has credits

### Non-Interactive Mode Issues
If using `-y` or `--yes` flag:
- **API key must be set up first**: Export `OPENAI_API_KEY` or create `.env` file
- **Dependencies install automatically**: System packages may require `sudo` password
- **No prompts means no manual API key setup**: Set up the key before running

```bash
# Set up API key for non-interactive use
echo 'OPENAI_API_KEY=your-api-key-here' > .env

# Then run non-interactively
./smart-rename.sh -y ~/Downloads/ "Your instruction"
```

## Cost Considerations

- Uses **GPT-3.5-turbo** (cost-effective)
- Processes only **first 2 pages** of PDFs
- Limits response to **30 tokens** max
- **Conservative cost estimation** with 30% safety buffer
- Approximate cost: **~$0.001-0.005 per file**
- **Estimates are intentionally high** - actual costs typically lower

### Cost Estimation Features
- ✅ **Accounts for consistency examples** in token calculation
- ✅ **Conservative 2.5 chars/token ratio** (vs optimistic 3.5)
- ✅ **20% estimation safety margin** for variations
- ✅ **Additional 30% cost buffer** to prevent surprises
- ✅ **Real-time pricing** when tokencost library available

## Limitations

- Only processes PDF and TXT files currently
- Requires internet connection for AI processing
- Processing speed depends on file size and API response time

## Contributing

Feel free to submit issues and pull requests to improve the tool!

## License

This project is open source. Please add your preferred license. 