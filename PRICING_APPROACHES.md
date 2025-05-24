# OpenAI Pricing: Programmatic Access Options

## The Reality Check ❌

**OpenAI does NOT provide an official API for current pricing.** This has been a heavily requested feature since 2022, but remains unavailable.

## Available Solutions ✅

### 1. Third-Party Libraries & APIs (Recommended)

#### **TokenCost by AgentOps** 🥇 (Our Choice)
- **GitHub**: `https://github.com/AgentOps-AI/tokencost`
- **Coverage**: 400+ LLMs including all OpenAI models
- **Format**: Python library
- **Cost**: Open source / Free
- **Reliability**: High (community maintained)
- **Installation**: `pip install tokencost`
- **Usage**: Direct cost calculation with actual token counts

```python
import tokencost

# Calculate costs directly
input_cost = tokencost.calculate_prompt_cost(prompt_tokens, "gpt-3.5-turbo")
output_cost = tokencost.calculate_completion_cost(completion_tokens, "gpt-3.5-turbo")
```

#### **Helicone LLM Cost API**
- **URL**: `https://www.helicone.ai/llm-cost`
- **Coverage**: 300+ AI models including all OpenAI models
- **Format**: JSON API
- **Cost**: Free tier available
- **Reliability**: High (actively maintained)
- **Example**: `GET https://www.helicone.ai/api/pricing/gpt-3.5-turbo`

### 2. Configuration with Periodic Updates (Fallback Approach)

```python
PRICING_CONFIG = {
    "gpt-3.5-turbo": {"input": 0.0015, "output": 0.002},
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
    # Update manually when OpenAI changes pricing
}
```

**Pros**:
- Fast and reliable
- No external dependencies
- Works offline

**Cons**:
- Requires manual updates
- May become outdated

### 3. Web Scraping (NOT Recommended)

While technically possible, scraping OpenAI's pricing page is:
- **Fragile**: Breaks when page structure changes
- **Unreliable**: May violate Terms of Service
- **Slow**: Adds latency to every request
- **Blocked**: Many sites implement anti-scraping measures

## Our Solution: TokenCost + Config Fallback 🎯

The `ai_rename.py` script uses **TokenCost** as the primary method:

1. **First**: Use TokenCost library for accurate, up-to-date pricing
2. **Fallback**: Use hardcoded configuration values if TokenCost fails
3. **Indicator**: Shows which source was used in the output

```python
def get_current_pricing(model_name, prompt_tokens=0, completion_tokens=0):
    try:
        import tokencost
        
        # Calculate actual costs using real token counts
        input_cost = tokencost.calculate_prompt_cost(prompt_tokens, model_name)
        output_cost = tokencost.calculate_completion_cost(completion_tokens, model_name)
        
        return {
            "input_cost": input_cost,
            "output_cost": output_cost,
            "total_cost": input_cost + output_cost,
            "source": "tokencost"
        }
    except Exception:
        # Fallback to config
        pricing = PRICING_CONFIG.get(model_name)
        input_cost = (prompt_tokens / 1000) * pricing["input"]
        output_cost = (completion_tokens / 1000) * pricing["output"]
        
        return {
            "input_cost": input_cost,
            "output_cost": output_cost,
            "total_cost": input_cost + output_cost,
            "source": "config_fallback"
        }
```

## Why TokenCost? 💡

1. **Open Source**: Transparent, community-driven
2. **Comprehensive**: 400+ LLMs supported
3. **Accurate**: Uses actual token counts for precise calculations
4. **No API Calls**: Works offline once installed
5. **Actively Maintained**: Regular updates by the community
6. **Free**: No API keys or usage limits

## Pricing Update Strategy 📋

### Option 1: TokenCost (Automated) ⭐
- Install: `pip install tokencost`
- Always current pricing
- No maintenance required
- Works with actual token counts

### Option 2: Manual Updates (Fallback)
- Check OpenAI pricing page monthly
- Update `PRICING_CONFIG` in code
- Commit changes to repository

### Option 3: Configuration File (Flexible)
- Store pricing in `pricing.json`
- Update file without code changes
- Version control pricing history

### Option 4: Environment Variables (DevOps)
- Set pricing via environment variables
- Different pricing for different environments
- Easy updates in deployment pipelines

## Monitoring Price Changes 📊

### Track costs over time:

```python
# Log costs to file for analysis
with open("cost_log.txt", "a") as f:
    f.write(f"{datetime.now()},{model},{tokens},{cost}\n")
```

### Monitor TokenCost updates:

```bash
# Check for tokencost updates
pip list --outdated | grep tokencost

# Update when new version available
pip install --upgrade tokencost
```

## Best Practices 💡

1. **Always show cost breakdown** to users
2. **Use actual token counts** for accurate pricing
3. **Set cost limits** to prevent unexpected charges
4. **Monitor usage trends** for budget planning
5. **Test with small batches** before large operations
6. **Keep TokenCost updated** for latest pricing

## Community Requests 📝

The OpenAI community has consistently requested:
- Official pricing API endpoint
- Cost estimation in `/v1/models` response
- Built-in cost tracking in API responses

Until OpenAI provides official pricing APIs, **TokenCost provides the best available solution** with accurate, up-to-date pricing for 400+ LLMs.

## Quick Reference 📚

| Approach | Accuracy | Reliability | Maintenance | Speed | Cost |
|----------|----------|-------------|-------------|-------|------|
| **TokenCost** | **Very High** | **High** | **Very Low** | **High** | **Free** |
| Helicone API | High | Medium | Low | Medium | Free Tier |
| Hardcoded Config | Medium | High | High | High | Free |
| Web Scraping | High | Low | Very High | Low | Free |

---

*Last updated: January 2025*
*Using: TokenCost library for automated pricing* 