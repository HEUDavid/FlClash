import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

TARGET_FILE = os.path.join(REPO_ROOT, "core/Clash.Meta/component/resource/vehicle.go")
PATCH_FILE = os.path.join(SCRIPT_DIR, "kernel_patch.txt")

# 原目标代码行
TARGET_CODE = "\tresp, err := mihomoHttp.HttpRequest(ctx, h.url, http.MethodGet, header, nil, mihomoHttp.WithSpecialProxy(h.proxy))"


def main():
    if not os.path.exists(TARGET_FILE):
        print(f"Error: {TARGET_FILE} not found", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(PATCH_FILE):
        print(f"Error: {PATCH_FILE} not found", file=sys.stderr)
        sys.exit(1)

    with open(PATCH_FILE, "r", encoding="utf-8") as f:
        replacement_code = f.read().rstrip()

    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # 避免重复注入（检查 patch 文件的特征注释标记）
    if "// [CUSTOM_KERNEL_PATCH]" in content:
        print("Notice: vehicle.go already patched.")
        return

    if TARGET_CODE not in content:
        print(f"Error: TARGET_CODE not found in {TARGET_FILE}", file=sys.stderr)
        sys.exit(1)

    # 用文本文件里的内容直接替换目标代码
    new_content = content.replace(TARGET_CODE, replacement_code, 1)

    with open(TARGET_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Successfully patched {TARGET_FILE} using {PATCH_FILE}!")


if __name__ == "__main__":
    main()
