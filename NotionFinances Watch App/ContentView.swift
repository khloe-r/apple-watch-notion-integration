//
//  ContentView.swift
//  NotionFinances Watch App
//
//  Created by Khloe R on 2023-12-26.
//

import SwiftUI

struct RowView: View {
    var title: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .foregroundColor(.primary)
                .font(.headline)
            
        }
    }
}

// Request

struct Filter: Codable {
    let value: String
    let property: String
}

struct Sort: Codable {
    let direction: String
    let timestamp: String
}

struct QueryObject: Codable {
    let query: String
    let filter: Filter
    let sort: Sort
}

// Response

struct Annotation: Codable {
    let bold: Bool
    let italic: Bool
    let strikethrough: Bool
    let underline: Bool
    let code: Bool
    let color: String
}

struct TextContent: Codable {
    let content: String
    let link: String? // Replace with appropriate type if needed
}

struct TextInfo: Codable {
    let type: String
    let text: TextContent
    let annotations: Annotation
    let plain_text: String
    let href: String? // Replace with appropriate type if needed
}

struct User: Codable {
    let object: String
    let id: String
}

struct Property: Codable {
    let id: String
    let name: String
    let type: String
    let rich_text: [String: String]? // Replace with appropriate type if needed
    let number: [String: String]? // Replace with appropriate type if needed
    let multi_select: [String: [Option]]? // Replace with appropriate type if needed
    let date: [String: String]? // Replace with appropriate type if needed
    let title: [String: String]? // Replace with appropriate type if needed
}

struct Option: Codable {
    let id: String
    let name: String
    let color: String
    let description: String?
}

struct ResultsItem: Codable, Identifiable {
    let object: String
    let id: String
    let cover: String? // Replace with appropriate type if needed
    let icon: String? // Replace with appropriate type if needed
    let created_time: String
    let created_by: User
    let last_edited_by: User
    let last_edited_time: String
    let title: [TextInfo]
    let description: [String]? // Replace with appropriate type if needed
    let is_inline: Bool
    let properties: [String: Property] // Property names are dynamically generated
    let parent: Parent
    let url: String
    let public_url: String? // Replace with appropriate type if needed
    let archived: Bool
}

struct Parent: Codable {
    let type: String
    let page_id: String
}

struct PageOrDatabase: Codable {
    // If needed, define properties for "page_or_database"
}

struct QueryResult: Codable {
    let object: String
    let results: [ResultsItem]
    let next_cursor: String?
    let has_more: Bool
    let type: String
    let page_or_database: PageOrDatabase
    // Add more properties if needed
    let developer_survey: String?
    let request_id: String
    
    init() {
        // Set default values for the properties
        self.object = ""
        self.results = []
        self.next_cursor = nil
        self.has_more = false
        self.type = ""
        self.page_or_database = PageOrDatabase()
        self.developer_survey = nil
        self.request_id = "" // Assuming PageOrDatabase has a default initializer
    }
}

struct ContentView: View {
    @State private var database: String = ""
    @State private var databaseList: [ResultsItem]? = []
    @State private var isLoading: Bool = false
    @State private var isSuccess: Bool = false
    
    func searchDb(completionHandler: @escaping ([ResultsItem]) -> Void) {
        isLoading = true
        
        let filter = Filter(value: "database", property: "object")
        let sort = Sort(direction: "ascending", timestamp: "last_edited_time")
        let queryObject = QueryObject(query: database, filter: filter, sort: sort)
        
        guard let requestData = try? JSONEncoder().encode(queryObject) else {
            return
        }
        
        let url = URL(string: "https://api.notion.com/v1/search")!
        var request = URLRequest(url: url)
            
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        if let apiSecret = ProcessInfo.processInfo.environment["NOTION_API_SECRET"] {
            request.addValue("Bearer \(apiSecret)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.uploadTask(with: request, from: requestData) { data, response, error in
                if let error = error {
                    print ("error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode) else {
                    isLoading = false
                    print ("server error")
                    return
                }

            if let data = data,
                    let filmSummary = try? JSONDecoder().decode(QueryResult.self, from: data) {
                    completionHandler(filmSummary.results)
                  }
        }
        task.resume()
    }
    
    func fetchData() {
        searchDb { (films) in
            databaseList = films
            isSuccess = true
            isLoading = false
        }
    }
    
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else if (isSuccess) {
            VStack {
                Text("Success!")
                List {
                    ForEach(databaseList ?? []) { ResultsItem in
                        NavigationLink(destination: UpdateDB(database: ResultsItem)) {
                            RowView(title: ResultsItem.title[0].text.content, icon: "arrowtriangle.right.circle.fill")
                        }
                    }
                }
            }.padding()
        } else {
            VStack {
                Text("Welcome")
                
                Text("Select a Database")
                    .font(.subheadline)
                
                TextField("Database Name", text: $database)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .border(.secondary)
                
                Button(action: fetchData) {
                    Text("Submit")
                }.tint(.green)

            }.padding()
            
        }
    }
}

#Preview {
    ContentView()
}
