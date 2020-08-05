//
//  UserSearchRowView.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import SwiftUI

struct UserSearchRowView: View {
    @ObservedObject var userSearchItemVM: UserSearchItemViewModel
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color(userSearchItemVM.user.color.color))
                    .frame(width: 80, height: 80)
                Text(userSearchItemVM.user.emoji)
                    .font(Font.system(size: 40))
                Text(userSearchItemVM.user.username)
                .bold()
                .font(Font.system(size: 24))
                .foregroundColor(Color(AppColor.textColor()))
                    .padding(.top, 75)
            }
            if (userSearchItemVM.message != nil) {
                Text(userSearchItemVM.message!)
                .font(Font.system(size: 12))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .foregroundColor(Color(AppColor.secondaryTextColor()))
            } else if (userSearchItemVM.isAFriend) {
                Text("Already a friend")
                .font(Font.system(size: 12))
                .foregroundColor(Color(AppColor.secondaryTextColor()))
            } else if (userSearchItemVM.isLoading) {
                ActivityIndicatorView(isAnimating: .constant(true), style: .medium)
            } else {
                Button("Add friend") {
                    self.userSearchItemVM.addAsFriend()
                }.foregroundColor(Color(userSearchItemVM.user.color.color))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

struct UserSearchRowView_Previews: PreviewProvider {

    static func viewModel(isAFriend: Bool, message: String?, isLoading: Bool, id: String) -> UserSearchItemViewModel {
        let user = AppUser(withUsername: "johndoe", email: "someemail@planet.to", color: PaletteColor.paletteColorD(), emoji: "🦆", uid: id)
        let vm = UserSearchItemViewModel(user: user)
        vm.isLoading = isLoading
        vm.isAFriend = isAFriend
        vm.message = message
        return vm
    }

    static var previews: some View {
        
        let list = [
            self.viewModel(isAFriend: false, message: nil, isLoading: false, id:"1"),
            self.viewModel(isAFriend: false, message: nil, isLoading: true, id:"2"),
            self.viewModel(isAFriend: false, message: "Something failed, you've already requested this user as a friend. checkout the logs.", isLoading: false, id:"3"),
            self.viewModel(isAFriend: true, message: nil, isLoading: false, id:"4"),
        ]
        
        return
            VStack {
                ForEach(list) { vm in
                    UserSearchRowView(userSearchItemVM:vm)
                    .frame(width: 355, height: 180, alignment: .center)
                    .background(Color.black)
                }
            }
    }
}
