module nft_checkin::profiles;

use std::string;
use sui::coin::{Self, Coin};
use sui::display;
use sui::event;
use sui::package;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::tx_context::sender;

/// 🧱 NFT Profile - Mỗi user sở hữu 1 NFT profile (không thể trade)
public struct ProfileNFT has key {
    id: UID,
    owner: address,
    name: string::String,
    bio: string::String,
    avatar_url: string::String,
    social_links: vector<string::String>,
    listAddressCheckin: vector<string::String>,
    checkpoints: u64,
    certificate_count: u64,
    created_at: u64,
}

/// 📦 Registry theo dõi tất cả profiles (shared object)
public struct ProfileRegistry has key {
    id: UID,
    deployer: address,
    total_profiles: u64,
    minted_users: Table<address, bool>,
}

/// 🎫 One-Time-Witness để tạo Display
public struct PROFILES has drop {}

/// 🔹 Sự kiện khi profile được tạo
public struct ProfileCreated has copy, drop {
    profile_id: address,
    owner: address,
    name: string::String,
}

/// 🔹 Sự kiện khi profile được cập nhật
public struct ProfileUpdated has copy, drop {
    profile_id: address,
    owner: address,
}

/// 🎯 Init - Tạo Display cho NFT và Registry
fun init(otw: PROFILES, ctx: &mut tx_context::TxContext) {
    let publisher = package::claim(otw, ctx);

    let mut display = display::new<ProfileNFT>(&publisher, ctx);
    display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name}"));
    display::add(&mut display, string::utf8(b"description"), string::utf8(b"{bio}"));
    display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{avatar_url}"));
    display::add(&mut display, string::utf8(b"creator"), string::utf8(b"Memory Profile"));
    display::update_version(&mut display);

    let deployer = sender(ctx);
    // Tạo registry shared
    let registry = ProfileRegistry {
        id: object::new(ctx),
        deployer,
        total_profiles: 0,
        minted_users: table::new(ctx),
    };

    transfer::share_object(registry);

    // Trả lại publisher + display cho deployer
    let deployer = sender(ctx);
    transfer::public_transfer(publisher, deployer);
    transfer::public_transfer(display, deployer);
}

/// 🧍‍♂️ Mint Profile NFT (thu phí 0.01 SUI gửi về deployer)
entry fun mint_profile(
    registry: &mut ProfileRegistry,
    name: string::String,
    bio: string::String,
    avatar_url: string::String,
    social_links: vector<string::String>,
    payment: Coin<SUI>,
    clock: &sui::clock::Clock,
    ctx: &mut tx_context::TxContext,
) {
    let sender_addr = sender(ctx);

    // ⛔ Kiểm tra đã mint chưa
    assert!(!table::contains(&registry.minted_users, sender_addr), 1);

    // === 💵 Thu phí mint ===
    let fee_amount = 10_000_000; // 0.01 SUI = 10^9 * 0.01
// ✅ Kiểm tra user đủ tiền chưa
    let balance = coin::value(&payment);
    assert!(balance >= fee_amount, 10); // Error code 10: Insufficient balance

    let mut pay = payment; // tạo bản mutable để split
    let fee_coin = coin::split<SUI>(&mut pay, fee_amount, ctx); // ✅ đúng cách

    // ✅ Gửi phí về ví deployer (là người deploy package)
    transfer::public_transfer(fee_coin, registry.deployer);

    // ✅ Trả lại phần dư (nếu có)
    transfer::public_transfer(pay, sender_addr);

    // === 🧱 Tạo NFT ===
    table::add(&mut registry.minted_users, sender_addr, true);

    let profile_nft = ProfileNFT {
        id: object::new(ctx),
        owner: sender_addr,
        name,
        bio,
        avatar_url,
        social_links,
        listAddressCheckin: vector::empty<string::String>(),
        checkpoints: 0,
        certificate_count: 0,
        created_at: sui::clock::timestamp_ms(clock),
    };

    registry.total_profiles = registry.total_profiles + 1;
 assert!(!table::contains(&registry.minted_users, sender_addr), 1);
    event::emit(ProfileCreated {
        profile_id: object::uid_to_address(&profile_nft.id),
        owner: sender_addr,
        name: profile_nft.name,
    });

    transfer::transfer(profile_nft, sender_addr);
}

/// ✏️ Cập nhật Profile NFT (chỉ owner mới được update)
entry fun update_profile(
    profile: &mut ProfileNFT,
    name: string::String,
    bio: string::String,
    avatar_url: string::String,
    social_links: vector<string::String>,
    ctx: &tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(profile.owner == sender_addr, 2);

    profile.name = name;
    profile.bio = bio;
    profile.avatar_url = avatar_url;
    profile.social_links = social_links;

    event::emit(ProfileUpdated {
        profile_id: object::uid_to_address(&profile.id),
        owner: sender_addr,
    });
}

// === View Functions ===
public fun owner(profile: &ProfileNFT): address { profile.owner }

public fun avatar_url(profile: &ProfileNFT): string::String { profile.avatar_url }

public fun name(profile: &ProfileNFT): string::String { profile.name }

public fun bio(profile: &ProfileNFT): string::String { profile.bio }

public fun social_links(profile: &ProfileNFT): vector<string::String> { profile.social_links }

public fun created_at(profile: &ProfileNFT): u64 { profile.created_at }

public fun get_certificate_count(profile: &ProfileNFT): u64 { profile.certificate_count }

public fun total_profiles(registry: &ProfileRegistry): u64 { registry.total_profiles }

public fun has_minted(registry: &ProfileRegistry, user: address): bool {
    table::contains(&registry.minted_users, user)
}
