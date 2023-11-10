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
    
    var body: some View {
        VStack {
            // Tampilkan gambar kartu
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
            
            // Tampilkan nama kartu
            Text(card.name)
                .font(.title)
                .padding()
            
            // Tampilkan jenis kartu dan teks orakel wrapped in a frame
            FrameView {
                Text("Type: \(card.type_line)")
                Text("Oracle Text: \(card.oracle_text)")
            }
            .padding()
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
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}


struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isSortingAscending = true


    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3) // Three cards per row

    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    HStack {
                        // Search Bar
                        SearchBar(searchText: $searchText)
                            .padding()

                        // Sort Button
                        Button(action: {
                            isSortingAscending.toggle()
                            sortMTGCardsByName()
                        }) {
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
                                    .frame(height: 300) // Adjust the image height as needed
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    // Load data from a JSON file
                    if let data = loadJSON() {
                        do {
                            let decoder = JSONDecoder()
                            let cards = try decoder.decode(MTGCardList.self, from: data)
                            mtgCards = cards.data
                        } catch {
                            print("Error decoding JSON: \(error)")
                        }
                    }
                }
                .navigationBarTitle("MTG Cards")
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }

          
        }
    }

    // Function to load data from a JSON file
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
                .frame(height: 200) // Adjust the frame height
            
            VStack {
                // Card image
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
                
                // Text under the image
                Text(card.name)
                    .font(.system(size: 14)) // Adjust the size (e.g., 14) to your preference
                    .padding(.top, 8) // Adjust the padding as needed
            }
        }
    }
}
