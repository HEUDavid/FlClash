import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

# --- Target A: vehicle.go (防重放请求头注入) ---
VEHICLE_FILE = os.path.join(REPO_ROOT, "core/Clash.Meta/component/resource/vehicle.go")
VEHICLE_PATCH_FILE = os.path.join(SCRIPT_DIR, "kernel_patch.txt")
VEHICLE_TARGET_CODE = "\tresp, err := mihomoHttp.HttpRequest(ctx, h.url, http.MethodGet, header, nil, mihomoHttp.WithSpecialProxy(h.proxy))"

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

# --- Target B: provider.go & provider_decrypt.go (规则即时解密与蜜罐) ---
PROVIDER_FILE = os.path.join(REPO_ROOT, "core/Clash.Meta/rules/provider/provider.go")
PROVIDER_DECRYPT_SRC = os.path.join(SCRIPT_DIR, "provider_decrypt.go")
PROVIDER_DECRYPT_DST = os.path.join(REPO_ROOT, "core/Clash.Meta/rules/provider/provider_decrypt.go")
PROVIDER_DECRYPT_TEST_SRC = os.path.join(SCRIPT_DIR, "provider_decrypt_test.go")
PROVIDER_DECRYPT_TEST_DST = os.path.join(REPO_ROOT, "core/Clash.Meta/rules/provider/provider_decrypt_test.go")

PROVIDER_TARGET_CODE = (
    "\trp.Fetcher = resource.NewFetcher(name, interval, vehicle, bundleFile, func(bytes []byte) (ruleStrategy, error) {\n"
    "\t\treturn rulesParse(bytes, newStrategy(behavior, parse), format)\n"
    "\t}, onUpdate)"
)

PROVIDER_PATCH_CODE = (
    "\trp.Fetcher = resource.NewFetcher(name, interval, vehicle, bundleFile, func(bytes []byte) (ruleStrategy, error) {\n"
    "\t\t// [CUSTOM_KERNEL_RULE_DECRYPT START]\n"
    "\t\tif isEncryptedRuleContainer(bytes) {\n"
    "\t\t\thwid := extractHwidFromVehicle(vehicle)\n"
    "\t\t\tif decrypted, err := decryptRulePayload(bytes, hwid); err == nil {\n"
    "\t\t\t\tdefer zeroMemory(decrypted)\n"
    "\t\t\t\tbytes = decrypted\n"
    "\t\t\t} else {\n"
    "\t\t\t\tbytes = getHoneypotPayload(format, behavior)\n"
    "\t\t\t}\n"
    "\t\t}\n"
    "\t\t// [CUSTOM_KERNEL_RULE_DECRYPT END]\n"
    "\t\treturn rulesParse(bytes, newStrategy(behavior, parse), format)\n"
    "\t}, onUpdate)"
)


def revert():
    # 1. 还原 vehicle.go
    if os.path.exists(VEHICLE_FILE):
        with open(VEHICLE_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        if "// [CUSTOM_KERNEL_IMPORTS START]" in content:
            start_idx = content.find("// [CUSTOM_KERNEL_IMPORTS START]")
            line_start = content.rfind("\n", 0, start_idx) + 1
            end_idx = content.find("// [CUSTOM_KERNEL_IMPORTS END]")
            line_end = content.find("\n", end_idx) + 1
            content = content[:line_start] + content[line_end:]

        if "// [CUSTOM_KERNEL_PATCH START]" in content:
            start_idx = content.find("// [CUSTOM_KERNEL_PATCH START]")
            line_start = content.rfind("\n", 0, start_idx) + 1
            target_idx = content.find(VEHICLE_TARGET_CODE, start_idx)
            if target_idx != -1:
                content = content[:line_start] + content[target_idx:]

        with open(VEHICLE_FILE, "w", encoding="utf-8") as f:
            f.write(content)
        print("Successfully reverted vehicle.go to original state!")

    # 2. 还原 provider.go
    if os.path.exists(PROVIDER_FILE):
        with open(PROVIDER_FILE, "r", encoding="utf-8") as f:
            p_content = f.read()

        if "// [CUSTOM_KERNEL_RULE_DECRYPT START]" in p_content:
            p_content = p_content.replace(PROVIDER_PATCH_CODE, PROVIDER_TARGET_CODE)
            with open(PROVIDER_FILE, "w", encoding="utf-8") as f:
                f.write(p_content)
            print("Successfully reverted provider.go to original state!")

    # 3. 移除注入的 provider_decrypt.go 及测试文件
    if os.path.exists(PROVIDER_DECRYPT_DST):
        os.remove(PROVIDER_DECRYPT_DST)
        print("Removed injected provider_decrypt.go")

    if os.path.exists(PROVIDER_DECRYPT_TEST_DST):
        os.remove(PROVIDER_DECRYPT_TEST_DST)
        print("Removed injected provider_decrypt_test.go")


def patch_vehicle():
    if not os.path.exists(VEHICLE_FILE) or not os.path.exists(VEHICLE_PATCH_FILE):
        print("Error: VEHICLE_FILE or VEHICLE_PATCH_FILE not found", file=sys.stderr)
        return False

    with open(VEHICLE_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    if "// [CUSTOM_KERNEL_PATCH" in content:
        print("Notice: vehicle.go already patched.")
        return True

    if VEHICLE_TARGET_CODE not in content:
        print(f"Error: VEHICLE_TARGET_CODE not found in {VEHICLE_FILE}", file=sys.stderr)
        return False

    with open(VEHICLE_PATCH_FILE, "r", encoding="utf-8") as f:
        patch_code = f.read().rstrip()

    rule_hosts = os.environ.get("KERNEL_RULE_HOST", "a.com,b.com")
    sign_salt = os.environ.get("KERNEL_SIGN_SALT", "abc")

    hosts_list = [h.strip().split(":")[0] for h in rule_hosts.split(",") if h.strip()]
    hosts_str = ", ".join(f'"{h}"' for h in hosts_list)

    patch_code = patch_code.replace("__KERNEL_RULE_HOSTS__", hosts_str)
    patch_code = patch_code.replace("__KERNEL_SIGN_SALT__", sign_salt)

    missing_imports = [imp for imp in REQUIRED_IMPORTS if imp not in content]
    if missing_imports:
        import_block = f"{IMPORT_START_MARKER}\n"
        for imp in missing_imports:
            import_block += f"\t{imp}\n"
        import_block += f"{IMPORT_END_MARKER}\n"
        content = content.replace('\t"context"\n', import_block + '\t"context"\n', 1)

    new_content = content.replace(VEHICLE_TARGET_CODE, patch_code, 1)
    with open(VEHICLE_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Successfully patched vehicle.go! [Hosts: {hosts_str}, Salt: {sign_salt}]")
    return True


def patch_provider():
    if not os.path.exists(PROVIDER_FILE) or not os.path.exists(PROVIDER_DECRYPT_SRC):
        print("Error: PROVIDER_FILE or PROVIDER_DECRYPT_SRC not found", file=sys.stderr)
        return False

    # 读取解密 Salt（优先 RULE_ENCRYPT_SALT，次选 RULE_SECRET_SALT）
    rule_salt = os.environ.get("RULE_ENCRYPT_SALT") or os.environ.get("RULE_SECRET_SALT") or "default_rule_decrypt_salt"

    # 1. 复制并注入 Salt 到 provider_decrypt.go
    with open(PROVIDER_DECRYPT_SRC, "r", encoding="utf-8") as f:
        decrypt_code = f.read()

    decrypt_code = decrypt_code.replace("__KERNEL_RULE_SALT__", rule_salt)
    with open(PROVIDER_DECRYPT_DST, "w", encoding="utf-8") as f:
        f.write(decrypt_code)
    print(f"Successfully injected provider_decrypt.go! [Salt: {rule_salt[:6]}***]")

    # 2. 如果存在测试文件，同步复制以便执行单元测试
    if os.path.exists(PROVIDER_DECRYPT_TEST_SRC):
        with open(PROVIDER_DECRYPT_TEST_SRC, "r", encoding="utf-8") as f:
            test_code = f.read()
        with open(PROVIDER_DECRYPT_TEST_DST, "w", encoding="utf-8") as f:
            f.write(test_code)

    # 3. 插桩 provider.go
    with open(PROVIDER_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    if "// [CUSTOM_KERNEL_RULE_DECRYPT" in content:
        print("Notice: provider.go already patched.")
        return True

    if PROVIDER_TARGET_CODE not in content:
        print(f"Error: PROVIDER_TARGET_CODE not found in {PROVIDER_FILE}", file=sys.stderr)
        return False

    new_content = content.replace(PROVIDER_TARGET_CODE, PROVIDER_PATCH_CODE, 1)
    with open(PROVIDER_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)

    print("Successfully patched provider.go!")
    return True


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("--revert", "-r"):
        revert()
        return

    ok_v = patch_vehicle()
    ok_p = patch_provider()
    if not ok_v or not ok_p:
        sys.exit(1)


if __name__ == "__main__":
    main()
