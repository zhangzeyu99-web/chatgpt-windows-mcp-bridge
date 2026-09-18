# 安全与密钥

## 存放位置（本机）

| 文件 | 路径 |
|------|------|
| tunnel id | `%APPDATA%\chatgpt-sol-local-bridge\tunnel-id` |
| runtime API key | `%APPDATA%\chatgpt-sol-local-bridge\runtime-api-key` |
| runtime env | `%APPDATA%\chatgpt-sol-local-bridge\runtime.env` |

安装脚本会尝试用 `icacls` 去掉继承、仅保留当前用户。

## 禁止

- 把上述文件复制进 Git
- 在聊天/截图中完整暴露 `sk-` / `tunnel_`（必要排查只保留前缀）
- 给 Runtime Key 开 All 权限；保持 Tunnels Read+Use

## 泄露后

1. Platform 立即 revoke key  
2. 如需，轮换 / 重建 tunnel  
3. 检查 git 历史是否误提交；若有，按 GitHub 文档清理并视为已泄露
