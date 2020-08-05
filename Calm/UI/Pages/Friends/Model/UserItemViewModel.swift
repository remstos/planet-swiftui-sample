//
//  UserSearchItemViewModel.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import Combine
import Resolver

class UserSearchItemViewModel: ObservableObject, Identifiable  {
    @Published var repository: UserSearchRepository = Resolver.resolve()
    @Published var user: AppUser
    @Published var isAFriend: Bool = false
    @Published var isLoading: Bool = false
    @Published var message: String?

    var id: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(user: AppUser) {
        self.user = user
        
        $user
            .map { $0.id! }
            .assign(to: \.id, on: self)
            .store(in: &cancellables)

    }
    
    func addAsFriend() {
        self.isLoading = true
        _ = repository.addUserAsFriend(self.user)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .failure(let error):
                    self.message = error.localizedDescription
                case .finished:
                    break
                }
            }, receiveValue: { success in
                self.message = success ? "They've received your request" : self.message
                self.isLoading = false
            })
            .store(in: &cancellables)
    }
}
