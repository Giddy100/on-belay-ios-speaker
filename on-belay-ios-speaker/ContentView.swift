//
//  ContentView.swift
//  on-belay-ios
//
//  Created by Giddy Hollander on 28/04/2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var firebaseService = FirebaseService.shared

    var body: some View {
        if firebaseService.currentUser != nil {
            MainScreen()
                .environment(\.layoutDirection, isHebrew ? .rightToLeft : .leftToRight)
        } else {
            LoginView()
                .environment(\.layoutDirection, isHebrew ? .rightToLeft : .leftToRight)
        }
    }
    
    var isHebrew: Bool {
        Locale.current.language.languageCode?.identifier == "he"
    }

}
