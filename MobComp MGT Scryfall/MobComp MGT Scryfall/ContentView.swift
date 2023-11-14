import SwiftUI

struct ItalicText: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.clear // Set background color to clear
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }
}

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
            .opacity(searchText.isEmpty ? 0 : 1)
        }
        .padding()
    }
}

struct MTGCardView: View {
    @Binding var card: MTGCard
    @Binding var currentIndex: Int
    @Binding var mtgCards: [MTGCard]

    @State private var showVersion = false
    @State private var showRuling = false
    @State private var pricingInfo: [CardPricingInfo] = []
    @State private var showLargeImage = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header image with art_crop
                ZStack {
                    AsyncImage(url: URL(string: card.image_uris?.art_crop ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: geometry.size.height / 3)
                                .clipped()
                        case .failure:
                            Color.gray // Placeholder color or image if loading fails
                        case .empty:
                            Color.gray // Placeholder color or image if no data
                        @unknown default:
                            Color.gray // Placeholder color or image for unknown cases
                        }
                    }
                    .onTapGesture {
                        self.showLargeImage.toggle()
                    }
                    .sheet(isPresented: $showLargeImage) {
                        LargeImageView(card: card, imageURL: URL(string: card.image_uris?.large ?? ""))
                    }
                }

                // Content of MTGCardView
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.name)
                        .font(.system(size: 24, weight: .bold)) // Adjust font size and weight as needed
                    Text(card.type_line)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.bottom, 10)

                    FrameView {
                        VStack(alignment: .leading, spacing: 0) {
                            parseAndRenderText(card.oracle_text + "\n\n" + (card.flavor_text ?? ""))
                        }
                        .padding(10) // Add padding to the VStack, adjust as needed
                        .background(
                            RoundedRectangle(cornerRadius: 20) // Adjust the corner radius as needed
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 6, y: 6) // Add a shadow to the background
                                .foregroundColor(Color.white) // Set the background color to light grey with high opacity
                        )
                    }

                    HStack {
                        // Left arrow button
                        Button(action: {
                            if currentIndex > 0 {
                                currentIndex -= 1
                                updateCard()
                            }
                        }) {
                            Image(systemName: "arrow.left.circle")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .padding(.trailing, 8)

                        // Versions button
                        Button(action: {
                            fetchPricingAndLegalities(for: card)
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

                        Spacer()

                        // Ruling button
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

                        // Right arrow button
                        Button(action: {
                            if currentIndex < mtgCards.count - 1 {
                                currentIndex += 1
                                updateCard()
                            }
                        }) {
                            Image(systemName: "arrow.right.circle")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .padding(.leading, 8)
                        
                    }
                    .padding()

                }
                .background(Color.white)
                .padding(10)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }

    private func updateCard() {
        card = mtgCards[currentIndex]
    }
    
    private func parseAndRenderText(_ text: String) -> some View {
        let attributedString = NSMutableAttributedString(string: text)

        // Apply a consistent font size to the entire attributed string
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attributedString.length))

        // Use regular expression to find text inside parentheses and make it italic
        let regex = try? NSRegularExpression(pattern: "\\((.*?)\\)", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)

        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range(at: 1) {
                attributedString.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 16), range: matchRange)
            }
        }

        return ItalicText(attributedText: attributedString)
    }


    struct LargeImageView: View {
        var card: MTGCard
        var imageURL: URL?

        var body: some View {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()

                if let imageURL = imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(20)
                                .padding(20)
                            
                            // Display USD price here
                            Text("$\(card.prices?.usd ?? "N/A")")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.top, 10)
                        case .failure:
                            Text("Failed to load image")
                                .foregroundColor(.white)
                                .padding()
                        case .empty:
                            ProgressView()
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
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
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(legality == "legal" ? Color.green : Color.gray)
                    .cornerRadius(12)
                Spacer()
                Text(format)
            }
            .font(.system(size: 14, weight: .semibold))
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
//            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
    }
}


struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isSortingAscending = true
    @State private var currentIndex = 0

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
                        ForEach(mtgCards.indices.filter {
                            searchText.isEmpty || mtgCards[$0].name.localizedCaseInsensitiveContains(searchText)
                        }, id: \.self) { index in
                            NavigationLink(destination: MTGCardView(card: $mtgCards[index], currentIndex: $currentIndex, mtgCards: $mtgCards)) {
                                CardImageView(card: mtgCards[index])
                                    .frame(height: 220)
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
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }

            Text("THIS MENU IS IN DEVELOPMENT")
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .semibold))
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }

            Text("THIS MENU IS IN DEVELOPMENT")
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .semibold))
                .tabItem {
                    Image(systemName: "folder")
                    Text("Collection")
                }

            Text("THIS MENU IS IN DEVELOPMENT")
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .semibold))
                .tabItem {
                    Image(systemName: "square.stack")
                    Text("Decks")
                }

            Text("THIS MENU IS IN DEVELOPMENT")
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .semibold))
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scan")
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
        VStack(spacing: 0) {
            // Frame with a corner radius
            ZStack {
                AsyncImage(url: URL(string: card.image_uris?.small ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(5)
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
            }
            .frame(height: 200) // Adjust the height as needed
//            .cornerRadius(8)

            // Text with adjusted padding and line limit
            Text(card.name)
                .font(.system(size: 14)) // Adjust font size and weight as needed
                .foregroundColor(.black)
                .lineLimit(2) // Display up to 2 lines of text
                .multilineTextAlignment(.center) // Center-align the text
                .frame(maxWidth: .infinity, alignment: .top) // Expand to fill the width
        }
        .padding(.top, 10)
    }
}
