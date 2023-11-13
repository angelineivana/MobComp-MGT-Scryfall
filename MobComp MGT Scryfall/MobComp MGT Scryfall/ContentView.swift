import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            Button(action: {
                searchText = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
            .opacity(searchText.isEmpty ? 0 : 1)
        }
        .padding()
    }
}

struct MTGCardView: View {
    var card: MTGCard
    @State private var showVersion = false
    @State private var showRuling = false
    @State private var pricingInfo: [CardPricingInfo] = []
    
    var body: some View {
        VStack {
            // Tampilkan gambar kartu
            AsyncImage(url: URL(string: card.image_uris?.large ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.red)
                case .empty:
                    ProgressView()
                @unknown default:
                    ProgressView()
                }
            }
            
            // Tampilkan nama kartu
            Text(card.name)
                .font(.title)
//                .padding()
            Text(card.type_line)

            FrameView {
                VStack {
                    Text(card.oracle_text)
//                        .padding(.trailing)
                        .background(Color.clear)
                    Text(card.flavor_text ?? "")
//                        .padding(.trailing)
                        .background(Color.clear)
                }
            }
            
            HStack {
                Button(action: {
                    fetchPricingAndLegalities(for: card)
                    //                    self.showVersion.toggle()
                }) {
                    Text("Versions")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(30)
                }
                .sheet(isPresented: $showVersion) {
                    CardPricingListView(pricingInfo: pricingInfo)
                }
                .onChange(of: pricingInfo) { _, newPricingInfo in
                    if !newPricingInfo.isEmpty {
                        self.showVersion.toggle()
                    }
                }
                
                Button(action: {
                    self.showRuling.toggle()
                }) {
                    Text("Ruling")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(30)
                }
                .sheet(isPresented: $showRuling) {
                    LegalitiesView(legalities: card.legalities)
                }
            }
            .padding()
        }
    }
    
    struct CardPricingInfo: Codable, Equatable {
        var name: String
        var set: String
        var rarity: String
        var language: String
        var prices: Prices

        struct Prices: Codable, Equatable {
            var usd: String
            var usd_foil: String?
            var eur: String
            var eur_foil: String?
            var tix: String
        }

        static func == (lhs: CardPricingInfo, rhs: CardPricingInfo) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.set == rhs.set &&
                   lhs.rarity == rhs.rarity &&
                   lhs.language == rhs.language &&
                   lhs.prices == rhs.prices
        }
    }

    struct CardPricingListView: View {
        var pricingInfo: [CardPricingInfo]

        var body: some View {
            Text("Pricing Information")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 24)
            VStack {
                List(pricingInfo, id: \.name) { info in
                    VStack(alignment: .leading) {
                        Text("\(info.set): \(info.name)")
                            .font(.headline)

                        Text("#1 · \(info.rarity) · \(info.language) · Nonfoil/Foil")
                            .foregroundColor(.gray)
                        HStack {
                            Text("USD: \(info.prices.usd)")
                            Spacer()
                            Text("EUR: \(info.prices.eur)")
                            Spacer()
                            Text("TIX: \(info.prices.tix)")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.vertical, 8)
                }
                .padding()
            }
        }
    }

    func fetchPricingAndLegalities(for card: MTGCard) {
        pricingInfo = [
            CardPricingInfo(
                name: card.name,
                set: card.set_name ?? "",
                rarity: card.rarity ?? "",
                language: card.lang ?? "",
                prices: CardPricingInfo.Prices(
                    usd: card.prices?.usd ?? "",
                    usd_foil: card.prices?.usd_foil,
                    eur: card.prices?.eur ?? "",
                    eur_foil: card.prices?.eur_foil,
                    tix: card.prices?.tix ?? ""
                )
            )
        ]
    }
    
    struct LegalitiesView: View {
        var legalities: MTGCard.Legality?

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("LEGALITIES")
                    .foregroundColor(.red)
                    .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)
                
                ScrollView {
                    if let standard = legalities?.standard {
                        LegalitiesRow(format: "Standard", legality: standard)
                    }
                    if let future = legalities?.future {
                        LegalitiesRow(format: "Future", legality: future)
                    }
                    if let historic = legalities?.historic {
                        LegalitiesRow(format: "Historic", legality: historic)
                    }
                    if let gladiator = legalities?.gladiator {
                        LegalitiesRow(format: "Gladiator", legality: gladiator)
                    }
                    if let pioneer = legalities?.pioneer {
                        LegalitiesRow(format: "Pioneer", legality: pioneer)
                    }
                    if let explorer = legalities?.explorer {
                        LegalitiesRow(format: "Explorer", legality: explorer)
                    }
                    if let modern = legalities?.modern {
                        LegalitiesRow(format: "Modern", legality: modern)
                    }
                    if let legacy = legalities?.legacy {
                        LegalitiesRow(format: "Legacy", legality: legacy)
                    }
                    if let pauper = legalities?.pauper {
                        LegalitiesRow(format: "Pauper", legality: pauper)
                    }
                    if let vintage = legalities?.vintage {
                        LegalitiesRow(format: "Vintage", legality: vintage)
                    }
                    if let penny = legalities?.penny {
                        LegalitiesRow(format: "Penny", legality: penny)
                    }
                    if let commander = legalities?.commander {
                        LegalitiesRow(format: "Commander", legality: commander)
                    }
                    if let oathbreaker = legalities?.oathbreaker {
                        LegalitiesRow(format: "Oathbreaker", legality: oathbreaker)
                    }
                    if let brawl = legalities?.brawl {
                        LegalitiesRow(format: "Brawl", legality: brawl)
                    }
                    if let historicbrawl = legalities?.historicbrawl {
                        LegalitiesRow(format: "Historic Brawl", legality: historicbrawl)
                    }
                    if let alchemy = legalities?.alchemy {
                        LegalitiesRow(format: "Alchemy", legality: alchemy)
                    }
                    if let paupercommander = legalities?.paupercommander {
                        LegalitiesRow(format: "Pauper Commander", legality: paupercommander)
                    }
                    if let duel = legalities?.duel {
                        LegalitiesRow(format: "Duel", legality: duel)
                    }
                    if let oldschool = legalities?.oldschool {
                        LegalitiesRow(format: "Old School", legality: oldschool)
                    }
                    if let premodern = legalities?.premodern {
                        LegalitiesRow(format: "Premodern", legality: premodern)
                    }
                    if let predh = legalities?.predh {
                        LegalitiesRow(format: "Prismatic", legality: predh)
                    }
                }
                
            }
            .padding()
        }
    }

    struct LegalitiesRow: View {
        var format: String
        var legality: String

        var body: some View {
            HStack {
                Text(legality == "legal" ? "LEGAL" : "NOT LEGAL")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(legality == "legal" ? Color.green : Color.gray)
                    .cornerRadius(8)
                Spacer()
                Text(format)
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal)
        }
    }


}



//struct ExplanationView: View {
//    var explanation: String
//    var title: String
//
//    var body: some View {
//        // Customize the appearance of the explanation view
//        VStack {
//            Text("Test")
//            Spacer()
//        }
//    }
//}

struct FrameView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(5)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}


struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isSortingAscending = true


    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    HStack {
                        // Search Bar
                        SearchBar(searchText: $searchText)
//                            .padding()

                        // Sort Button
                        Button(action: {
                            isSortingAscending.toggle()
                            sortMTGCardsByName()
                        }) {
                            Text("Sort")
                            Image(systemName: isSortingAscending ? "arrow.up" : "arrow.down")
                                .imageScale(.large)
                                .padding()
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mtgCards.filter {
                            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                        }) { card in
                            NavigationLink(destination: MTGCardView(card: card)) {
                                CardImageView(card: card)
                                    .frame(height: 200) // Adjust the image height as needed
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let data = loadJSON() {
                        do {
                            let decoder = JSONDecoder()
                            let cards = try decoder.decode(MTGCardList.self, from: data)
                            mtgCards = cards.data
                            print("Data loaded successfully: \(mtgCards)")
                        } catch {
                            print("Error decoding JSON: \(error)")
                        }
                    } else {
                        print("Failed to load JSON data")
                    }
                }

                .navigationBarTitle("MTG Cards")
            }
        }
    }

    func loadJSON() -> Data? {
        if let path = Bundle.main.path(forResource: "WOT-Scryfall", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return data
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
        return nil
    }
    
    func sortMTGCardsByName() {
        mtgCards.sort(by: { card1, card2 in
            isSortingAscending ? card1.name < card2.name : card1.name > card2.name
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CardImageView: View {
    var card: MTGCard
    
    var body: some View {
        ZStack {
            // Frame with a corner radius
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(radius: 3)
                .frame(height: 200)
            
            VStack {
                AsyncImage(url: URL(string: card.image_uris?.large ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.red)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        ProgressView()
                    }
                }
                
                Text(card.name)
                    .font(.system(size: 14))
                    .padding(.top, 8)
            }
        }
    }
}
