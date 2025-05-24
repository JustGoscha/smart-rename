#!/usr/bin/env python3

import argparse
import os
import sys
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

    prompt = f"""Instruction: {args.instruction}
{examples}
Original filename: {args.original}

File content (excerpt):
{args.content}

Please provide only the new filename (with extension), nothing else."""

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

    filename = completion_text
    print(filename)

if __name__ == "__main__":
    main() 