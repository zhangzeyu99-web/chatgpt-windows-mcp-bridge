# 维护与升级

## 日常

| 动作 | 命令 |
|------|------|
| 状态 | `.\deploy\windows\Status-Bridge.ps1` |
| 启动 | `.\deploy\windows\Start-Bridge.ps1` |
| 停止 | `.\deploy\windows\Stop-Bridge.ps1` |
| 开机自启 | `.\deploy\windows\Install-Autostart.ps1` |

日志默认：`%USERPROFILE%\.chatgpt-sol-local-bridge\logs\`

## 升级 MCP 桥

```powershell
cd $env:USERPROFILE\chatgpt-sol-local-bridge
git pull --ff-only
npm ci
# 然后 Stop + Start
```

或重新跑 `Install-Bridge.ps1`（会 `git pull` + `npm ci`）。

## 升级 tunnel-client

1. 查看 [Releases](https://github.com/openai/tunnel-client/releases)。
2. 更新 `Install-Bridge.ps1` 内 `$TunnelZipUrl` / `$TunnelVersion`。
3. 删除 `%USERPROFILE%\tools\tunnel-client\tunnel-client.exe` 后重跑安装，或手动解压覆盖。
4. `Configure-Tunnel.ps1` → `Start-Bridge.ps1`。

## 轮换密钥

1. Platform 作废旧 Runtime Key，创建新 Key。
2. 覆盖 `%APPDATA%\chatgpt-sol-local-bridge\runtime-api-key`。
3. 重跑 `Configure-Tunnel.ps1` 与 `Start-Bridge.ps1`。

## 仓库治理建议

- **本仓库**：只放运维脚本与文档；CI 可做 PSScriptAnalyzer / 秘钥扫描。
- **上游桥**：继续跟踪 `mingrath/chatgpt-sol-local-bridge`，不要把 fork 当密钥存放处。
- **私有机位笔记**：若需记录某台机器的路径，另建 **private** 笔记仓或本地 wiki，仍禁止提交密钥。
- Issue / PR：安装失败附 `Status-Bridge.ps1` 输出与桥/隧道日志尾部（先脱敏）。

## 复刻检查清单

- [ ] 新机器安装 Node 20+、Git
- [ ] 写入 tunnel-id + runtime-api-key
- [ ] Install → Configure → Start → Status 全绿
- [ ] ChatGPT Tunnel 连接器用同一 tunnel id
- [ ] WORKSPACE_ROOTS 仅含需要暴露的目录
- [ ] 确认 `.gitignore` 挡住 secrets
