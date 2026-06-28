# Hi there, I'm Netanel Elhadad 👋

### IT Operations & Infrastructure Administrator | Python Developer | Aspiring Cyber Security Professional

I am an IT Operations specialist with extensive experience in system administration, virtualization, and enterprise infrastructure management. I am passionate about bridging the gap between IT operations and software development by building custom automation tools. Currently, I am expanding my expertise with the goal of transitioning into the Cyber Security field by the end of the year.

---

### 🛠️ Tech Stack & Tools

*   **Languages:** Python (PyCharm, Pygame)
*   **Infrastructure & Virtualization:** VMware (vSphere, ESXi), Windows Server, Linux
*   **Networking & Security:** Cisco Networking, Checkpoint Firewalls (Gaia)
*   **Storage & Hardware:** NetApp ONTAP, Dell PowerEdge Servers (iDRAC)
*   **Automation & Deployment:** Terraform, CLion (Air-gapped environments)

---

### 💻 Featured Projects

Here are some of the key tools I've developed to streamline IT administrative tasks:

*   **ITops-Automation---Management-Suite-for-Dell-Servers**
    A unified GUI automation suite for managing, configuring, and updating Dell PowerEdge servers (iDRAC) and VMware ESXi environments. Features bulk firmware updates, initial network setup, automated ESXi Kickstart (KS.CFG) ISO generation, and parallel network ISO mounting.
*   **ITops-Automation---Backup-and-Restore-Cisco-Switch**
    About A collection of Python automation tools and GUI applications for managing IT infrastructure, servers, and network switches.

---

### ⚡ Fun Facts
*   When I'm not managing servers or writing Python scripts, you can find me on my Logitech G29 playing driving simulators like *Euro Truck Simulator 2*.
*   In tactical video games, I'm the type of player who ignores the main plot to explore the entire map and collect every hidden stash. 🎮

---

### 📫 Let's Connect

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-blue?style=for-the-badge&logo=linkedin)](https://linkedin.com/in/netanel-elhadad-2aaaa361)
[![Email](https://img.shields.io/badge/Email-Contact_Me-red?style=for-the-badge&logo=gmail)](mailto:nati3210@gmail.com)

---

### ☕ Support My Work

If you find my automation tools or scripts helpful, consider supporting my work!
[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=for-the-badge&logo=github)](https://github.com/saago)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-FFDD00?style=for-the-badge&logo=buy-me-a-coffee)](https://ko-fi.com/netanelelhadad)

# 🛡️ SafeNet-Family

**System-wide adult-content filtering for Windows**

A free, browser-independent content filter for a Windows 11 home PC. It does **not** depend on any single browser — it filters at the DNS, hosts-file, OS-policy, and firewall levels, so it covers Edge, Chrome, Firefox, Brave, Opera, and any future browser, plus apps.

> **⚠️ IMPORTANT:** This is a WORK PC. Do not install here. Copy the whole `SafeNet-Family` folder to your **home** PC and run it there.

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
