//
//  FriendSearchView.swift
//  Calm
//
//  Created by Remi Santos on 08/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import SwiftUI
import UIKit
import PanModal

class FriendSearchViewPresenter: SwiftUIViewPresenterDelegate {
    var viewController: FriendSearchViewHostingController?
    override init() {
        super.init()
        viewController = FriendSearchViewHostingController(rootView: AnyView(FriendSearchView(delegate: self)))
        host = viewController
    }
}

class FriendSearchViewHostingController: UIHostingController<AnyView>, PanModalPresentable{
    var panScrollable: UIScrollView? {
        return nil
    }
}

struct FriendSearchView: View {
    @ObservedObject var presenterDelegate: SwiftUIViewPresenterDelegate
    @ObservedObject var listVM: UserSearchListViewModel

    @State private var searchText: String = ""
    
    init(delegate: SwiftUIViewPresenterDelegate = SwiftUIViewPresenterDelegate(), listVM: UserSearchListViewModel = UserSearchListViewModel()) {
        self.listVM = listVM
        self.presenterDelegate = delegate
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().separatorColor = .clear
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color(AppColor.backgroundColor()).edgesIgnoringSafeArea(.all)
                VStack {
                    SearchBarView(text: Binding(
                        get: { self.searchText },
                        set: { (newValue) in
                            self.searchText = newValue
                            self.listVM.searchUsers(by: newValue)
                    }), placeholder: "Search by username")
                    ForEach(listVM.itemViewModels) { itemViewModel in
                        UserSearchRowView(userSearchItemVM:itemViewModel)
                    }
                    Spacer()
                }
                .keyboardAdaptive()
                .background(Color(AppColor.backgroundColor()))
                .navigationBarTitle("Make new friends")
                .navigationBarItems(leading:
                    Button("Cancel") {
                        self.presenterDelegate.dismiss()
                })
                ActivityIndicatorView(isAnimating: $listVM.isSearching, style: .large)
                .keyboardAdaptive()
            }
        }
        .onAppear {
            self.listVM.clearSearch()
        }
    }
}

struct FriendSearchView_Previews: PreviewProvider {
    
    static var previews: some View {
        FriendSearchView(delegate: SwiftUIViewPresenterDelegate(), listVM: UserSearchListViewModel(forPreview: true))
    }
}
