# aturan.md — Aturan Kerja AI Agent untuk Proyek Ini

> File ini adalah kontrak resmi antara user dan AI agent yang punya akses
> terminal, Git, dan GitHub CLI (`gh`). Semua aksi agent di repo ini WAJIB
> mengikuti aturan di bawah tanpa terkecuali.

---

## 0. Tujuan

Mendefinisikan cara kerja AI agent dalam mengerjakan task end-to-end:
issue → branch → code → test → commit → push → PR → CI → merge → cleanup,
dengan guardrail agar tidak merusak `main`, tidak bocor secret, dan tidak
merge tanpa CI hijau.

---

## 1. Prinsip Utama

1. Satu task = satu issue = satu branch = satu PR.
2. Jangan pernah push langsung ke `main` atau `master`.
3. Jangan pernah merge PR tanpa CI hijau.
4. Jangan pernah commit secret, token, `.env`, atau credential.
5. Jangan pernah `git push --force` ke branch yang sudah di-review.
6. Selalu jelaskan aksi destruktif sebelum eksekusi.
7. Kalau ragu, berhenti dan tanya user.

---

## 2. Peran

### AI Agent (full auto)
- Membuat issue
- Membuat branch
- Menulis kode
- Menulis test
- Commit
- Push
- Membuka PR
- Menjawab review comment
- Update dokumentasi
- Menutup issue setelah merge
- Lapor ringkasan ke user

### Manusia (user)
- Memberi arahan awal / task
- Memberi approval untuk aksi berisiko
- Review PR kalau diminta
- Menentukan prioritas bisnis
- Memegang keputusan akhir untuk hal ambigu

---

## 3. Alur Wajib (End-to-End)

```
[TASK DARI USER]
    ↓
1. Buat Issue di GitHub
    ↓
2. Sinkron main terbaru
    ↓
3. Buat Branch dari main
    ↓
4. Implementasi kode + test
    ↓
5. Jalankan lint, test, build lokal
    ↓
6. Commit (Conventional Commits)
    ↓
7. Push branch
    ↓
8. Buka PR (Draft → Ready)
    ↓
9. Tunggu CI hijau
    ↓
10. Merge (Squash)
    ↓
11. Hapus branch
    ↓
12. Tutup issue
    ↓
13. Lapor ke user
```

---

## 4. Aturan Issue

Setiap task baru WAJIB dibuatkan issue terlebih dahulu.

Format judul:
```
[type] Judul singkat
```
Contoh:
- `[feat] Tambah login Google`
- `[fix] Perbaiki null response di /api/user`
- `[chore] Update dependency`

Format body:
```md
## Konteks
<penjelasan singkat>

## Tujuan
<apa yang ingin dicapai>

## Acceptance Criteria
- [ ] ...
- [ ] ...

## Test Plan
- ...

## Catatan
<opsional>
```

Label wajib: `ai-generated`, `auto`.
Label tambahan: `feat` / `fix` / `chore` / `docs` / `refactor` / `test`.

Command:
```bash
gh issue create \
  --title "[feat] Tambah login Google" \
  --body "$(cat <<'EOF'
## Konteks
...

## Tujuan
...

## Acceptance Criteria
- [ ] ...

## Test Plan
- ...
EOF
)" \
  --label "ai-generated,auto,feat"
```

---

## 5. Aturan Branch

- Selalu ambil dari `main` yang sudah update.
- Satu branch = satu issue.
- Format nama branch:

```
<type>/<issue-number>-<slug-singkat>
```

Contoh:
```
feat/12-google-login
fix/45-null-response
chore/78-update-deps
docs/90-readme-setup
refactor/101-auth-service
test/112-cover-callback
```

Command:
```bash
git checkout main
git pull origin main
git checkout -b feat/12-google-login
```

Larangan:
- ❌ Branch dari branch lain (kecuali user minta)
- ❌ Nama branch tanpa nomor issue
- ❌ Branch berumur > 3 hari tanpa aktivitas (harus rebase atau tutup)

---

## 6. Aturan Coding dengan AI

Sebelum menulis kode:
1. Baca issue terkait.
2. Baca pola kode yang sudah ada di repo.
3. Cek  `aturan.md` ini.
4. Konfirmasi ke user kalau ada ambiguitas.

Saat menulis kode:
- Ikuti style yang sudah ada.
- Jangan ubah file di luar scope issue.
- Jangan refactor besar kecuali diminta.
- Jangan hapus test yang ada.
- Tambahkan test untuk kode baru.
- Jalankan formatter & linter repo.

---

## 7. Aturan Commit

Format: **Conventional Commits**

```
<type>(<scope>): <deskripsi singkat>
```

Type yang diizinkan:
- `feat` — fitur baru
- `fix` — perbaikan bug
- `chore` — maintenance
- `docs` — dokumentasi
- `refactor` — refactor tanpa ubah perilaku
- `test` — test saja
- `style` — format, no logic
- `perf` — performance
- `ci` — CI/CD

Contoh:
```
feat(auth): add google oauth button
test(auth): cover oauth callback
docs: update setup guide
```

Aturan:
- Commit kecil dan atomik.
- Jangan commit `.env`, `node_modules`, `dist`, `build`, secret.
- Jangan pakai pesan `wip`, `update`, `fix bug`, `changes`.
- Footer opsional:
  ```
  Refs #12
  Co-authored-by: AI Agent <ai@local>
  ```

Command:
```bash
git add -A
git commit -m "feat(auth): add google oauth button" -m "Refs #12"
```

---

## 8. Pre-Commit Checks (Wajib)

Sebelum commit, WAJIB jalankan (sesuaikan dengan repo):

```bash
npm run lint        # atau ruff, eslint, golangci-lint
npm run test        # atau pytest, go test
npm run build       # kalau ada
```

Kalau gagal:
- Perbaiki dulu.
- Jangan commit kode yang gagal.
- Jangan bypass dengan `--no-verify` kecuali user minta eksplisit.

Scan secret sebelum push:
```bash
git diff --cached | grep -iE "(api[_-]?key|secret|password|token)" || true
```

---

## 9. Aturan Push

```bash
git push -u origin feat/12-google-login
```

Aturan:
- Push hanya ke branch sendiri.
- Jangan push ke `main` / `master`.
- Jangan force push ke branch yang sudah di-review.
- Kalau butuh force push karena rebase, WAJIB tanya user dulu.

---

## 10. Aturan Pull Request

Setiap branch WAJIB dibuka PR.

Langkah:
1. Buka sebagai Draft:
   ```bash
   gh pr create --draft \
     --title "feat(auth): add google oauth" \
     --body "Closes #12" \
     --base main \
     --head feat/12-google-login \
     --label "ai-generated,auto"
   ```
2. Tunggu CI jalan.
3. Kalau CI hijau dan siap, ubah jadi Ready:
   ```bash
   gh pr ready
   ```
4. Kalau ada reviewer, tunggu review.
5. Merge kalau memenuhi syarat (lihat bagian 11).

Body PR wajib berisi:
```md
## What
<perubahan utama>

## Why
Closes #12

## How to Test
1. ...
2. ...

## Screenshot / Video
<jika UI>

## Notes
<risiko, migrasi, catatan AI>
```

---

## 11. Syarat Merge (Wajib)

PR hanya boleh di-merge kalau SEMUA ini terpenuhi:

- [ ] CI hijau (lint, test, build)
- [ ] Tidak ada conflict dengan `main`
- [ ] Tidak ada secret terdeteksi
- [ ] PR description lengkap
- [ ] Minimal 1 approval (kalau repo require review) ATAU user sudah bilang auto-merge
- [ ] Tidak ada komentar `CHANGES_REQUESTED` yang belum resolved

Mode merge: **Squash and Merge**

Command:
```bash
gh pr merge --squash --delete-branch
```

Setelah merge:
```bash
git checkout main
git pull origin main
```

Kalau ada syarat yang gagal:
1. Berhenti.
2. Lapor ke user.
3. Tunggu instruksi.

---

## 12. Setelah Merge

1. Hapus branch lokal & remote (otomatis dari `--delete-branch`).
2. Tutup issue (biasanya otomatis via `Closes #12`).
3. Kalau issue belum tertutup:
   ```bash
   gh issue close 12 --comment "Selesai via PR #XX"
   ```
4. Lapor ringkasan ke user:
   ```
   ✅ Task selesai
   - Issue: #12
   - Branch: feat/12-google-login (deleted)
   - PR: #34 (merged)
   - Commit: abc1234
   - File berubah: 3
   - Test: passed
   ```

---

## 13. Larangan Keras (Hard Rules)

Agent DILARANG:

- ❌ `git push` langsung ke `main` / `master`
- ❌ `git push --force` ke `main` / `master`
- ❌ Merge PR tanpa CI hijau
- ❌ Merge PR tanpa approval (kalau repo require review)
- ❌ Commit file `.env`, credential, private key, token
- ❌ Menghapus branch `main` / `master`
- ❌ Menghapus file kode penting tanpa konfirmasi
- ❌ Menjalankan `rm -rf` di luar repo
- ❌ `git reset --hard` ke commit lama tanpa konfirmasi
- ❌ Mengubah `aturan.md` ini tanpa izin user
- ❌ Mengubah CI/CD, secrets, atau settings repo tanpa izin
- ❌ Install dependency baru tanpa konfirmasi
- ❌ Mengubah database schema / migration tanpa konfirmasi
- ❌ Deploy ke production tanpa izin eksplisit

Kalau agent merasa perlu melanggar salah satu aturan di atas, agent
HARUS berhenti dan bertanya ke user.

---

## 14. Konfirmasi Wajib ke User

Aksi berikut butuh approval manual user SEBELUM dieksekusi:

- Menghapus file / folder
- Mengubah dependency di `package.json`, `requirements.txt`, `go.mod`
- Mengubah schema database atau migration
- Mengubah konfigurasi CI/CD
- Mengubah file `.github/workflows/*`
- Menambah secrets / environment variables
- Force push
- Rebase branch yang sudah di-review
- Merge PR yang menyentuh `main` langsung (rare case)
- Deploy / release / tag

Format pertanyaan ke user:
```
⚠️ Butuh konfirmasi
Aksi: <deskripsi>
Alasan: <kenapa perlu>
Risiko: <apa yang bisa terjadi>
Lanjut? (y/n)
```

---

## 15. Gaya Komunikasi ke User

Agent harus:
- Ringkas, tidak bertele-tele.
- Selalu tampilkan command yang akan dijalankan kalau destruktif.
- Laporkan hasil dengan format:

  ```
  ✅ Selesai: <ringkasan>
  📎 PR: <link>
  🧪 Test: <status>
  ⚠️ Catatan: <kalau ada>
  ```

- Kalau gagal:

  ```
  ❌ Gagal di step: <step>
  Penyebab: <error>
  Saran: <opsi>
  ```

---

## 16. Konvensi Repo (isi manual)

Sesuaikan bagian ini dengan project-mu:

```
Bahasa utama     : TypeScript
Package manager  : pnpm
Test runner      : vitest
Linter           : eslint
Formatter        : prettier
Build            : vite
Branch utama     : main
CI               : GitHub Actions
Deploy target    : Vercel
```

Command yang dipakai agent:

```bash
pnpm install
pnpm lint
pnpm test
pnpm build
```

---

## 17. Checklist Cepat untuk Agent

Sebelum mulai:
- [ ] Sudah baca `aturan.md`?
- [ ] Sudah paham task dari user?
- [ ] Sudah cek issue terkait (atau buat baru)?

Sebelum commit:
- [ ] Lint pass?
- [ ] Test pass?
- [ ] Build pass?
- [ ] Tidak ada secret?

Sebelum push:
- [ ] Branch benar (bukan `main`)?
- [ ] Commit message sesuai Conventional Commits?
- [ ] Tidak ada file sampah?

Sebelum PR:
- [ ] Base = `main`?
- [ ] Body PR lengkap?
- [ ] Label terpasang?

Sebelum merge:
- [ ] CI hijau?
- [ ] Tidak ada conflict?
- [ ] Approval / izin user?

Setelah merge:
- [ ] Branch terhapus?
- [ ] Issue tertutup?
- [ ] Lapor ke user?

---

## 18. Ringkasan Satu Baris

> AI agent mengerjakan semuanya otomatis: issue → branch → code → test →
> commit → push → PR → CI → merge → cleanup. Manusia mengawasi, memberi
> approval untuk aksi berisiko, dan memegang keputusan akhir.

---

## 19. Persetujuan

Dengan file ini ada di repo, user menyetujui agent menjalankan alur
otomatis di atas. Agent menyetujui untuk mematuhi semua larangan dan
meminta konfirmasi pada aksi berisiko.

Versi: 1.0
Berlaku sejak: <tanggal commit file ini>