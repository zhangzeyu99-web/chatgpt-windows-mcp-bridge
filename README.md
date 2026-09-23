# ChatGPT Windows MCP Bridge (ops template)

可复刻的 **Windows 本机 MCP 桥接 + OpenAI Secure MCP Tunnel** 安装与运维模板。

本仓库**不包含** MCP 服务源码本体，也不包含任何密钥。运行时会克隆上游开源桥，并下载官方 `tunnel-client`。

> 仓库现为 **Public**。请只提交脚本与文档；密钥永远留在本机 `%APPDATA%`。

## 架构

```
ChatGPT (Developer Mode connector)
        │  Secure MCP Tunnel
        ▼
tunnel-client (本机, 出站 HTTPS)
        │  localhost
        ▼
chatgpt-sol-local-bridge (本机 MCP, 默认 :8765)
        │
        ▼
你授权的工作区目录 (WORKSPACE_ROOTS)
```

| 组件 | 来源 | 默认位置 |
|------|------|----------|
| MCP 桥 | [mingrath/chatgpt-sol-local-bridge](https://github.com/mingrath/chatgpt-sol-local-bridge) | `%USERPROFILE%\chatgpt-sol-local-bridge` |
| tunnel-client | [openai/tunnel-client](https://github.com/openai/tunnel-client/releases) | `%USERPROFILE%\tools\tunnel-client` |
| 密钥 / runtime | 本机生成 | `%APPDATA%\chatgpt-sol-local-bridge\` |
| 桥监听 | 127.0.0.1 | `8765` |
| 隧道健康检查 | 127.0.0.1 | `8766` |

## 前置条件

- Windows 10/11 x64
- Node.js 20+
- Git
- ChatGPT 计划支持 Developer Mode（如 Pro）
- OpenAI Platform：已创建 Tunnel + **Restricted** Runtime API Key（Tunnels Read + Use）

## 快速安装（可复刻）

```powershell
# 1) 克隆本运维仓库
git clone https://github.com/zhangzeyu99-web/chatgpt-windows-mcp-bridge.git
cd chatgpt-windows-mcp-bridge

# 2) 准备密钥目录（不要提交）
$sec = Join-Path $env:APPDATA 'chatgpt-sol-local-bridge'
New-Item -ItemType Directory -Force -Path $sec | Out-Null
Set-Content -NoNewline (Join-Path $sec 'tunnel-id') 'tunnel_xxxxxxxx'
Set-Content -NoNewline (Join-Path $sec 'runtime-api-key') 'sk-xxxxxxxx'
# 可选：icacls 收紧权限，仅当前用户可读写

# 3) 安装桥 + tunnel-client 并写入 .env
powershell -ExecutionPolicy Bypass -File .\deploy\windows\Install-Bridge.ps1

# 4) 配置隧道 profile（非交互）
powershell -ExecutionPolicy Bypass -File .\deploy\windows\Configure-Tunnel.ps1

# 5) 启动
powershell -ExecutionPolicy Bypass -File .\deploy\windows\Start-Bridge.ps1

# 6) 看状态
powershell -ExecutionPolicy Bypass -File .\deploy\windows\Status-Bridge.ps1
```

健康检查：

```powershell
Invoke-WebRequest http://127.0.0.1:8765/readyz -UseBasicParsing
Invoke-WebRequest http://127.0.0.1:8766/readyz -UseBasicParsing
```

## ChatGPT 接入

见 [docs/CHATGPT-SETUP.md](docs/CHATGPT-SETUP.md)。

要点：连接方式选 **Tunnel**，填同一 `tunnel_id`，Auth 选 **No Auth**（本地桥自管权限）。

## 工作区授权

编辑安装目录下的 `.env`（或 `%APPDATA%\chatgpt-sol-local-bridge\runtime.env`）：

```env
WORKSPACE_ROOTS=C:\Users\You\projects;D:\codex\your-repo
DEFAULT_WORKSPACE=D:\codex\your-repo
ALLOW_TOOL_ROOT_REGISTRATION=false
```

改完后执行 `Stop-Bridge.ps1` → `Start-Bridge.ps1`。  
注意：ChatGPT 侧动态 `workspace_add_root` 默认关闭，加目录只能改本机配置后重启。

## 开机自启（可选）

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\windows\Install-Autostart.ps1
```

## 安全红线

**永远不要提交：**

- `runtime-api-key` / `CONTROL_PLANE_API_KEY`
- `tunnel-id` / `CONTROL_PLANE_TUNNEL_ID`
- 含真实密钥的 `.env` / `runtime.env`
- `%APPDATA%\chatgpt-sol-local-bridge\*`

仓库内只保留 [.env.example](.env.example)。更多见 [docs/SECURITY.md](docs/SECURITY.md)。

计费说明：在 ChatGPT 网页里用 Developer Mode + 本机隧道，一般走 **ChatGPT 订阅**；只有你另外用 Platform API（如 Responses API）调模型时，才会产生 Platform 用量账单。隧道本身文档未写按次收费。

## 维护

见 [docs/MAINTENANCE.md](docs/MAINTENANCE.md)。

## License

本运维模板：MIT。上游桥与 `tunnel-client` 各自遵循其仓库许可证。