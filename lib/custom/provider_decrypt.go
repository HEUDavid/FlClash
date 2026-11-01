package provider

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"errors"
	"net/url"

	P "github.com/metacubex/mihomo/constant/provider"
	"golang.org/x/crypto/chacha20poly1305"
)

var (
	emrsMagic = []byte{'E', 'M', 'R', 'S'}
	eymlMagic = []byte{'E', 'Y', 'M', 'L'}
)

// 由 Mihomo ConvertToMrs 原生生成的最小合法 Domain MRS 二进制蜜罐流 (包含一条空路由占位域名)
var honeypotMrsDomainPayload = []byte{
	0x28, 0xb5, 0x2f, 0xfd, 0x04, 0x00, 0x3d, 0x02, 0x00, 0x64, 0x03, 0x4d,
	0x52, 0x53, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00,
	0x02, 0xaa, 0x00, 0x6a, 0x00, 0x23, 0x6d, 0x6f, 0x63, 0x2e, 0x6c, 0x6c,
	0x75, 0x6e, 0x2d, 0x72, 0x65, 0x64, 0x6c, 0x6f, 0x68, 0x65, 0x63, 0x61,
	0x6c, 0x70, 0x2d, 0x74, 0x6f, 0x70, 0x79, 0x65, 0x6e, 0x6f, 0x68, 0x2d,
	0x64, 0x72, 0x61, 0x75, 0x67, 0x06, 0x00, 0x60, 0x20, 0x18, 0x0c, 0x97,
	0x1f, 0x4e, 0xe2, 0x59, 0xa6, 0xc5, 0x75, 0x5a, 0x29, 0x20, 0xa6, 0xc4,
}

// 由 Mihomo ConvertToMrs 原生生成的最小合法 IPCIDR MRS 二进制蜜罐流 (包含 RFC 5737 保留网段 198.51.100.1/32)
var honeypotMrsIpcidrPayload = []byte{
	0x28, 0xb5, 0x2f, 0xfd, 0x04, 0x00, 0xe5, 0x00, 0x00, 0x70, 0x4d, 0x52,
	0x53, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xc6, 0x33, 0x64,
	0x05, 0x00, 0x33, 0x27, 0x83, 0x17, 0x2c, 0x1a, 0x56, 0x08, 0x60, 0x70,
	0x45, 0xbf, 0xf5, 0x20, 0xaa,
}

// 最小合法空 YAML 文本规则数据
const honeypotYamlPayload = "payload:\n  - DOMAIN-KEYWORD,guard-honeypot-placeholder-null\n"

// 由 CI Secret 注入的编译期常量
const kernelDecryptSalt = "__KERNEL_RULE_SALT__"

// 判断是否为私有加密容器 (匹配 EMRS 或 EYML)
func isEncryptedRuleContainer(data []byte) bool {
	if len(data) < 34 { // 4B Magic + 1B Ver + 1B Mode + 12B Nonce + 16B Tag = 34
		return false
	}
	magic := data[:4]
	return bytes.Equal(magic, emrsMagic) || bytes.Equal(magic, eymlMagic)
}

// 从规则 Provider 的 Vehicle URL 中提取 HWID 参数（离线冷启动与在线更新均有效）
func extractHwidFromVehicle(v P.Vehicle) string {
	if v == nil {
		return ""
	}
	if parsed, err := url.Parse(v.Url()); err == nil {
		return parsed.Query().Get("hwid")
	}
	return ""
}

// 内存即时解密实现 (ChaCha20-Poly1305，强绑定 AAD=hwid)
func decryptRulePayload(data []byte, hwid string) ([]byte, error) {
	if hwid == "" {
		return nil, errors.New("empty hwid context")
	}
	if len(data) < 34 {
		return nil, errors.New("invalid container length")
	}

	nonce := data[6:18]
	ciphertextWithTag := data[18:]

	// 派生密钥：HMAC-SHA256(kernelDecryptSalt, hwid)[:32]
	mac := hmac.New(sha256.New, []byte(kernelDecryptSalt))
	mac.Write([]byte(hwid))
	key := mac.Sum(nil)[:32]

	aead, err := chacha20poly1305.New(key)
	if err != nil {
		return nil, err
	}

	// 强校验 AAD=hwid，跨设备解密在此处直接失败报错
	plaintext, err := aead.Open(nil, nonce, ciphertextWithTag, []byte(hwid))
	if err != nil {
		return nil, err
	}

	return plaintext, nil
}

// 获取格式与行为感知的合法蜜罐明文切片
func getHoneypotPayload(format P.RuleFormat, behavior P.RuleBehavior) []byte {
	if format == P.MrsRule {
		if behavior == P.IPCIDR {
			return honeypotMrsIpcidrPayload
		}
		return honeypotMrsDomainPayload
	}
	return []byte(honeypotYamlPayload)
}

// 内存主动擦除，防 Frida / 调试器内存 Dump
func zeroMemory(buf []byte) {
	for i := range buf {
		buf[i] = 0
	}
}
