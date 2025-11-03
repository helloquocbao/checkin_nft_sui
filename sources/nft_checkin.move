module nft_checkin::profiles;

use nft_checkin::utils_random;
use std::string;
use sui::clock;
use sui::coin::{Self, Coin};
use sui::display;
use sui::dynamic_field as df;
use sui::event;
use sui::package;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::tx_context::sender;

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

public struct ProfileRegistry has key {
    id: UID,
    deployer: address,
    total_profiles: u64,
    minted_users: Table<address, bool>,
}

public struct PROFILES has drop {}

public struct BadgeKey has copy, drop, store { location_id: u64 }

public struct Badge has drop, store {
    location_name: string::String,
    description: string::String,
    image_url: string::String,
    rarity: u8,
    perfection: u64,
    created_at: u64,
}

public struct LocationRegistry has key {
    id: UID,
    deployer: address,
    total_locations: u64,
    locations: Table<u64, BadgeTemplate>,
}

public struct BadgeTemplate has copy, drop, store {
    location_name: string::String,
    description: string::String,
    image_common: string::String,
    image_rare: string::String,
    image_epic: string::String,
    image_legendary: string::String,
}

public struct ProfileCreated has copy, drop {
    profile_id: address,
    owner: address,
    name: string::String,
}

public struct BadgeClaimed has copy, drop {
    profile_id: address,
    owner: address,
    location_id: u64,
}

/// 🎰 Kết quả quay huy hiệu (dùng cho frontend hiển thị)
public struct BadgeGachaResult has copy, drop {
    owner: address,
    location_id: u64,
    rarity: u8,
    perfection: u64,
    timestamp: u64,
}

fun init(otw: PROFILES, ctx: &mut tx_context::TxContext) {
    let publisher = package::claim(otw, ctx);
    let mut display = display::new<ProfileNFT>(&publisher, ctx);
    display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name}"));
    display::add(&mut display, string::utf8(b"description"), string::utf8(b"{bio}"));
    display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{avatar_url}"));
    display::add(&mut display, string::utf8(b"creator"), string::utf8(b"Memory token"));
    display::update_version(&mut display);

    let deployer = sender(ctx);
    let registry = ProfileRegistry {
        id: object::new(ctx),
        deployer,
        total_profiles: 0,
        minted_users: table::new(ctx),
    };

    transfer::share_object(registry);
    transfer::public_transfer(publisher, deployer);
    transfer::public_transfer(display, deployer);
}

entry fun mint_profile(
    registry: &mut ProfileRegistry,
    name: string::String,
    bio: string::String,
    avatar_url: string::String,
    social_links: vector<string::String>,
    country: string::String,
    payment: Coin<SUI>,
    clock: &clock::Clock,
    ctx: &mut tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(!table::contains(&registry.minted_users, sender_addr), 1);

    let fee_amount = 10_000_000;
    let balance = coin::value(&payment);
    assert!(balance >= fee_amount, 10);

    let mut pay = payment;
    let fee_coin = coin::split<SUI>(&mut pay, fee_amount, ctx);
    transfer::public_transfer(fee_coin, registry.deployer);
    transfer::public_transfer(pay, sender_addr);

    table::add(&mut registry.minted_users, sender_addr, true);
    registry.total_profiles = registry.total_profiles + 1;

    let profile_nft = ProfileNFT {
        id: object::new(ctx),
        owner: sender_addr,
        name,
        bio,
        avatar_url,
        social_links,
        country,
        created_at: clock::timestamp_ms(clock),
        claimed_badges: vector::empty<u64>(),
        badge_count: 0,
    };

    event::emit(ProfileCreated {
        profile_id: object::uid_to_address(&profile_nft.id),
        owner: sender_addr,
        name: profile_nft.name,
    });

    transfer::transfer(profile_nft, sender_addr);
}

entry fun add_location(
    registry: &mut LocationRegistry,
    name: string::String,
    description: string::String,
    image_common: string::String,
    image_rare: string::String,
    image_epic: string::String,
    image_legendary: string::String,
    ctx: &tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(sender_addr == registry.deployer, 100);
    let id = registry.total_locations;
    let template = BadgeTemplate {
        location_name: name,
        description,
        image_common,
        image_rare,
        image_epic,
        image_legendary,
    };
    table::add(&mut registry.locations, id, template);
    registry.total_locations = id + 1;
}

fun image_for_rarity(rarity: u8, template: &BadgeTemplate): string::String {
    if (rarity == 0) {
        template.image_common
    } else if (rarity == 1) {
        template.image_rare
    } else if (rarity == 2) {
        template.image_epic
    } else {
        template.image_legendary
    }
}

/// 🏅 Claim (Gacha) badge cho 1 địa điểm
entry fun claim_badge(
    profile: &mut ProfileNFT,
    registry: &LocationRegistry,
    location_id: u64,
    payment: Coin<SUI>,
    clock: &clock::Clock,
    ctx: &mut tx_context::TxContext,
) {
    let sender_addr = sender(ctx);
    assert!(profile.owner == sender_addr, 1);

    // 💰 Thu phí claim gacha = 0.01 SUI
    let fee_amount = 10_000_000; // 0.01 SUI = 10^7 MIST
    let balance = coin::value(&payment);
    assert!(balance >= fee_amount, 10);

    let mut pay = payment;
    let fee_coin = coin::split<SUI>(&mut pay, fee_amount, ctx);
    transfer::public_transfer(fee_coin, registry.deployer);
    transfer::public_transfer(pay, sender_addr);

    // 🎲 Random hóa độ hiếm và độ hoàn hảo
    let template = table::borrow(&registry.locations, location_id);
    let rarity_seed = utils_random::random_number(ctx, 0, 99);
    let rarity_level: u8 = if (rarity_seed < 60) { 0 } else if (rarity_seed < 85) { 1 } else if (
        rarity_seed < 97
    ) { 2 } else { 3 };
    let perfection = utils_random::random_number(ctx, 250, 1000);
    let img_url = image_for_rarity(rarity_level, template);

    // 🧱 Tạo badge mới
    let badge = Badge {
        location_name: template.location_name,
        description: template.description,
        image_url: img_url,
        rarity: rarity_level,
        perfection,
        created_at: clock::timestamp_ms(clock),
    };

    let key = BadgeKey { location_id };

    // 🧱 Ghi đè badge cũ (nếu có)
    df::remove<BadgeKey, Badge>(&mut profile.id, key);
    df::add<BadgeKey, Badge>(&mut profile.id, key, badge);

    // 🧾 Cập nhật danh sách claimed (chỉ thêm nếu chưa có)
    let mut found = false;
    let count = vector::length(&profile.claimed_badges);
    let mut i = 0;
    while (i < count) {
        if (vector::borrow(&profile.claimed_badges, i) == &location_id) {
            found = true;
            break
        };
        i = i + 1;
    };
    if (!found) {
        vector::push_back(&mut profile.claimed_badges, location_id);
        profile.badge_count = profile.badge_count + 1;
    };

    // 🔔 Emit event GachaResult để frontend hiển thị kết quả quay
    event::emit(BadgeGachaResult {
        owner: sender_addr,
        location_id,
        rarity: rarity_level,
        perfection,
        timestamp: clock::timestamp_ms(clock),
    });

    // 🔔 Event chính thức ghi nhận (dành cho indexer / backend)
    event::emit(BadgeClaimed {
        profile_id: object::uid_to_address(&profile.id),
        owner: sender_addr,
        location_id,
    });
}

public fun total_profiles(registry: &ProfileRegistry): u64 { registry.total_profiles }

public fun has_minted(registry: &ProfileRegistry, user: address): bool {
    table::contains(&registry.minted_users, user)
}
