//
//  AddFinance.swift
//  NotionFinances Watch App
//
//  Created by Khloe R on 2023-12-26.
//

import SwiftUI

struct ParentData: Codable {
    let database_id: String
}

// Date

struct StartData: Codable {
    let start: String
}

struct DateData: Codable {
    let date: StartData
}

// Amount

struct AmountData: Codable {
    let number: Double
}

// Category

struct CategoryData: Codable {
    let multi_select: [MultiSelectData]
}

struct MultiSelectData: Codable {
    let name: String
}

// Expense

struct ExpenseCatData: Codable {
    let title: [TitleData]
}

struct TitleData: Codable {
    let text: TextData
}

struct TextData: Codable {
    let content: String
}


struct PropertyData: Codable {
    let Expense: ExpenseCatData
    let Date: DateData
    let Category: CategoryData
    let Amount: AmountData
}

struct ExpenseData: Codable {
    let parent: ParentData
    let properties: PropertyData
}

struct UpdateDB: View {
    @State private var expense: String = ""
    @State private var value = 0.0
    @State private var selectedCategory: ExpenseCategory = .Food
    
    @State private var database: ResultsItem
    
    @State private var isLoading: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isError: Bool = false
    
    init(database: ResultsItem) {
        self.database = database
    }
    
    enum ExpenseCategory: String, CaseIterable, Identifiable {
        case Income, Food, Entertainment, Other, School, Gifts, Home
        var id: Self { self }
    }
    
    func incrementStep() {
        value += 0.5
    }


    func decrementStep() {
        value -= 0.5
    }
    
    func addExpense() {
        isLoading = true
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let result = formatter.string(from: date)
        
        let objData = ExpenseData(parent: ParentData(database_id: database.id), properties: PropertyData(Expense: ExpenseCatData(title: [TitleData(text: TextData(content: expense))]), Date: DateData(date: StartData(start: result)), Category: CategoryData(multi_select: [MultiSelectData(name: selectedCategory.rawValue)]), Amount: AmountData(number: value)))
        
        guard let requestData = try? JSONEncoder().encode(objData) else {
            return
        }
        if let JSONString = String(data: requestData, encoding: String.Encoding.utf8)
        {
            print(JSONString)
        }
        print(String(data: requestData, encoding: .utf8)!)
        
        let url = URL(string: "https://api.notion.com/v1/pages")!
        var request = URLRequest(url: url)
            
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        if let apiSecret = ProcessInfo.processInfo.environment["NOTION_API_SECRET"] {
            request.addValue("Bearer \(apiSecret)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.uploadTask(with: request, from: requestData) { data, response, error in
            if let error = error {
                isLoading = false
                isError = true
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                isLoading = false
                isError = true
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                isLoading = false
                isSuccess = true
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else if (isSuccess) {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.green)
                Text("Success!")
            }.padding()
        } else if (isError) {
            VStack {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
                Text("Error!")
            }.padding()
        } else {
            NavigationView {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("\(database.title[0].text.content)")
                                    .font(.subheadline)
                                
                                TextField("Expense", text: $expense)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .border(.secondary)
                                
                                Stepper {
                                    Text("$\(value, specifier: "%.2f")").font(.system(size: 28))
                                } onIncrement: {
                                    incrementStep()
                                } onDecrement: {
                                    decrementStep()
                                }
                                .padding(5)
                                
                                List {
                                        Picker("Category", selection: $selectedCategory) {
                                            ForEach(ExpenseCategory.allCases) { expense in
                                                Text(expense.rawValue)
                                            }
                                        }
                                        .labelsHidden()
                                        
                                    }
                                    .padding()
                                    .frame(minHeight: 75, maxHeight: .infinity).scrollDisabled(true)
                                
                                Button(action: addExpense) {
                                    Text("Submit")
                                }.tint(.green)
                                
                                }
                            
                        }
                    }
            .navigationBarHidden(true)
            
        }
        
    }
}
