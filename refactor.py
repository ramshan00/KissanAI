import os
import glob

def refactor_dir(base_dir):
    pattern = os.path.join(base_dir, "backend", "**", "*.py")
    files = glob.glob(pattern, recursive=True)
    target = 'is_postgres = os.getenv("DATABASE_URL") and os.getenv("DATABASE_URL").startswith("postgresql://")'
    replacement = 'from backend.database import IS_POSTGRES; is_postgres = IS_POSTGRES'
    
    for filepath in files:
        if "database.py" in filepath:
            continue
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        if target in content:
            print(f"Refactoring {filepath}")
            # Also clean up the 'import os' if it's on the line above it
            content = content.replace("import os\n    " + target, "from backend.database import IS_POSTGRES\n    is_postgres = IS_POSTGRES")
            content = content.replace("import os\n        " + target, "from backend.database import IS_POSTGRES\n        is_postgres = IS_POSTGRES")
            content = content.replace("import os\n                    " + target, "from backend.database import IS_POSTGRES\n                    is_postgres = IS_POSTGRES")
            content = content.replace(target, replacement)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

print("Refactoring local...")
refactor_dir(r"d:\Kissanapp")
print("Refactoring HF...")
refactor_dir(r"d:\hf_kissanapp")
print("Done!")
