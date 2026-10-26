import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

TARGET_FILE = os.path.join(REPO_ROOT, "core/Clash.Meta/component/resource/vehicle.go")
PATCH_FILE = os.path.join(SCRIPT_DIR, "kernel_patch.txt")

# 原目标代码行
TARGET_CODE = "\tresp, err := mihomoHttp.HttpRequest(ctx, h.url, http.MethodGet, header, nil, mihomoHttp.WithSpecialProxy(h.proxy))"

IMPORT_START_MARKER = "\t// [CUSTOM_KERNEL_IMPORTS START]"
IMPORT_END_MARKER = "\t// [CUSTOM_KERNEL_IMPORTS END]"

REQUIRED_IMPORTS = [
    '"crypto/hmac"',
    '"crypto/rand"',
    '"crypto/sha256"',
    '"encoding/hex"',
    '"net/url"',
    '"strconv"',
]


def revert():
    if not os.path.exists(TARGET_FILE):
        return

    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. 移除注入的 imports 标记块
    if "// [CUSTOM_KERNEL_IMPORTS START]" in content:
        start_idx = content.find("// [CUSTOM_KERNEL_IMPORTS START]")
        line_start = content.rfind("\n", 0, start_idx) + 1
        end_idx = content.find("// [CUSTOM_KERNEL_IMPORTS END]")
        line_end = content.find("\n", end_idx) + 1
        content = content[:line_start] + content[line_end:]

    # 2. 移除注入的代码块，保留原 TARGET_CODE
    if "// [CUSTOM_KERNEL_PATCH START]" in content:
        start_idx = content.find("// [CUSTOM_KERNEL_PATCH START]")
        line_start = content.rfind("\n", 0, start_idx) + 1
        target_idx = content.find(TARGET_CODE, start_idx)
        if target_idx != -1:
            content = content[:line_start] + content[target_idx:]

    with open(TARGET_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print("Successfully reverted vehicle.go to original state!")


def main():
    if not os.path.exists(TARGET_FILE) or not os.path.exists(PATCH_FILE):
        print("Error: TARGET_FILE or PATCH_FILE not found", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) > 1 and sys.argv[1] in ("--revert", "-r"):
        revert()
        return

    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # 避免重复打补丁
    if "// [CUSTOM_KERNEL_PATCH" in content:
        print("Notice: vehicle.go already patched.")
        return

    if TARGET_CODE not in content:
        print(f"Error: TARGET_CODE not found in {TARGET_FILE}", file=sys.stderr)
        sys.exit(1)

    with open(PATCH_FILE, "r", encoding="utf-8") as f:
        patch_code = f.read().rstrip()

    # 读取环境变量（默认线上双域名，不含内网 IP）
    rule_hosts = os.environ.get("KERNEL_RULE_HOST", "a.com,b.com")
    sign_salt = os.environ.get("KERNEL_SIGN_SALT", "abc")

    # 提取纯域名/IP（若携带端口自动截断端口，统一 target == hName）
    hosts_list = [h.strip().split(":")[0] for h in rule_hosts.split(",") if h.strip()]
    hosts_str = ", ".join(f'"{h}"' for h in hosts_list)

    # 字符串替换注入
    patch_code = patch_code.replace("__KERNEL_RULE_HOSTS__", hosts_str)
    patch_code = patch_code.replace("__KERNEL_SIGN_SALT__", sign_salt)

    # 补齐缺少的 imports
    missing_imports = [imp for imp in REQUIRED_IMPORTS if imp not in content]
    if missing_imports:
        import_block = f"{IMPORT_START_MARKER}\n"
        for imp in missing_imports:
            import_block += f"\t{imp}\n"
        import_block += f"{IMPORT_END_MARKER}\n"
        content = content.replace('\t"context"\n', import_block + '\t"context"\n', 1)

    # 替换注入补丁
    new_content = content.replace(TARGET_CODE, patch_code, 1)

    with open(TARGET_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Successfully patched vehicle.go! [Hosts: {hosts_str}, Salt: {sign_salt}]")


if __name__ == "__main__":
    main()
