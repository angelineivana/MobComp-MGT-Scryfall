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
    @Binding var selectedCard: MTGCard?

    @State private var showVersion = false
    @State private var showRuling = false
    @State private var pricingInfo: [CardPricingInfo] = []
    @State private var showLargeImage = false
    @State private var isImagePopupVisible = false
    @State private var isArtCrop = true
    @State private var showLegalities = false
    @State private var legalitiesViewHeight: CGFloat = 0

    let manaCostImageMapping: [String: String] = [
        "1": "satuh",
        "2": "dua",
        "3": "tiga",
        "4": "empat",
        "W": "matahari",
        "7": "tujuh",
        "U": "air",
        "R": "api",
        "B": "tengkorak",
        "G": "pohon"
    ]
    
    private func extractManaSymbols(from manaCost: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "\\{(.*?)\\}", options: [])
        let range = NSRange(location: 0, length: manaCost.utf16.count)

        var symbols: [String] = []

        regex?.enumerateMatches(in: manaCost, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range(at: 1),
                let swiftRange = Range(matchRange, in: manaCost) {
                let symbol = String(manaCost[swiftRange])
                symbols.append(symbol)
            }
        }

        return symbols
    }


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
                    .onTapGesture {
                        print("Image URL: \(card.image_uris?.art_crop ?? "")")
                        isImagePopupVisible.toggle()
                    }
                }
                // Content of MTGCardView
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(card.name)
                            .font(.system(size: 24, weight: .bold)) // Adjust font size and weight as needed
                        Spacer() // Add Spacer to push mana_cost to the right side
                        
                        let symbols = extractManaSymbols(from: card.mana_cost)

                        // Display mana_cost images
                        ForEach(symbols, id: \.self) { symbol in
                            if let manaCostImageName = manaCostImageMapping[symbol] {
                                if let image = UIImage(named: manaCostImageName) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 4)
                                } else {
                                    // Display an error message if the image is not found
                                    Text("Error: Image '\(manaCostImageName)' not found!")
                                        .foregroundColor(.red)  // You can customize the color
                                        .padding(.trailing, 4)
                                }
                            } else {
                                // Display an error message if the mapping is not found
                                Text("Error: Mapping not found for symbol '\(symbol)'")
                                    .foregroundColor(.red)  // You can customize the color
                                    .padding(.trailing, 4)
                            }
                        }

                    }
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
                                .foregroundColor(Color.white.opacity(0.2)) // Set the background color to light grey with high opacity
                                .shadow(color: Color.black.opacity(0.7), radius: 5, x: 6, y: 6) // Add a shadow to the background
                        )
                    }

                    HStack {
                        // Left arrow button
                        Button(action: {
                            if currentIndex > 0 {
                                currentIndex -= 1
                                selectedCard = mtgCards[currentIndex]
                            }
                        }) {
                            Image(systemName: "arrow.left.circle")
                                .imageScale(.large)
                                .foregroundColor(.black)
                                .padding()
                                .opacity(currentIndex > 0 ? 1 : 0) // <-- Update opacity based on index
                        }
                        .padding(.trailing, 8)

                        // Versions button
                        Button(action: {
                            fetchPricingAndLegalities(for: card)
                            // Toggle the showVersion directly without using a sheet
                            self.showVersion.toggle()
                            self.showLegalities = false
                        }) {
                            Text("Versions")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.accentColor.opacity(0.6))
                                .cornerRadius(30)
                        }
                        .onAppear {
                            // Perform the action when the MTGCardView appears
                            fetchPricingAndLegalities(for: card)
                            self.showVersion.toggle()
                            self.showLegalities = false
                        }
                        .background(GeometryReader { proxy in
                            Color.clear.onAppear {
                                let pricingViewHeight = proxy.frame(in: .global).size.height
                                // Pass the height information to the legalities view
                                self.legalitiesViewHeight = pricingViewHeight
                            }
                        })
                        //
//                        .onChange(of: pricingInfo) { _, newPricingInfo in
//                            if !newPricingInfo.isEmpty {
//                                self.showVersion.toggle()
//                            }
//                        }

                        Spacer()

                        // Ruling button
                        Button(action: {
                            self.showLegalities.toggle()
                            self.showVersion = false
                        }) {
                            Text("Ruling")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.accentColor.opacity(0.6))
                                .cornerRadius(30)
                        }
                        
                        // Right arrow button
                        Button(action: {
                            if currentIndex < mtgCards.count - 1 {
                                currentIndex += 1
                                selectedCard = mtgCards[currentIndex]
                            }
                        }) {
                            Image(systemName: "arrow.right.circle")
                                .imageScale(.large)
                                .foregroundColor(.black)
                                .padding()
                                .opacity(currentIndex < mtgCards.count - 1 ? 1 : 0) // <-- Update opacity based on index
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width > 100 {
                                    // Swipe right, navigate to the previous card
                                    if currentIndex > 0 {
                                        currentIndex -= 1
                                        selectedCard = mtgCards[currentIndex]
                                    }
                                } else if value.translation.width < -100 {
                                    // Swipe left, navigate to the next card
                                    if currentIndex < mtgCards.count - 1 {
                                        currentIndex += 1
                                        selectedCard = mtgCards[currentIndex]
                                    }
                                }
                            }
                    )

                    // Display legalities information directly in the view
                    if showLegalities && !showVersion {
                        LegalitiesView(legalities: card.legalities)
//                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 10)
                    }
                    
                    // Display pricing information directly in the view
                    if showVersion && !showLegalities {
                        VStack(alignment: .leading) {
//                            Text("Price Information")
//                                .font(.system(size: 18, weight: .bold))
//                            // Display pricing information
                            ForEach(pricingInfo, id: \.name) { info in
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
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .padding()
                        }
                    }

//                    .onAppear {
//                        if let index = mtgCards.firstIndex(where: { $0.id == card.id }) {
//                            currentIndex = index
//                        }
//                    }

                }
                .background(Color.white)
                .padding(10)
                .onAppear {
                    if let index = mtgCards.firstIndex(where: { $0.id == card.id }) {
                        currentIndex = index
                    }
                }
            }
            .overlay(
                isImagePopupVisible ? AnyView(
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()

                        VStack {
                            if let largeImageUrl = URL(string: card.image_uris?.normal ?? "") {
                                AsyncImage(url: largeImageUrl) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(20)
                                    case .failure:
                                        Text("Failed to load image")
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        ProgressView()
                                    }
                                }
                            }
                            Text("$\(card.prices?.usd ?? "N/A")")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.top, 10)
                        }
                        .padding(.top, 15)
                        .padding(20)

                    }
                    .onTapGesture {
                        isImagePopupVisible.toggle()
                    }
                ) : AnyView(EmptyView())
            )
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    
    private func parseAndRenderText(_ text: String) -> some View {
        let attributedString = NSMutableAttributedString(string: text)

        // Apply a consistent font size to the entire attributed string
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attributedString.length))

        // Use regular expression to find text inside curly braces and replace mana cost symbols
        let regex = try? NSRegularExpression(pattern: "\\{(.*?)\\}", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)

        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range(at: 1),
                let swiftRange = Range(matchRange, in: text) {
                let symbol = String(text[swiftRange])
                if let manaCostImageName = manaCostImageMapping[symbol], let image = UIImage(named: manaCostImageName) {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
                    let imageString = NSAttributedString(attachment: attachment)
                    attributedString.replaceCharacters(in: matchRange, with: imageString)
                }
            }
        }

        return ItalicText(attributedText: attributedString)
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

    func fetchPricingAndLegalities(for card: MTGCard) {
        if let index = mtgCards.firstIndex(where: { $0.id == card.id }) {
            currentIndex = index
        }

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
            VStack(alignment: .leading) {
                Text("Legalities")
                    .font(.system(size: 18, weight: .bold))
                ScrollView {
                    HStack {
                        VStack {
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
                        }
                        VStack {
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
                }
        
            }
//            .padding()
        }
    }

    struct LegalitiesRow: View {
        var format: String
        var legality: String

        var body: some View {
            HStack {
                Text(legality == "legal" ? "LEGAL" : "NOT LEGAL")
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(legality == "legal" ? Color.green : Color.gray)
                    .cornerRadius(12)
                    .font(.system(size: 9, weight: .semibold))
//                    .frame(maxWidth: .infinity)

                Spacer()
                Text(format)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FrameView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(5)
            .cornerRadius(8)
    }
}

struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isSortingAscending = true
    @State private var currentIndex = 0
    @State private var selectedCard: MTGCard?
    @State private var sortByAlphabet = true
    @State private var sortByNumber = false
    @State private var isSortingAlphabetAscending = true
    @State private var isSortingNumberAscending = true


    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    // Search Bar
                    SearchBar(searchText: $searchText)
                        .padding(.leading, 10)
                    VStack(alignment: .leading) {
                        // Sort Button
                        Text("Sort By")
                            .font(.system(size: 18, weight: .semibold)) // Adjust font size and weight as needed
//                            .padding(.top, 10)
                            .padding(.leading, 2) // Add leading padding for alignment

                        HStack {
                            Button(action: {
                                sortByAlphabet.toggle()
                                sortByNumber = false
                                isSortingAlphabetAscending.toggle()
                                sortMTGCards()
                            }) {
                                Text("Alphabet")
                                    .padding(.vertical, 8) // Adjust vertical padding for a smaller height
                                    .padding(.horizontal, 12) // Adjust horizontal padding
                                    .foregroundColor(sortByAlphabet ? .white : .black)
                                    .background(sortByAlphabet ? Color.accentColor.opacity(0.6) : Color.clear)
                                    .cornerRadius(30)
                            }

                            Button(action: {
                                sortByNumber.toggle()
                                sortByAlphabet = false
                                isSortingNumberAscending.toggle()
                                sortMTGCards()
                            }) {
                                Text("Collector Number")
                                    .padding(.vertical, 8) // Adjust vertical padding for a smaller height
                                    .padding(.horizontal, 12) // Adjust horizontal padding
                                    .foregroundColor(sortByNumber ? .white : .black)
                                    .background(sortByNumber ? Color.accentColor.opacity(0.6) : Color.clear)
                                    .cornerRadius(30)
                            }
                            // Button for toggling sorting order
                            Button(action: {
                                if sortByAlphabet {
                                    isSortingAlphabetAscending.toggle()
                                } else if sortByNumber {
                                    isSortingNumberAscending.toggle()
                                }
                                sortMTGCards()
                            }) {
                                Text("↑↓")
                                    .padding()
                                    .foregroundColor(.blue)
                            }
                        }
//                        .padding(.leading, 16) // Add leading padding for alignment
                    }
                

//                    .padding(.horizontal, 16)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mtgCards.indices.filter {
                            searchText.isEmpty || mtgCards[$0].name.localizedCaseInsensitiveContains(searchText)
                        }, id: \.self) { index in
                            NavigationLink(
                                destination: MTGCardView(card: $mtgCards[index], currentIndex: $currentIndex, mtgCards: $mtgCards, selectedCard: $selectedCard),
                                tag: mtgCards[index],  // Use the MTGCard itself as a unique identifier
                                selection: $selectedCard
                            ) {
                                CardImageView(card: mtgCards[index])
                                    .frame(height: 220)
                            }
//                            .onDisappear {
//                                selectedCard = nil
//                            }

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
    
    func sortMTGCards() {
        if sortByAlphabet {
            mtgCards.sort { (card1, card2) in
                let result = card1.name.localizedCaseInsensitiveCompare(card2.name)
                return isSortingAlphabetAscending ? result == .orderedAscending : result == .orderedDescending
            }
        } else if sortByNumber {
            mtgCards.sort { (card1, card2) in
                return isSortingNumberAscending ? card1.collector_number < card2.collector_number : card1.collector_number > card2.collector_number
            }
        }
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
