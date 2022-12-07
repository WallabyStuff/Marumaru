//
//  SkeletonView+CustomAnimation.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import SkeletonView

extension UIView {
  func showCustomSkeleton() {
    let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .topLeftBottomRight)
    let gradient = SkeletonGradient(baseColor: R.color.backgroundWhiteLight()!,
                                    secondaryColor: R.color.backgroundGray()!)
    showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
  }
}
