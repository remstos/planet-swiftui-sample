//
//  SwiftUIHelpers.swift
//  Calm
//
//  Created by Remi Santos on 03/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import SwiftUI

class SwiftUIViewPresenterDelegate: ObservableObject {
    var host: UIHostingController<AnyView>?
    func dismiss() {
        host?.dismiss(animated: true)
    }
    
    func presentViewController(_ controller: UIViewController) {
        self.host?.present(controller, animated: true, completion: nil)
    }
}

private struct PresenterContainerView<Content>: View where Content:View {
    var content: () -> Content
    init(delegate: SwiftUIViewPresenterDelegate, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}

class SwiftUIViewPresenter<Content>: SwiftUIViewPresenterDelegate where Content:View {
    var viewController: UIViewController?
    init(view: Content) {
        super.init()
        viewController = UIHostingController(rootView: PresenterContainerView(delegate: self, content: {
            return view
        }))
    }

}

// .cornerRadius()
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
