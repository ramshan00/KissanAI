import sys

file_path = 'backend/antigravity/orchestrator.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove try/except logic around genai and remove `is_gemini_active`
import re

def clean_file(content):
    # Constructor changes
    content = re.sub(
        r'        self\.is_gemini_active = False\s*# Enable real Gemini integration.*?\n        if self\.api_key.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n',
        r'''        if not self.api_key or len(self.api_key.strip()) < 10:
            raise Exception("GEMINI_API_KEY is missing or invalid! Production mode requires real API integrations.")
        genai.configure(api_key=self.api_key)
        print("Google Antigravity Engine: Real Gemini API integration activated successfully!")\n''',
        content,
        flags=re.DOTALL
    )

    # Replace specific `if self.is_gemini_active:` with direct execution
    # First ZabaanAI
    content = re.sub(
        r'        if self\.is_gemini_active:\n            try:\n',
        r'        try:\n',
        content
    )
    
    # Remove else rule-based fallbacks for ZabaanAI
    # Since regex is risky, I'll just use string replacement for specific parts if possible, or build a parser.
    return content

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(clean_file(content))
