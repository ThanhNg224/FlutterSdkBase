# GIT_FLOW.md

## Git & Collaboration Workflow

### 1. Branching Strategy (Gitflow)

| Branch | Mục đích | Tạo từ | Merge vào | Xóa sau merge |
| --- | --- | --- | --- | --- |
| `main` | Code production ổn định, gắn tag release | — | — | Không |
| `develop` | Tích hợp tính năng cho bản release kế tiếp | `main` | — | Không |
| `feature/<desc>` | Phát triển tính năng mới | `develop` | `develop` | Có |
| `bugfix/<desc>` | Sửa lỗi phát hiện trên dev/staging | `develop` | `develop` | Có |
| `release/<version>` | Chuẩn bị release (bump version, test gate) | `develop` | `main` & `develop` | Có |
| `hotfix/<desc>` | Sửa lỗi khẩn cấp trên production | `main` | `main` & `develop` | Có |

---

### 2. Release & Hotfix Flow

#### A. Release Flow
1. Tạo branch `release/<version>` từ `develop` (tuân thủ SemVer: `MAJOR.MINOR.PATCH`).
2. Bump version trong `pubspec.yaml` và cập nhật `CHANGELOG.md` (`chore(release): bump version to x.y.z`).
3. Chạy `make verify` (hoặc `make ci`).
4. Mở PR vào `main`. Sau khi merge:
   - Đánh tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push origin vX.Y.Z`
5. Merge ngược lại `develop` để đồng bộ.

#### B. Hotfix Flow
1. Tạo `hotfix/<desc>` trực tiếp từ `main`.
2. Sửa lỗi, verify với `make verify`.
3. Mở PR vào `main`. Sau khi merge:
   - Đánh tag PATCH version mới: `git tag -a vX.Y.(Z+1) -m "Hotfix vX.Y.(Z+1)"`
4. Merge ngược lại `develop` (hoặc `release/*` nếu đang có release branch mở).

---

### 3. Commit Message Standards (Conventional Commits)

Format:
```text
<type>(<scope>): <short description>

[body - optional]
```

- **Allowed types:**
  - `feat`: A new SDK capability or public feature.
  - `fix`: A bug fix.
  - `refactor`: Code restructuring without changing behavior.
  - `perf`: Code optimization to improve performance.
  - `chore`: Tooling, dependencies, or configuration changes.
  - `ci`: Continuous-integration configuration or gates.
  - `docs`: Documentation updates.
  - `test`: Adding or modifying tests.
  - `revert`: Reverting a previous commit.

- **Rules:**
  - Tiếng Anh, câu mệnh lệnh, viết thường.
  - Dòng đầu tối đa 72 ký tự, **không** có dấu chấm ở cuối.
  - Nhóm commit logic (Atomic commits), không tạo commit rác blob.

---

### 4. PR & Collaboration Rules

1. **Rebase First:** Luôn `git fetch && git rebase origin/develop` trước khi mở PR để giữ git graph tuyến tính, tránh merge commit thừa.
2. **Squash Merge:** Khuyến nghị squash commit khi merge `feature/*` vào `develop` để giữ lịch sử develop sạch.
3. **NO Co-author Metadata:** Không đính kèm co-author (`Co-authored-by: ...`) vào commit message.
4. **Pre-PR Checklist:**
   - [ ] `make verify` chạy thành công (0 lint issues, tests pass 100%).
   - [ ] Không có secret, credential hoặc log debug thừa.
   - [ ] Không tự tạo git worktrees nếu không có chỉ định riêng.
