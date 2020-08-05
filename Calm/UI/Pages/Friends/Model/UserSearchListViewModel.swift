//
//  UserSearchListViewModel.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import Combine
import Resolver

class UserSearchListViewModel: ObservableObject {
    @Published var itemViewModels = [UserSearchItemViewModel]()
    @Published var repository: UserSearchRepository = Resolver.resolve()
    @Published var isSearching = false

    private var cancellables = Set<AnyCancellable>()
    
    init(forPreview: Bool = false) {
        if (forPreview) {
            repository = TestDataUserSearchRepository()
        }
        repository.$users.map { users in
            users.map { user in
                UserSearchItemViewModel(user: user)
            }
        }
        .assign(to: \.itemViewModels, on: self)
        .store(in: &cancellables)
    }
    
    func clearSearch() {
        repository.clearUsers()
    }
    
    func searchUsers(by username: String) {
        isSearching = true
        
        repository.searchUsers(username)
            .sink(receiveCompletion: { _ in }, receiveValue: { (finishedLastSearch) in
                if finishedLastSearch {
                    self.isSearching = false
                }
            })
            .store(in: &cancellables)
    }
}
