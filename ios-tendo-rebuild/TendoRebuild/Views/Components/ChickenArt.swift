import SwiftUI

/// Maps a protocol's completed-chicken visual identifier to bundled artwork.
enum ChickenArt {
    static let visualIds: [String] = ["standard", "hot", "nugget", "wingHeavy", "independent", "corporate", "road", "night", "theseus"]

    static func assetName(for visualId: String) -> String {
        switch visualId {
        case "standard": "leghorn_hen_profile"
        case "hot": "hen_red_black_profile"
        case "nugget": "hen_made_of_nuggets"
        case "wingHeavy": "hen_giant_wings"
        case "independent": "weathered_hen_profile"
        case "corporate": "manufactured_hen"
        case "road": "golden_laced_hen"
        case "night": "black_hen_profile"
        default: "assembled_hen"
        }
    }

    static func label(for visualId: String) -> String {
        switch visualId {
        case "standard": "Standard Specimen"
        case "hot": "Thermal Specimen"
        case "nugget": "Nugget Construction"
        case "wingHeavy": "Wing-Dominant Specimen"
        case "independent": "Independent Specimen"
        case "corporate": "Uniform Specimen"
        case "road": "Regional Composite"
        case "night": "Nocturnal Specimen"
        default: "Multi-Source Assembly"
        }
    }
}

struct RestoredChickenImage: View {
    let visualId: String

    var body: some View {
        Image(ChickenArt.assetName(for: visualId))
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
