# 🎫 NFT Check-in System on Sui Blockchain

**[English](#english)** | **[Tiếng Việt](#vietnamese)**

---

<a name="english"></a>

# 🌍 ENGLISH VERSION

### 📖 Overview

**NFT Check-in System** is a decentralized application built on Sui blockchain that allows users to collect location-based NFT badges through a check-in mechanism. The system features a unique gacha system for badge rarity and includes a marketplace for trading rare badges.

### ✨ Key Features

#### 1️⃣ **Profile NFT System** (`nft_checkin::profiles`)

- **One Profile Per User**: Each user can mint only one unique Profile NFT
- **Profile Information**:
  - Name, bio, avatar URL
  - Social media links
  - Country
  - Badge collection tracking
  - Creation timestamp
- **Mint Fee**: 0.01 SUI per profile
- **Non-transferable**: Profile NFTs are soul-bound to the owner

#### 2️⃣ **Location Badge System**

- **Admin-managed Locations**: Deployer adds check-in locations with GPS coordinates
- **Badge Template**: Each location has 4 rarity-specific images
  - Common (60% drop rate)
  - Rare (25% drop rate)
  - Epic (12% drop rate)
  - Legendary (3% drop rate)
- **Gacha Mechanism**:
  - Random rarity determination
  - Perfection score: 250-1000 (affects badge quality)
  - Can re-claim same location to upgrade badge

#### 3️⃣ **Badge Marketplace** (`nft_checkin::badge_marketplace`)

- **Trading Requirements**: Only Epic and Legendary badges can be traded
- **Kiosk Integration**: Uses Sui's native Kiosk framework
- **Royalty System**: 5% automatic royalty to creator on every sale
- **Features**:
  - List badges for sale with custom price
  - Buy badges from other users
  - Delist (cancel) listings
  - Transfer Policy enforcement

---

### 🏗️ Architecture

```
nft_checkin/
├── profiles (Main Module)
│   ├── ProfileNFT - User's unique profile
│   ├── ProfileRegistry - Shared object managing all profiles
│   ├── LocationRegistry - Shared object managing locations
│   ├── Badge - Dynamic field attached to Profile
│   └── BadgeTemplate - Location template with GPS & images
│
└── badge_marketplace (Trading Module)
    ├── MarketplaceRegistry - Marketplace configuration
    ├── TradableBadge - Wrapped badge for trading
    ├── BadgeListing - Listing information
    └── TransferPolicy - Royalty enforcement
```

---

### 📊 Data Structures

#### `ProfileNFT`

```move
public struct ProfileNFT has key {
    id: UID,
    owner: address,
    name: string::String,
    bio: string::String,
    avatar_url: string::String,
    social_links: vector<string::String>,
    country: string::String,
    created_at: u64,
    claimed_badges: vector<u64>,
    badge_count: u64,
}
```

#### `Badge` (as Dynamic Field)

```move
public struct Badge has drop, store {
    location_name: string::String,
    description: string::String,
    image_url: string::String,
    rarity: u8,           // 0=Common, 1=Rare, 2=Epic, 3=Legendary
    perfection: u64,      // 250-1000
    created_at: u64,
}
```

#### `BadgeTemplate`

```move
public struct BadgeTemplate has copy, drop, store {
    location_name: string::String,
    description: string::String,
    latitude: string::String,
    longitude: string::String,
    image_common: string::String,
    image_rare: string::String,
    image_epic: string::String,
    image_legendary: string::String,
}
```

---

### 🔧 Main Functions

#### **Profile Module**

| Function         | Description                            | Fee      |
| ---------------- | -------------------------------------- | -------- |
| `mint_profile()` | Create a unique Profile NFT            | 0.01 SUI |
| `add_location()` | Add new check-in location (admin only) | Free     |
| `claim_badge()`  | Claim badge at location (gacha roll)   | 0.01 SUI |

#### **Marketplace Module**

| Function           | Description                     | Restriction         |
| ------------------ | ------------------------------- | ------------------- |
| `list_badge()`     | List badge for sale             | Epic/Legendary only |
| `buy_badge()`      | Purchase badge from marketplace | Any user            |
| `delist_badge()`   | Cancel listing                  | Owner only          |
| `update_royalty()` | Update royalty percentage       | Deployer only       |

---

### 🎲 Gacha System

When claiming a badge, the system randomly determines:

1. **Rarity** (based on probability):

   - Common: 60% chance
   - Rare: 25% chance
   - Epic: 12% chance
   - Legendary: 3% chance

2. **Perfection Score**: Random value between 250-1000

   - Affects badge quality/value
   - Higher perfection = more valuable

3. **Overwrite Mechanism**: Claiming the same location replaces the old badge
   - Useful for hunting better rarity/perfection

---

### 💰 Economic Model

#### Revenue Streams:

- **Profile Minting**: 0.01 SUI → Deployer
- **Badge Claiming**: 0.01 SUI → Deployer
- **Marketplace Royalty**: 5% of sale price → Deployer

#### User Benefits:

- Collect rare badges from various locations
- Trade Epic/Legendary badges for profit
- Build unique profile with badge collection

---

### 🚀 Deployment Guide

#### 1. **Build the Project**

```bash
sui move build
```

#### 2. **Publish to Network**

```bash
sui client publish --gas-budget 100000000
```

#### 3. **Initialize Location Registry**

After deployment, call the init function to create shared objects.

#### 4. **Add Locations** (Admin Only)

```bash
sui client call \
  --function add_location \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <LOCATION_REGISTRY_ID> \
         "Eiffel Tower" \
         "Iconic landmark in Paris" \
         "48.8584" "2.2945" \
         "https://common.jpg" \
         "https://rare.jpg" \
         "https://epic.jpg" \
         "https://legendary.jpg" \
  --gas-budget 10000000
```

#### 5. **Users Can Mint Profile**

```bash
sui client call \
  --function mint_profile \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <REGISTRY_ID> \
         "Alice" \
         "World traveler" \
         "https://avatar.jpg" \
         '["twitter:alice"]' \
         "USA" \
         <COIN_OBJECT_ID> \
         <CLOCK_OBJECT_ID> \
  --gas-budget 10000000
```

---

### ⚠️ Error Codes

| Code  | Module      | Description                                       |
| ----- | ----------- | ------------------------------------------------- |
| `1`   | Both        | Not the owner of Profile/Badge                    |
| `2`   | Marketplace | Insufficient payment                              |
| `3`   | Marketplace | No access to Kiosk                                |
| `4`   | Marketplace | **Badge rarity too low (must be Epic/Legendary)** |
| `10`  | Profile     | Insufficient balance for minting                  |
| `100` | Both        | Not the deployer                                  |
| `101` | Marketplace | Royalty too high (max 20%)                        |

---

### 📢 Events

#### Profile Module Events:

- `ProfileCreated`: Emitted when user mints profile
- `BadgeClaimed`: Emitted when badge is claimed
- `BadgeGachaResult`: Contains rarity & perfection for frontend display

#### Marketplace Module Events:

- `BadgeListed`: Emitted when badge is listed
- `BadgeSold`: Emitted when badge is purchased
- `BadgeDelisted`: Emitted when listing is cancelled

---

### 🛠️ Tech Stack

- **Blockchain**: Sui Network
- **Language**: Move 2024.beta
- **Framework**: Sui Framework
- **Features**: Kiosk, Transfer Policy, Dynamic Fields, Display Objects

---

### 📝 License

MIT License © 2025

### 👨‍💻 Developer

**Repository**: [helloquocbao/checkin_nft_sui](https://github.com/helloquocbao/checkin_nft_sui)

For questions or contributions, please open an issue on GitHub.

---

**Built with ❤️ on Sui Blockchain**

---

---

---

<a name="vietnamese"></a>

# 🇻🇳 PHIÊN BẢN TIẾNG VIỆT

## 📖 Tổng quan

**NFT Check-in System** là ứng dụng phi tập trung trên blockchain Sui cho phép người dùng thu thập huy hiệu NFT dựa trên vị trí thông qua cơ chế check-in. Hệ thống có cơ chế gacha độc đáo cho độ hiếm của huy hiệu và marketplace để giao dịch các huy hiệu hiếm.

---

## ✨ Tính năng chính

### 1️⃣ **Hệ thống Profile NFT** (`nft_checkin::profiles`)

- **Một Profile cho mỗi người**: Mỗi user chỉ được mint một Profile NFT duy nhất
- **Thông tin Profile**:
  - Tên, tiểu sử, ảnh đại diện
  - Link mạng xã hội
  - Quốc gia
  - Theo dõi bộ sưu tập huy hiệu
  - Thời gian tạo
- **Phí Mint**: 0.01 SUI mỗi profile
- **Không chuyển nhượng**: Profile NFT gắn chặt với chủ sở hữu

### 2️⃣ **Hệ thống Badge theo địa điểm**

- **Địa điểm do Admin quản lý**: Deployer thêm các địa điểm check-in với tọa độ GPS
- **Badge Template**: Mỗi địa điểm có 4 ảnh theo độ hiếm
  - Common - Phổ thông (tỉ lệ 60%)
  - Rare - Hiếm (tỉ lệ 25%)
  - Epic - Sử thi (tỉ lệ 12%)
  - Legendary - Huyền thoại (tỉ lệ 3%)
- **Cơ chế Gacha**:
  - Xác định độ hiếm ngẫu nhiên
  - Điểm hoàn hảo: 250-1000 (ảnh hưởng chất lượng badge)
  - Có thể claim lại cùng địa điểm để nâng cấp badge

### 3️⃣ **Chợ Giao dịch Badge** (`nft_checkin::badge_marketplace`)

- **Yêu cầu Giao dịch**: Chỉ badge Epic và Legendary được phép trade
- **Tích hợp Kiosk**: Sử dụng Kiosk framework gốc của Sui
- **Hệ thống Royalty**: 5% phí bản quyền tự động cho creator mỗi giao dịch
- **Tính năng**:
  - Đăng bán badge với giá tự đặt
  - Mua badge từ người dùng khác
  - Hủy đăng bán
  - Ép buộc Transfer Policy

---

## 🏗️ Kiến trúc

```
nft_checkin/
├── profiles (Module chính)
│   ├── ProfileNFT - Profile độc nhất của user
│   ├── ProfileRegistry - Shared object quản lý tất cả profile
│   ├── LocationRegistry - Shared object quản lý địa điểm
│   ├── Badge - Dynamic field gắn vào Profile
│   └── BadgeTemplate - Template địa điểm với GPS & ảnh
│
└── badge_marketplace (Module Giao dịch)
    ├── MarketplaceRegistry - Cấu hình marketplace
    ├── TradableBadge - Badge được wrap để giao dịch
    ├── BadgeListing - Thông tin đăng bán
    └── TransferPolicy - Ép buộc royalty
```

---

## 🎲 Hệ thống Gacha

Khi claim badge, hệ thống random:

1. **Độ hiếm** (theo xác suất):

   - Common (Phổ thông): 60%
   - Rare (Hiếm): 25%
   - Epic (Sử thi): 12%
   - Legendary (Huyền thoại): 3%

2. **Điểm Hoàn hảo**: Giá trị ngẫu nhiên 250-1000

   - Ảnh hưởng chất lượng/giá trị badge
   - Perfection cao hơn = giá trị cao hơn

3. **Cơ chế Ghi đè**: Claim lại cùng địa điểm sẽ thay thế badge cũ
   - Hữu ích để săn độ hiếm/perfection tốt hơn

---

## 💰 Mô hình Kinh tế

### Nguồn Thu:

- **Mint Profile**: 0.01 SUI → Deployer
- **Claim Badge**: 0.01 SUI → Deployer
- **Royalty Marketplace**: 5% giá bán → Deployer

### Lợi ích User:

- Sưu tập badge hiếm từ nhiều địa điểm
- Trade badge Epic/Legendary để kiếm lời
- Xây dựng profile độc đáo với bộ sưu tập badge

---

## 🚀 Hướng dẫn Deploy

### 1. **Build Project**

```bash
sui move build
```

### 2. **Publish lên Network**

```bash
sui client publish --gas-budget 100000000
```

### 3. **Khởi tạo Location Registry**

Sau khi deploy, gọi hàm init để tạo shared objects.

### 4. **Thêm Địa điểm** (Chỉ Admin)

```bash
sui client call \
  --function add_location \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <LOCATION_REGISTRY_ID> \
         "Tháp Eiffel" \
         "Biểu tượng nổi tiếng ở Paris" \
         "48.8584" "2.2945" \
         "https://common.jpg" \
         "https://rare.jpg" \
         "https://epic.jpg" \
         "https://legendary.jpg" \
  --gas-budget 10000000
```

### 5. **User Mint Profile**

```bash
sui client call \
  --function mint_profile \
  --module profiles \
  --package <PACKAGE_ID> \
  --args <REGISTRY_ID> \
         "Alice" \
         "Du lịch thế giới" \
         "https://avatar.jpg" \
         '["twitter:alice"]' \
         "Việt Nam" \
         <COIN_OBJECT_ID> \
         <CLOCK_OBJECT_ID> \
  --gas-budget 10000000
```

---

## ⚠️ Mã Lỗi

| Mã    | Module      | Mô tả                                            |
| ----- | ----------- | ------------------------------------------------ |
| `1`   | Cả hai      | Không phải chủ sở hữu Profile/Badge              |
| `2`   | Marketplace | Số tiền thanh toán không đủ                      |
| `3`   | Marketplace | Không có quyền truy cập Kiosk                    |
| `4`   | Marketplace | **Độ hiếm badge quá thấp (phải Epic/Legendary)** |
| `10`  | Profile     | Số dư không đủ để mint                           |
| `100` | Cả hai      | Không phải deployer                              |
| `101` | Marketplace | Royalty quá cao (tối đa 20%)                     |

---

## 📢 Sự kiện (Events)

### Events Module Profile:

- `ProfileCreated`: Phát ra khi user mint profile
- `BadgeClaimed`: Phát ra khi claim badge
- `BadgeGachaResult`: Chứa độ hiếm & perfection để frontend hiển thị

### Events Module Marketplace:

- `BadgeListed`: Phát ra khi đăng bán badge
- `BadgeSold`: Phát ra khi mua badge
- `BadgeDelisted`: Phát ra khi hủy đăng bán

---

## 🛠️ Công nghệ

- **Blockchain**: Sui Network
- **Ngôn ngữ**: Move 2024.beta
- **Framework**: Sui Framework
- **Tính năng**: Kiosk, Transfer Policy, Dynamic Fields, Display Objects

---

## 📝 Giấy phép

MIT License © 2025

---

## 👨‍💻 Thông tin Developer

**Repository**: [helloquocbao/checkin_nft_sui](https://github.com/helloquocbao/checkin_nft_sui)

Nếu có câu hỏi hoặc muốn đóng góp, vui lòng mở issue trên GitHub.

---

**Built with ❤️ on Sui Blockchain**
