//
//  FriendsViewController.swift
//  Calm
//
//  Created by Remi Santos on 22/03/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import UIKit
import PanModal

class FriendsViewController: UIViewController, StoryboardInstantiable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var friends : [Friendship] = []
    var requests : [Friendship] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    weak var refreshControl : UIRefreshControl?

    private var margin : CGFloat {
        get {
            return self.view.layoutMargins.left
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = AppColor.backgroundColor()
        
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.register(UINib(nibName: TitleReusableView.nibName, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TitleReusableView.reuseIdentifier)

        let refreshCtrl = UIRefreshControl()
        refreshCtrl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        self.collectionView.refreshControl = refreshCtrl
        refreshControl = refreshCtrl
    
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = nil
        
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addNewFriend))
        self.navigationItem.rightBarButtonItem = addButton
        
        self.setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clearPersonalizedNavigationBar(animated: animated)
    }
    
    func setupData() {
        guard let currentUser = AppUserManager.shared.currentUser else {
            return
        }
        FriendsStore.getFriendshipsForUser(currentUser) { (friendships, error) in
            if let friendships = friendships {
                var friends: [Friendship] = []
                var requests: [Friendship] = []
                friendships.forEach { (friendship) in
                    if friendship.status == "requested" {
                        if (friendship.initiatedBy.id != currentUser.id) {
                            requests.append(friendship)
                        }
                    } else {
                        friends.append(friendship)
                    }
                }
                self.friends = friends
                self.requests = requests
                self.refreshControl?.endRefreshing()
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func refresh() {
        self.setupData()
    }
    
    @objc func addNewFriend() {
        guard let _ = AppUserManager.shared.currentUser else {
            return
        }
        let presenter = FriendSearchViewPresenter()
        if let controller = presenter.viewController {
            present(controller, animated: true, completion: nil)
        }
    }
    
    func showAlert(withMessage message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cool.", style: .default, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showFriendPlanet(_ friendship: Friendship) {
        let controller = UserPlanViewController.createFromStoryboard(embedInNavigation: false) as! UserPlanViewController
        controller.user = friendship.friend
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAnswerFriendshipRequest(_ friendship: Friendship) {
        let friendUsername = friendship.friend.username
        let alert = UIAlertController(title: "\(friendUsername) asked to be your friend", message: "What do you want to do?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm friendship", style: .default, handler:{ (action) in
            FriendsStore.acceptFriendship(friendship) { (success, error) in
                self.showAlert(withMessage: success ? "Congrats, \(friendUsername) and you are friends now" : "Something went wrong")
                self.refresh()
            }
        }))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive, handler:{ (action) in
            FriendsStore.declineFriendship(friendship) { (success, error) in
                self.showAlert(withMessage: success ? "Ok, the friend request has been declined. Feel free to block them if needed" : "Something went wrong")
                self.refresh()
            }
        }))
        alert.addAction(UIAlertAction(title: "Do nothing for now", style: .cancel, handler:nil))

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - UICollectionView
    
    func friendshipAtIndexPath(_ indexPath:IndexPath) -> Friendship? {
        var source: [Friendship] = []
        if (indexPath.section == 0) {
            source = self.requests
        } else {
            source = self.friends
        }
        return source.count > indexPath.row ? source[indexPath.row] : nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? self.requests.count : self.friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TitleReusableView.reuseIdentifier, for: indexPath) as! TitleReusableView
        let title = indexPath.section == 0 ? "Requests" : "Friends"
        view.updateWithText(title)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserStatusCollectionCell
        cell.displayStatus = false
        let friendship = self.friendshipAtIndexPath(indexPath)!

        cell.updateForFriend(friendship.friend, event: nil, nextEvent: nil)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let friendship = self.friendshipAtIndexPath(indexPath) else {
            return
        }

        if (friendship.status == "requested") {
            self.showAnswerFriendshipRequest(friendship)
        } else if (friendship.status == "accepted") {
            self.showFriendPlanet(friendship)
        }
    }
    
    // MARK: - UICollectionViewFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let shouldDisplayTitle = self.collectionView(collectionView, numberOfItemsInSection: section) > 0
        let height = TitleReusableView.defaultHeight
        return shouldDisplayTitle ? CGSize(width: 0, height:height) : CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let margin = self.margin
        return UIEdgeInsets(top: 0, left: margin, bottom: margin, right: margin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.margin
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin = self.margin
        let height: CGFloat = indexPath.section == 0 ? 64 : 40
        let width = (collectionView.bounds.size.width - margin*2)
        return CGSize(width: width, height: height)
    }
}
