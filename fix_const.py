import subprocess
import os
import re

def run_analyze():
    print("Running flutter analyze...")
    result = subprocess.run(["flutter", "analyze", "--machine"], capture_output=True, text=True, shell=True)
    return result.stdout.split('\n')

def fix_const_errors():
    lines = run_analyze()
    files_to_fix = {}
    
    for line in lines:
        if not line.strip(): continue
        if "NON_CONSTANT_" in line or "INVALID_CONSTANT" in line or "CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE" in line or "CONST_WITH_NON_CONSTANT_ARGUMENT" in line or "CONST_EVAL_THROWS_EXCEPTION" in line or "CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH" in line or "non_constant" in line.lower() or "const" in line.lower():
            # Parse the machine output format: SEVERITY|TYPE|ERROR_CODE|FILE_PATH|LINE|COLUMN|LENGTH|MESSAGE
            parts = line.split('|')
            if len(parts) >= 8:
                file_path = parts[3]
                line_num = int(parts[4]) - 1 # 0-indexed
                col_num = int(parts[5]) - 1
                
                if file_path not in files_to_fix:
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            files_to_fix[file_path] = f.readlines()
                    except Exception:
                        continue
                
                # We need to remove the word "const" on this line or previous lines if it applies to this expression.
                # A naive but effective approach: just search for 'const ' in the current line and remove it.
                # If it's not on the current line, we search upwards for a few lines.
                
                # Let's try to remove 'const ' from the line where the error is reported first.
                file_lines = files_to_fix[file_path]
                if 0 <= line_num < len(file_lines):
                    # Find 'const ' before the column or anywhere in the line
                    l = file_lines[line_num]
                    if 'const ' in l:
                        file_lines[line_num] = re.sub(r'\bconst\s+', '', l, count=1)
                    else:
                        # Search upwards up to 5 lines
                        for i in range(line_num - 1, max(-1, line_num - 6), -1):
                            if 'const ' in file_lines[i]:
                                file_lines[i] = re.sub(r'\bconst\s+', '', file_lines[i], count=1)
                                break

    for file_path, lines in files_to_fix.items():
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
            
    print(f"Fixed errors in {len(files_to_fix)} files.")
    return len(files_to_fix)

if __name__ == "__main__":
    # Run multiple passes to catch cascaded const errors
    for _ in range(5):
        fixed_count = fix_const_errors()
        if fixed_count == 0:
            break
    print("Done.")
