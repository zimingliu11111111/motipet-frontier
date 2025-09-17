import ClockKit
import UIKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "motipet.graphic.circular",
            displayName: "MotiPet",
            supportedFamilies: [.graphicCircular, .circularSmall]
        )
        handler([descriptor])
    }

    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Static complication; nothing to handle.
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, with handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(makeTimelineEntry(for: complication))
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, with handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    func getLocalizableSampleTemplate(for complication: CLKComplication, with handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(makeTemplate(for: complication))
    }

    private func makeTimelineEntry(for complication: CLKComplication) -> CLKComplicationTimelineEntry? {
        guard let template = makeTemplate(for: complication) else { return nil }
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }

    private func makeTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.family {
        case .graphicCircular:
            guard let image = UIImage(named: "Complication_Icon") else { return nil }
            let provider = CLKFullColorImageProvider(fullColorImage: image)
            return CLKComplicationTemplateGraphicCircularImage(imageProvider: provider)
        case .circularSmall:
            guard let image = UIImage(named: "Complication_Icon") else { return nil }
            let provider = CLKImageProvider(onePieceImage: image)
            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: provider)
        default:
            return nil
        }
    }
}