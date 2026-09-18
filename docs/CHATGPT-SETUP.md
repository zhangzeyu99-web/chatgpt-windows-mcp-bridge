# ChatGPT Developer Mode 接入

## Platform 侧（一次性）

1. 打开 [Platform Tunnels](https://platform.openai.com/settings/organization/tunnels)（路径以控制台为准）。
2. Create tunnel，记下 `tunnel_...` ID。
3. 创建 **Restricted** Runtime API Key，权限至少：Tunnels **Read** + **Use**。
4. 把二者写入本机（不要进 Git）：

```powershell
$sec = Join-Path $env:APPDATA 'chatgpt-sol-local-bridge'
New-Item -ItemType Directory -Force -Path $sec | Out-Null
Set-Content -NoNewline (Join-Path $sec 'tunnel-id') 'tunnel_YOUR_ID'
Set-Content -NoNewline (Join-Path $sec 'runtime-api-key') 'sk-YOUR_KEY'
```

## 本机启动

```powershell
.\deploy\windows\Install-Bridge.ps1
.\deploy\windows\Configure-Tunnel.ps1
.\deploy\windows\Start-Bridge.ps1
.\deploy\windows\Status-Bridge.ps1
```

确认：

- `http://127.0.0.1:8765/readyz` → 200
- `http://127.0.0.1:8766/readyz` → ready / live

## ChatGPT 侧

1. ChatGPT → Settings → 打开 Developer Mode（名称以产品为准）。
2. 创建 Connector / App：
   - Connection: **Tunnel**
   - Tunnel ID: 与本机 `tunnel-id` 相同
   - Authentication: **No Auth**（或产品提供的等价选项）
3. 保存后，在对话里启用该连接器，先做只读探测（如列出工作区根目录）。

## 工作区

编辑 `%USERPROFILE%\chatgpt-sol-local-bridge\.env` 中的 `WORKSPACE_ROOTS` / `DEFAULT_WORKSPACE`，然后：

```powershell
.\deploy\windows\Stop-Bridge.ps1
.\deploy\windows\Start-Bridge.ps1
```

## 计费提醒

- 网页 ChatGPT + Developer Mode：通常计入 ChatGPT 订阅额度。
- Platform Usage：一般只在你另外调用 Platform API 模型时产生。
- 不要把 Runtime API Key 当普通 Chat Completions 密钥到处用。
