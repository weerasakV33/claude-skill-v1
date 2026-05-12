# claude-engineering-skills

ทำให้ Claude Code ทำงานเป็น senior software engineer จริงๆ — ไม่ใช่ assistant ที่รอคำสั่ง แต่เป็น engineering partner ที่รับผิดชอบทั้งระบบ

ทุกอย่างใน repo นี้เขียนเป็น **identity** ไม่ใช่ instructions — Claude อ่านแล้วซึมเข้าตัวตน เหมือนหมอที่ไม่จำทุกยาแต่รู้ว่าต้องเปิดหนังสือเมื่อไหร่ เหมือนตำรวจที่ไม่จำกฎหมายทุกข้อแต่รู้ว่าต้องเปิดประมวลกฎหมายเมื่อไหร่ SE ก็เหมือนกัน — ไม่จำทุก API แต่รู้ว่าต้องเปิด Context7 / Cloud Logging / Chrome DevTools เมื่อไหร่

---

## ⚡ Install

### Windows

```powershell
git clone https://github.com/weerasakV33/claude-skill-v1.git
cd claude-skill-v1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Unblock-File .\install.ps1
.\install.ps1
```

### Mac / Linux

```bash
git clone https://github.com/weerasakV33/claude-skill-v1.git
cd claude-skill-v1
chmod +x install.sh
./install.sh
```

ปิด terminal เก่า เปิดใหม่ → identity + 7 skills โหลดทันที

---

## 🔌 MCP servers — สำคัญที่สุด

Skills สอน Claude ให้รู้ว่า **ต้องเห็นอะไร**. MCP servers ทำให้ Claude **เห็นได้จริง**

ติดตั้ง **baseline 6 อันนี้** หลัง install skills:

```bash
# 1. GitHub — repo, PRs, issues, Actions logs
claude mcp add --transport http github https://api.githubcopilot.com/mcp

# 2. Chrome DevTools — ตัวสำคัญที่สุดสำหรับงาน UI
#    เห็น DOM, console, network, performance trace จริง
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest

# 3. Context7 — docs ใหม่จริงตาม version (ห้าม Claude เดา API จาก training data)
claude mcp add context7 -- npx -y @upstash/context7-mcp

# 4. Filesystem — scoped local file access
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem <project-path>

# 5. Playwright — scripted E2E
claude mcp add playwright -- npx -y @playwright/mcp

# 6. Sentry — production errors (ถ้าใช้)
claude mcp add sentry -- npx -y @sentry/mcp-server@latest
```

**Stack-specific:**

```bash
# GCP (Cloud Run + Cloud SQL + Cloud Logging)
claude mcp add gcp-observability -- npx -y @google-cloud/observability-mcp

# Supabase
claude mcp add supabase -- npx -y @supabase/mcp-server-supabase

# Postgres ตรงๆ (read-only mode สำหรับ prod)
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres <conn-string>

# Stripe
claude mcp add stripe -- npx -y @stripe/mcp
```

---

## 📦 What you get

### Identity (always loaded — `CLAUDE.md`)

Claude คือ **senior software engineer** ที่:
- เห็นทั้งระบบก่อนแตะ — อ่าน log, browser, DB จริง ไม่ใช่อ่าน code แล้วเดา
- Recommend ไม่ survey — เสนอทางเฉพาะเจาะจง ไม่ list ตัวเลือก
- Plan แล้ว execute จนเสร็จ — ไม่หยุดกลางทางถามว่า "ทำต่อมั้ย"
- รับผิดชอบทั้งระบบ — code, tests, env, deploy, verification
- ไม่ทำขึ้นมาเอง — ถ้าไม่ได้ดู log จริง ไม่บอกว่า "ดูจาก log แล้ว"
- **รู้ว่าเมื่อไม่รู้ต้องไปเปิดหนังสือ** — Context7 สำหรับ docs ใหม่, Cloud Logging สำหรับ runtime, Chrome DevTools สำหรับ UI, codebase search สำหรับ patterns

### 7 skills (loaded on demand)

| Skill | When this facet of identity activates |
|-------|---------------------------------------|
| `setup-environment` | หลัง plan, ก่อน code — เปิด tabs ที่จำเป็นต้องเห็น |
| `greenfield-project` | เริ่ม project ใหม่ — architect ทั้งระบบ |
| `debugging` | bug report — evidence first, theory second |
| `multi-issue-batch` | bugs หลายตัวพร้อมกัน — inventory ก่อน fix |
| `impact-analysis` | แก้ของที่ใช้หลายที่ — trace dependencies ก่อน |
| `reference-driven` | "ทำเหมือนอันนั้น" — อ่าน reference ให้ครบก่อน build |
| `build-complete-system` | plan agreed แล้ว — execute จนเสร็จ |

---

## 🎯 The flow

```
1. รับ requirement
        ↓
2. Plan together (Mode A — recommend ไม่ survey)
        ↓
3. setup-environment — เปิด tabs ที่ต้องเห็น
        ↓
4. Execute (Mode B — build จนเสร็จ ไม่หยุดถาม)
        ↓
5. Verify with real evidence (เปิด browser, hit endpoint, ดู log)
        ↓
6. Report what actually happened
```

**Mode A vs Mode B แยกชัด** — planning ไม่เขียน code, executing ไม่ถาม permission กับสิ่งที่อยู่ใน plan แล้ว

---

## 📁 Layout

```
~/.claude/
├── CLAUDE.md                            ← identity (always loaded)
├── skills/
│   ├── setup-environment/SKILL.md
│   ├── greenfield-project/SKILL.md
│   ├── debugging/SKILL.md
│   ├── multi-issue-batch/SKILL.md
│   ├── impact-analysis/SKILL.md
│   ├── reference-driven/SKILL.md
│   └── build-complete-system/SKILL.md
└── projects/                            ← per-project memory (UNTOUCHED)
```

Installer **backup** ของเก่าที่ `~/.claude/.backups/<timestamp>/` และ **ไม่แตะ** `projects/`

---

## ✅ Verify install

หลัง install:
1. ปิด terminal เก่าทั้งหมด
2. เปิด terminal ใหม่
3. รัน `claude`
4. ถาม Claude:

```
Hi. What is your role? What skills do you have? What MCP tools can you see?
```

Claude ควรตอบ:
- เป็น **senior software engineer**, partner ไม่ใช่ assistant
- มี **7 skills**: setup-environment, greenfield-project, debugging, multi-issue-batch, impact-analysis, reference-driven, build-complete-system
- list MCP tools ที่ connect สำเร็จ

---

## 🔄 Update

```bash
# Windows
cd claude-skill-v1
git pull
.\install.ps1

# Mac/Linux
cd claude-skill-v1
git pull
./install.sh
```

ของเก่าจะถูก backup อัตโนมัติที่ `~/.claude/.backups/<timestamp>/`

---

## 🎯 How it works with per-project memory

Repo นี้ install **global** identity + skills (universal engineering character)

Per-project context (stack เฉพาะ, conventions, business rules) อยู่ที่ `~/.claude/projects/<your-project>/memory/` — แยกของแต่ละ project (Claude Code จัดการอัตโนมัติ)

ทั้ง 2 layer ทำงานคู่กัน:
- **Global** (จาก repo นี้): "ผมเป็นวิศวกรประเภทไหน ทำงานยังไง"
- **Per-project** (Claude เก็บเอง): "project นี้ใช้ stack อะไร convention อะไร"

ตอนเริ่ม session ใหม่กับ project เดิม:
```
Read memory of <project-name>. Continue from where we left off.
```

Claude จะโหลด identity + per-project memory + skills ทั้งหมด

---

## License

MIT
