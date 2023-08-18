//
//  Extensions.swift
//  MyHelperApp
//
//  Created by Sibtain Ali (Fiverr) on 27/01/2022.
//

import SwiftUI

extension NSNotification {
    static let ImageCaptured = NSNotification.Name.init("ImageCaptured")
}


extension Dictionary {
    
    func toString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)?.removingPercentEncoding ?? ""
        } catch {
            printOnDebug("Error serializing dictionary to JSON string: \(error.localizedDescription)")
            return ""
        }
    }
    
    func print() {
        printOnDebug(self.toString())
    }
    
}

extension Encodable {
    
    func toDictionary() -> [String: Any] {
        let data = try? JSONEncoder().encode(self)
        guard let dictionary = try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
    
}


extension Binding {
    // usage example: TextField("Name", text: $template.text.toUnwrapped(defaultValue: ""))
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}


extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    var isNotEmpty: Bool {
        self.count > 0
    }
}


extension View {
    
    // take screenshot of any view
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}


func printOnDebug(_ object: Any) {
#if DEBUG
    print(object)
#endif
}
