// MTGCard.swift
import Foundation

struct MTGCard: Codable, Identifiable {
    var id: UUID
    var name: String
    var type_line: String
    var oracle_text: String
    var image_uris: ImageURIs?
    var flavor_text: String?
    var set_name: String?
    var rarity: String?
    var lang: String?
    var prices: Prices?
    var legalities: Legality?

    struct Prices: Codable {
        var usd: String?
        var usd_foil: String?
        var usd_etched: String?  
        var eur: String?
        var eur_foil: String?
        var tix: String?
    }
    
    struct Legality: Codable {
        var standard: String?
        var future: String?
        var gladiator: String?
        var pioneer: String?
        var modern: String?
        var legacy: String?
        var vintage: String?
        var commander: String?
        var oathbreaker: String?
        var alchemy: String?
        var explorer: String?
        var brawl: String?
        var historic: String?
        var historicbrawl: String?
        var pauper: String?
        var paupercommander: String?
        var penny: String?
        var duel: String?
        var oldschool: String?
        var predh: String?
        var premodern: String?
    }

    struct ImageURIs: Codable {
        var small: String?
        var normal: String?
        var large: String?
    }
}

struct MTGCardList: Codable {
    var object: String
    var total_cards: Int
    var has_more: Bool
    var data: [MTGCard]
}
