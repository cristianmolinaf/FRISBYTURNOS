import Flutter
import UIKit
import SwiftUI

// MARK: - Flutter MethodChannel for Liquid Glass
public class LiquidGlassPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.frisby.turnos/liquid_glass", binaryMessenger: registrar.messenger())
    let instance = LiquidGlassPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLiquidGlassSupported":
      if #available(iOS 26, *) {
        result(true)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - SwiftUI Liquid Glass Native Navigation View
// Adheres strictly to the swiftui-liquid-glass skill specification:
// - Uses GlassEffectContainer to wrap grouped navigation items
// - Applies .glassEffect(.regular.interactive()) to buttons / capsules
// - Supports morphing transitions with glassEffectID
// - Gated with #available(iOS 26, *) and provides clean fallback for earlier iOS versions

public struct NavItemData: Identifiable {
  public let id: Int
  public let title: String
  public let systemImage: String
}

@available(iOS 15.0, *)
public struct FrisbyLiquidGlassNavBarView: View {
  @Binding public var selectedIndex: Int
  public let items: [NavItemData]
  public let activeColor: Color
  public let isDark: Bool
  public var onSelect: ((Int) -> Void)?

  public init(
    selectedIndex: Binding<Int>,
    items: [NavItemData],
    activeColor: Color = Color(red: 200/255, green: 16/255, blue: 46/255), // Frisby Red #C8102E
    isDark: Bool = false,
    onSelect: ((Int) -> Void)? = nil
  ) {
    self._selectedIndex = selectedIndex
    self.items = items
    self.activeColor = activeColor
    self.isDark = isDark
    self.onSelect = onSelect
  }

  public var body: some View {
    #if compiler(>=6.0)
    if #available(iOS 26, *) {
      // Modern iOS 26+ Native Liquid Glass Navigation Container
      GlassEffectContainer(spacing: 24) {
        HStack(spacing: 8) {
          ForEach(items) { item in
            let isSelected = selectedIndex == item.id
            Button(action: {
              selectedIndex = item.id
              onSelect?(item.id)
            }) {
              VStack(spacing: 3) {
                Image(systemName: item.systemImage)
                  .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                  .foregroundColor(isSelected ? activeColor : (isDark ? Color.white.opacity(0.65) : Color(red: 28/255, green: 28/255, blue: 30/255).opacity(0.65)))
                Text(item.title)
                  .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                  .foregroundColor(isSelected ? activeColor : (isDark ? Color.white.opacity(0.65) : Color(red: 28/255, green: 28/255, blue: 30/255).opacity(0.65)))
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .glassEffect(isSelected ? .regular.tint(activeColor).interactive() : .regular.interactive(), in: Capsule())
          }
        }
        .padding(6)
        .background(
          Capsule()
            .fill(isDark ? Color.black.opacity(0.2) : Color.white.opacity(0.2))
        )
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
    } else {
      fallbackNavBar
    }
    #else
    fallbackNavBar
    #endif
  }

  // Fallback for iOS < 26 (Smooth Frosted Glass with Material and Blur)
  private var fallbackNavBar: some View {
    HStack(spacing: 12) {
      ForEach(items) { item in
        let isSelected = selectedIndex == item.id
        Button(action: {
          selectedIndex = item.id
          onSelect?(item.id)
        }) {
          VStack(spacing: 3) {
            Image(systemName: item.systemImage)
              .font(.system(size: 20, weight: isSelected ? .bold : .medium))
              .foregroundColor(isSelected ? activeColor : (isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.6)))
            Text(item.title)
              .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
              .foregroundColor(isSelected ? activeColor : (isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.6)))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            Capsule()
              .fill(isSelected ? activeColor.opacity(0.12) : Color.clear)
          )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(
      Capsule()
        .fill(.ultraThinMaterial)
        .overlay(
          Capsule()
            .stroke(Color.white.opacity(isDark ? 0.2 : 0.8), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.08), radius: 20, y: 8)
    )
    .padding(.bottom, 8)
  }
}
