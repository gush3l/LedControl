//
//  ColorSliderView.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import SwiftUI

struct ColorSliderView: View {
    let label: String
    let color: Color
    let systemImage: String
    @Binding var value: Float
    
    @State private var textValue: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(label: String, value: Binding<Float>, color: Color, systemImage: String = "slider.horizontal.3") {
        self.label = label
        self._value = value
        self.color = color
        self.systemImage = systemImage
        self._textValue = State(initialValue: "\(Int(value.wrappedValue))")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 7)
            
            HStack {
                TextField("", text: $textValue)
                    .frame(width: 40, alignment: .center)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .onChange(of: textValue) { newValue in
                        if let intValue = UInt8(newValue), intValue <= 255 {
                            value = Float(intValue)
                        }
                    }
                    .onSubmit { isTextFieldFocused = false }
                
                Slider(value: $value, in: 0...255, step: 1)
                    .accentColor(color)
                    .onChange(of: value) { newValue in
                        textValue = "\(Int(newValue))"
                    }
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .shadow(radius: 5)
        )
    }
}
