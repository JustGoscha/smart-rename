# Smart Document Renamer

Transform messy filenames into organized, meaningful names using AI that actually reads your documents.

## The Problem
Your downloads folder is chaos: `IMG_20240401.pdf`, `untitled.md`, `random_file_001.pdf`. You spend forever hunting for files because the names tell you nothing about the content.

## The Solution
AI that reads your documents and creates smart, chronological filenames based on actual content:

```
random_file_001.pdf → 2024-03-15_Invoice_ACME_Corp_Services.pdf
IMG_20240401.json → 2024-04-01_Payslip_TechCorp_April.json
untitled.md → 2024-03-15_Meeting_Notes_Q1_Planning.md
```

## Quick Start

```bash
git clone https://github.com/JustGoscha/smart-rename.git
cd smart-rename
./smart-rename.sh ~/Downloads/
```

That's it! The script auto-installs everything and uses intelligent defaults.

## Installation

**Requirements:** Python 3 (everything else installs automatically)

```bash
# macOS
brew install python3

# Ubuntu/Debian  
sudo apt-get install python3
```

**API Key:** Get one from [OpenAI](https://platform.openai.com/api-keys) - the script will help you set it up.

## Usage

### Smart Defaults (Recommended)
```bash
./smart-rename.sh ~/Downloads/                    # Intelligent organization
./smart-rename.sh -y ./documents/                 # Non-interactive mode
```

### Custom Instructions
```bash
# Expense tracking
./smart-rename.sh ./receipts/ "Format: Expense_VENDOR_AMOUNT_DATE"

# Academic papers
./smart-rename.sh ./research/ "Format: AuthorLastName_YYYY_ShortTitle"

# Meeting notes
./smart-rename.sh ./notes/ "Format: Meeting_COMPANY_YYYY-MM-DD"

# Translate to Spanish
./smart-rename.sh ~/docs/ "Rename in Spanish with chronological format"
```

## What Makes It Smart

🧠 **Content Analysis** - Reads PDFs and text files, not just filenames  
📅 **Date Extraction** - Finds dates in any format within documents  
🏷️ **Type Detection** - Identifies invoices, contracts, reports, payslips automatically  
🌍 **Multi-language** - Translate and organize in any language  
💰 **Metadata Extraction** - Pulls vendor names, amounts, company names from content  
🔄 **Consistency** - Maintains patterns across your entire batch  

## Real Examples

**Invoice Processing:**
```
"final_invoice_copy.pdf" (content: "ACME Corp Invoice #1234 March 15, 2024")
→ "2024-03-15_Invoice_ACME_Corp_1234.pdf"
```

**Expense Tracking:**
```
"receipt.pdf" (content: "Starbucks $4.50 01/15/2024")  
→ "2024-01-15_Expense_Starbucks_4.50.pdf"
```

**Academic Papers:**
```
"paper.pdf" (content: "Machine Learning in Healthcare by Smith et al. 2023")
→ "Smith_2023_MachineLearning_Healthcare.pdf"
```

## Supported Files

- **PDFs** (text extraction)
- **Text files** (.txt, .md, .csv, .json, .py, .js, .sh, etc.)

## Security

Enterprise-grade protection against injection attacks:
- Path traversal blocking (`../../../etc/passwd` → safe)
- Command injection prevention (`file;rm -rf /` → safe)  
- Multi-layer sanitization and validation

## Cost

~$0.001-0.005 per file using GPT-4o-mini. Conservative estimates with 30% buffer - actual costs typically lower.

## License

MIT License - see [LICENSE](LICENSE) file for details. 
