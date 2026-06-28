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

# SafeNet-Family — system-wide adult-content filtering for Windows

A free, browser-independent content filter for a Windows 11 home PC. It does **not**
depend on any single browser — it filters at the DNS, hosts-file, OS-policy and
firewall levels, so it covers Edge, Chrome, Firefox, Brave, Opera, and any future
browser, plus apps.

> **This is a WORK PC. Do not install here.** Copy the whole `SafeNet-Family`
> folder to your **home** PC and run it there.

---

## What it does (defence in depth)

| Layer | What it blocks | Works in every browser? |
|-------|----------------|--------------------------|
| **1. Filtering DNS** — Cloudflare for Families (`1.1.1.3`) | Adult + malware sites, the whole category | Yes (system-wide) |
| **2. Forced SafeSearch** (hosts file) | Explicit results on Google / Bing / YouTube | Yes (system-wide) |
| **3. SafeSearch policies** (Edge/Chrome/Brave/Firefox) | Locks SafeSearch in the browser UI | Browser-level |
| **4. DoH lockdown** | Browsers' encrypted DNS that would bypass filtering | Yes |
| **5. Firewall anti-bypass** | Manually switching to Google/Quad9/OpenDNS etc. | Yes |
| **6. Hosts blocklist** | Top adult domains, even if DNS is tampered with | Yes (system-wide) |
| **7. Auto-reapply task** | Reverts casual tampering hourly + at startup | n/a |

---

## How to install (on your HOME PC)

1. Copy this whole folder somewhere on the home PC, e.g. `C:\SafeNet-Family`.
2. Right-click **`Install.ps1`** → **Run with PowerShell**. Approve the
   Administrator (UAC) prompt.
   - Or, for the strongest setting:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\Install.ps1 -LockDownDNS
     ```
3. Close and reopen all browsers.
4. Check it worked:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Status.ps1
   ```
5. Test: try visiting an adult site or searching with SafeSearch off — it should be blocked.

## To remove it

Right-click **`Uninstall.ps1`** → **Run with PowerShell**. It restores your
original DNS and removes everything.

---

## Options

- **YouTube strictness:** `-YouTubeMode Strict` (default) or `-YouTubeMode Moderate`.
- **`-LockDownDNS`:** blocks *all* DNS except the filtering resolver. Strongest,
  but can break unusual home networks (e.g. a local Pi-hole). Try without it first.

---

## ⚠️ Honest limitations — please read

You told me **everyone on the PC has Administrator rights** and you want to block
**everyone, including yourself**. Be aware:

- **Anything Administrator sets, Administrator can undo.** Someone with admin rights
  can run `Uninstall.ps1`, delete the scheduled task, or change DNS back. The hourly
  re-apply task reverts *casual / accidental* changes, but it is **not** a lock
  against a determined admin user.
- **To make this genuinely hermetic, change one thing:** create a **separate
  Administrator account** with a password that the protected person does **not**
  have, then demote the everyday account(s) to **Standard user**. Standard users
  cannot change DNS, edit the hosts file, alter policies, or delete the task — so
  the filter becomes effectively unbreakable from that account.
  - Quick way: Settings → Accounts → Other users → Add a "Guardian" admin account
    with a private password; then set the daily-use account to **Standard**.
- **Even stronger (whole-home):** set Cloudflare for Families (`1.1.1.3` / `1.0.0.3`)
  on your **home router** as well, so every device on the network is filtered and a
  single PC can't opt out. Router-level + this PC-level setup is the best free combo.

---

## Files

| File | Purpose |
|------|---------|
| `Install.ps1`     | Applies everything + creates the auto-reapply task. Self-elevates. |
| `Apply-Filter.ps1`| The actual enforcement (idempotent). Run by the scheduled task. |
| `Uninstall.ps1`   | Restores the PC to its prior state. |
| `Status.ps1`      | Read-only health check of all layers. |
| `state\`          | Auto-created: DNS backup + apply log. |

---

## Notes / troubleshooting

- **SafeSearch IPs** used: Google `216.239.38.120`, YouTube `216.239.38.120`
  (strict) / `216.239.38.119` (moderate), Bing `150.171.28.16`. These are the
  official forced-SafeSearch endpoints.
- If a legitimate site is wrongly blocked, it's almost always the DNS category
  filter — you can switch DNS to Cloudflare's `1.1.1.2` (malware-only) by editing
  `$FilterDnsV4` in `Apply-Filter.ps1`, but that stops blocking adult content.
- If your home network uses a local DNS server (e.g. Pi-hole) you want to keep,
  install **without** `-LockDownDNS`.
- Execution policy errors? Run installs with `powershell -ExecutionPolicy Bypass -File <script>`.

---

## Support & Credits

Developed by **Netanel Elhadad**.

If this tool helped you secure your home network and protect your family, consider supporting the project!

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/netanelelhadad)

