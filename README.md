# 🧱 Sui Move Module: `nft_checkin::profiles`

Module `nft_checkin::profiles` triển khai **NFT Profile System** cho người dùng trên blockchain Sui.
Mỗi người dùng chỉ có thể mint một **Profile NFT duy nhất**, dùng để quản lý thông tin cá nhân, thống kê số lần check-in, chứng chỉ đạt được và hiển thị công khai qua Display Object.

---

## ✨ Tính năng chính

### 1. **NFT Profile**

- Mỗi người dùng mint một NFT duy nhất, **không thể chuyển nhượng**.
- Chứa thông tin cơ bản của người dùng:

  - `name`, `bio`, `avatar_url`
  - `social_links`: danh sách liên kết mạng xã hội
  - `listAddressCheckin`: danh sách địa điểm check-in
  - `checkpoints`: số điểm check-in
  - `certificate_count`: số chứng chỉ đạt được
  - `created_at`: thời điểm tạo

---

### 2. **Profile Registry**

- Là một **Shared Object** quản lý toàn bộ Profile trên hệ thống.
- Theo dõi:

  - Tổng số profile đã mint (`total_profiles`)
  - Danh sách người dùng đã mint (`minted_users: Table<address, bool>`)
  - Địa chỉ người triển khai (`deployer`)

---

### 3. **Phí Mint Profile**

- Người dùng phải thanh toán **0.01 SUI** khi mint profile.
- Phí được gửi đến ví `registry.deployer`.
- Nếu user không đủ SUI, giao dịch sẽ thất bại (error code `10`).

---

### 4. **Sự kiện (Events)**

| Event            | Mục đích                                  |
| ---------------- | ----------------------------------------- |
| `ProfileCreated` | Phát ra khi người dùng mint profile mới   |
| `ProfileUpdated` | Phát ra khi người dùng cập nhật thông tin |

---

## 🧩 Cấu trúc dữ liệu

### `struct ProfileNFT`

| Trường               | Kiểu dữ liệu             | Mô tả                       |
| -------------------- | ------------------------ | --------------------------- |
| `id`                 | `UID`                    | Định danh duy nhất của NFT  |
| `owner`              | `address`                | Địa chỉ chủ sở hữu          |
| `name`               | `string::String`         | Tên hiển thị                |
| `bio`                | `string::String`         | Mô tả cá nhân               |
| `avatar_url`         | `string::String`         | Ảnh đại diện                |
| `social_links`       | `vector<string::String>` | Danh sách mạng xã hội       |
| `listAddressCheckin` | `vector<string::String>` | Danh sách địa điểm check-in |
| `checkpoints`        | `u64`                    | Tổng số lần check-in        |
| `certificate_count`  | `u64`                    | Tổng số chứng chỉ           |
| `created_at`         | `u64`                    | Thời điểm tạo (timestamp)   |

---

## ⚙️ Các hàm chính

### 🔹 `init(otw: PROFILES, ctx: &mut TxContext)`

Khởi tạo hệ thống:

- Tạo `display` cho NFT Profile
- Tạo `ProfileRegistry` làm shared object
- Trả `publisher` và `display` cho deployer

---

### 🔹 `entry fun mint_profile(...)`

Mint một Profile NFT mới:

- Kiểm tra chưa mint trước đó
- Kiểm tra đủ tiền (>= 0.01 SUI)
- Tạo `ProfileNFT`
- Ghi vào `minted_users`
- Emit sự kiện `ProfileCreated`
- Chuyển NFT về ví người dùng

**Error codes:**

| Mã   | Mô tả                  |
| ---- | ---------------------- |
| `1`  | User đã mint trước đó  |
| `10` | Không đủ số dư để mint |

---

### 🔹 `entry fun update_profile(...)`

Cập nhật thông tin NFT (chỉ owner được phép):

- Thay đổi `name`, `bio`, `avatar_url`, `social_links`
- Phát sự kiện `ProfileUpdated`

---

### 🔹 View functions

| Hàm                              | Mô tả                       |
| -------------------------------- | --------------------------- |
| `owner(profile)`                 | Trả về địa chỉ owner        |
| `avatar_url(profile)`            | Lấy URL ảnh đại diện        |
| `name(profile)`                  | Lấy tên người dùng          |
| `bio(profile)`                   | Lấy mô tả                   |
| `social_links(profile)`          | Lấy danh sách mạng xã hội   |
| `created_at(profile)`            | Lấy timestamp tạo profile   |
| `get_certificate_count(profile)` | Lấy tổng chứng chỉ          |
| `total_profiles(registry)`       | Lấy tổng số profile đã mint |
| `has_minted(registry, user)`     | Kiểm tra user đã mint chưa  |

---

## 💸 Logic thu phí

1. Người dùng gửi `Coin<SUI>` vào hàm `mint_profile`.
2. Hệ thống tách ra:

   - 0.01 SUI gửi cho `registry.deployer`
   - Phần dư trả lại user

3. Nếu user không đủ 0.01 SUI → **assert fail (error code 10)**.

---

## 📦 Deploy & Test

### 🧩 1. Deploy module

```bash
sui client publish --gas-budget 100000000
```

### 🧩 2. Gọi init

```bash
sui client call \
  --function init \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <PROFILES_WITNESS_OBJECT> \
  --gas-budget 10000000
```

### 🧩 3. Mint Profile

```bash
sui client call \
  --function mint_profile \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <REGISTRY_ID> "Duy Raptor" "Full-stack Web3 Developer" \
         "https://via.placeholder.com/400" \
         '["github:duyraptor","twitter:duyraptor"]' \
         <COIN_ID> <CLOCK_ID> \
  --gas-budget 10000000
```

---

## 📚 License

MIT License © 2025 — `nft_checkin::profiles`
