#!/usr/bin/env python3

import argparse
import os
import sys
import re
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# Pricing configuration with fallback to hardcoded values
PRICING_CONFIG = {
    "gpt-3.5-turbo": {"input": 0.0015, "output": 0.002},
    "gpt-4": {"input": 0.03, "output": 0.06},
    "gpt-4-turbo": {"input": 0.01, "output": 0.03},
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
    # Add more models as needed
}

def get_current_pricing(model_name, prompt_tokens=0, completion_tokens=0, prompt_text=None, completion_text=None):
    """
    Get current pricing using tokencost library with fallback to config
    """
    try:
        import tokencost
        
        # Use tokencost with actual text - this is the proper way to use it
        if prompt_text is not None and completion_text is not None:
            input_cost = float(tokencost.calculate_prompt_cost(prompt_text, model_name))
            output_cost = float(tokencost.calculate_completion_cost(completion_text, model_name))
            
            return {
                "input": input_cost / (prompt_tokens / 1000) if prompt_tokens > 0 else 0,
                "output": output_cost / (completion_tokens / 1000) if completion_tokens > 0 else 0,
                "input_cost": input_cost,
                "output_cost": output_cost,
                "total_cost": input_cost + output_cost,
                "source": "tokencost"
            }
        else:
            # If we don't have text, use tokencost's model data but calculate manually
            # This is more reliable than trying to pass token counts to tokencost
            pricing = PRICING_CONFIG.get(model_name, PRICING_CONFIG.get("gpt-4o-mini"))
            input_cost = (prompt_tokens / 1000) * pricing["input"]
            output_cost = (completion_tokens / 1000) * pricing["output"]
            
            return {
                "input": pricing["input"],
                "output": pricing["output"],
                "input_cost": input_cost,
                "output_cost": output_cost,
                "total_cost": input_cost + output_cost,
                "source": "config_with_tokencost_available"
            }
    except (ImportError, Exception) as e:
        if not isinstance(e, ImportError):
            # Only show non-import errors (since import errors are expected if tokencost not installed)
            print(f"  ⚠️  TokenCost error: {e}", file=sys.stderr)
        
        # Fallback to hardcoded pricing
        pricing = PRICING_CONFIG.get(model_name, PRICING_CONFIG.get("gpt-4o-mini"))
        input_cost = (prompt_tokens / 1000) * pricing["input"]
        output_cost = (completion_tokens / 1000) * pricing["output"]
        
        return {
            "input": pricing["input"],
            "output": pricing["output"],
            "input_cost": input_cost,
            "output_cost": output_cost,
            "total_cost": input_cost + output_cost,
            "source": "config_fallback"
        }

def format_examples(examples_str):
    """
    Format the examples string for the prompt
    """
    if not examples_str or examples_str.strip() == "":
        return ""
    
    examples_text = "\nPrevious rename examples for consistency:\n"
    for line in examples_str.strip().split('\n'):
        if line.strip() and " -> " in line:
            examples_text += f"  {line.strip()}\n"
    
    return examples_text

def sanitize_filename(filename):
    """
    Sanitize AI-generated filename to prevent injection attacks and ensure filesystem compatibility.
    
    NOTE: This function now handles ONLY the filename part without extension.
    The extension is preserved and added separately.
    
    Security measures:
    - Remove path traversal attempts (../, ..\, /, \)
    - Strip dangerous shell metacharacters 
    - Prevent reserved names (Windows: CON, PRN, AUX, etc.)
    - Limit length to reasonable bounds
    - Remove leading dots (hidden files) unless explicitly allowed
    - Preserve spaces for readability (normalized to single spaces)
    """
    if not filename or not isinstance(filename, str):
        return "unnamed_file"
    
    # Strip whitespace from ends
    filename = filename.strip()
    
    # Remove any path components (security: prevent directory traversal)
    filename = os.path.basename(filename)
    
    # Remove or replace path separators that might have survived basename
    filename = filename.replace('/', '_').replace('\\', '_')
    
    # Remove dangerous shell metacharacters and control characters
    # Keep alphanumeric, spaces, dots, hyphens, underscores, parentheses, brackets
    filename = re.sub(r'[^\w\s\.\-\(\)\[\]]+', '_', filename)
    
    # Normalize multiple consecutive spaces to single spaces, and multiple underscores to single underscores
    filename = re.sub(r'\s+', ' ', filename)  # Multiple spaces -> single space
    filename = re.sub(r'_+', '_', filename)   # Multiple underscores -> single underscore
    
    # Remove leading dots to prevent hidden files (security measure)
    filename = filename.lstrip('.')
    
    # If filename is empty after sanitization, provide default
    if not filename:
        return "unnamed_file"
    
    # Check for Windows reserved names (case insensitive)
    # Since we're not dealing with extensions here, check the entire name
    name_upper = filename.upper()
    reserved_names = {
        'CON', 'PRN', 'AUX', 'NUL',
        'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
        'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    }
    
    if name_upper in reserved_names:
        filename = f"file_{filename}"
    
    # Limit total length (leave room for extension to be added later)
    if len(filename) > 150:  # Conservative limit to leave room for extension
        filename = filename[:150]
    
    # Final check: ensure filename doesn't start/end with problematic characters
    filename = filename.strip('._- ')
    
    # If still empty, return default
    if not filename:
        return "unnamed_file"
    
    return filename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--instruction', required=True)
    parser.add_argument('--content', required=True)
    parser.add_argument('--original', required=True)
    parser.add_argument('--examples', default='', help='Previous rename examples for consistency (newline separated)')
    args = parser.parse_args()

    client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

    # Format examples if provided
    examples = format_examples(args.examples)

    # Extract the original file extension to preserve it
    original_name, original_ext = os.path.splitext(args.original)
    if not original_ext:
        original_ext = ".txt"  # Default if no extension found

    prompt = f"""You are a file renaming assistant. Follow the user's instruction EXACTLY, including:
- Use the language that makes most sense, unless specified otherwise
- Use the EXACT format specified in the instruction
- Return ONLY the filename part without any extension

Instruction: {args.instruction}
{examples}
Original filename: {args.original}

File content (excerpt):
{args.content}

IMPORTANT: Follow the instruction precisely. Use the same language and format as specified. 
Return ONLY the new filename WITHOUT any extension - we will add the extension automatically.
Do not include .pdf, .txt, .json or any other extension in your response."""

    MODEL = "gpt-4o-mini"

    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=30,
        temperature=0.2,
    )

    # Extract token usage information
    usage = response.usage
    prompt_tokens = usage.prompt_tokens
    completion_tokens = usage.completion_tokens
    total_tokens = usage.total_tokens

    # Get current pricing using tokencost
    completion_text = response.choices[0].message.content.strip()
    pricing = get_current_pricing(MODEL, prompt_tokens, completion_tokens, prompt, completion_text)

    # Print usage stats to stderr so they don't interfere with the filename output
    print(f"📊 Token Usage:", file=sys.stderr)
    print(f"  Input tokens:  {prompt_tokens:,}", file=sys.stderr)
    print(f"  Output tokens: {completion_tokens:,}", file=sys.stderr)
    print(f"  Total tokens:  {total_tokens:,}", file=sys.stderr)
    print(f"💰 Cost (via {pricing['source']}):", file=sys.stderr)
    print(f"  Input cost:    ${pricing['input_cost']:.6f}", file=sys.stderr)
    print(f"  Output cost:   ${pricing['output_cost']:.6f}", file=sys.stderr)
    print(f"  Total cost:    ${pricing['total_cost']:.6f}", file=sys.stderr)

    # Sanitize the filename for security
    original_filename = completion_text
    sanitized_filename = sanitize_filename(original_filename)
    
    # Add the original extension back to the filename
    final_filename = sanitized_filename + original_ext
    
    # Log security sanitization if filename was modified
    if original_filename != sanitized_filename:
        print(f"🔒 Security: Filename sanitized for safety", file=sys.stderr)
        print(f"  Original:  {original_filename}", file=sys.stderr)
        print(f"  Sanitized: {sanitized_filename}", file=sys.stderr)
    
    # Log extension preservation
    print(f"📎 Extension: Added original extension {original_ext}", file=sys.stderr)

    print(final_filename)

if __name__ == "__main__":
    main() 