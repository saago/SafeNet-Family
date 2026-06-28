
# 🛡️ SafeNet-Family

**System-wide adult-content filtering for Windows**

A free, browser-independent content filter for a Windows 11 home PC. It does **not** depend on any single browser — it filters at the DNS, hosts-file, OS-policy, and firewall levels, so it covers Edge, Chrome, Firefox, Brave, Opera, and any future browser, plus apps.

---

## 🔒 What it does (Defence in Depth)

| Layer | What it Blocks | Browser Compatibility |
| :--- | :--- | :--- |
| **1. Filtering DNS** (`1.1.1.3`) | Adult & malware sites (entire category) | Yes (System-wide) |
| **2. Forced SafeSearch** | Explicit results on Google, Bing & YouTube | Yes (System-wide) |
| **3. SafeSearch Policies** | Locks SafeSearch in the browser UI | Browser-level |
| **4. DoH Lockdown** | Browsers' encrypted DNS that bypass filtering | Yes (System-wide) |
| **5. Firewall Anti-bypass** | Manual switching to Google/Quad9/OpenDNS | Yes (System-wide) |
| **6. Hosts Blocklist** | Top adult domains (DNS tampering fallback) | Yes (System-wide) |
| **7. Auto-reapply Task** | Reverts casual tampering hourly & at startup | N/A |

---

## 🚀 Installation Guide

1. Copy this folder to the home PC (e.g., `C:\SafeNet-Family`).
2. Right-click **`Install.ps1`** and select **Run with PowerShell**. Approve the UAC prompt.
   *(For the strongest setting, run: `powershell -ExecutionPolicy Bypass -File .\Install.ps1 -LockDownDNS`)*
3. Close and reopen all browsers.
4. Verify the installation by running: `powershell -ExecutionPolicy Bypass -File .\Status.ps1`
5. Test the filter by attempting to visit an adult site or searching with SafeSearch off.

### Uninstallation

Right-click **`Uninstall.ps1`** and select **Run with PowerShell**. This restores your original DNS and removes all filters.

---

## ⚙️ Configuration Options

*   **YouTube Strictness:** Use `-YouTubeMode Strict` (default) or `-YouTubeMode Moderate`.
*   **DNS Lockdown:** Use `-LockDownDNS` to block all DNS except the filtering resolver. *Note: This is the strongest setting but may break custom home networks like Pi-hole. Try without it first.*

---

## ⚠️ Honest Limitations (Please Read)

You mentioned everyone on the PC has Administrator rights and you want to block everyone, including yourself. Be aware:

*   **Admin Override:** Anything an Administrator sets, they can undo. The hourly re-apply task reverts accidental changes but is not a lock against a determined admin user.
*   **Hermetic Setup:** Create a **separate Administrator account** with a private password. Demote everyday accounts to **Standard user**. Standard users cannot change DNS, edit hosts files, or alter policies.
*   **Whole-home Filtering:** For the strongest protection, configure Cloudflare for Families (`1.1.1.3` / `1.0.0.3`) directly on your **home router** so every device on the network is filtered.

---

## 📁 Project Files

| File | Purpose |
| :--- | :--- |
| `Install.ps1` | Applies filters and creates the auto-reapply task (Self-elevates). |
| `Apply-Filter.ps1` | The actual enforcement script run by the scheduled task. |
| `Uninstall.ps1` | Restores the PC to its prior unfiltered state. |
| `Status.ps1` | Read-only health check for all filtering layers. |
| `state\` | Auto-created directory for DNS backup and apply logs. |

---

## 💡 Troubleshooting & Notes

*   **SafeSearch IPs:** Uses official forced-SafeSearch endpoints (Google: `216.239.38.120`, YouTube: `216.239.38.120` / `.119`, Bing: `150.171.28.16`).
*   **False Positives:** If a legitimate site is blocked, it's likely the DNS filter. You can switch to Cloudflare's malware-only DNS (`1.1.1.2`) in `Apply-Filter.ps1`, but this disables adult content blocking.
*   **Local DNS:** If using a local DNS (e.g., Pi-hole), install **without** `-LockDownDNS`.
*   **Execution Errors:** Run scripts with `powershell -ExecutionPolicy Bypass -File <script>`.

---

## 🤝 Support & Credits

Developed by **Netanel Elhadad**.

If this tool helped secure your home network and protect your family, consider supporting the project!

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/netanelelhadad)
