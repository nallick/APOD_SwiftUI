//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pictureOfTheDay: PictureOfTheDay

    private let dateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "MMMM d, yyyy"
        return result
    }()

    var body: some View {
        if let picture = pictureOfTheDay.picture.value {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    LabeledText(label: "Date:", content: dateFormatter.string(from: pictureOfTheDay.date))
                    LabeledText(label: "Description:", content: picture.explanation)
                    LabeledText(label: "Copyright:", content: picture.copyright ?? "")
                    LabeledText(label: "URL:", content: picture.url.absoluteString)
                }
                if let error = pictureOfTheDay.image.error {
                    Text("Error: \(error.localizedDescription)\n\n\(String(describing: error))")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 500, alignment: .topLeading)
                        .padding()
                } else {
                    Image(nsImage: (pictureOfTheDay.image.value ?? nil) ?? NSImage())
                }
            }
        } else if let error = pictureOfTheDay.picture.error, error.isError {
            VStack(alignment: .leading) {
                Text("Date: \(dateFormatter.string(from: pictureOfTheDay.date))")
                    .padding(.bottom)
                Text("Error: \(error.localizedDescription)\n\n\(String(describing: error))")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 500, alignment: .topLeading)
            }
        }
    }
}

extension ContentView {

    struct LabeledText: View {
        let label: String
        let content: String

        var body: some View {
            HStack(alignment: .top) {
                Text(label)
                    .font(.body).bold()
                    .frame(width: 100, alignment: .topTrailing)
                    .padding(.trailing, 10)
                Text(content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300, alignment: .topLeading)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PictureOfTheDay())
    }
}
