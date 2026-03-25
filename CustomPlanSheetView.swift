import SwiftUI

struct CustomPlanSheetView: View {
    @Binding var fastingHours: Int

    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")

    private var eatingHours: Int {
        max(24 - fastingHours, 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("\(fastingHours):\(eatingHours)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(AppL10n.format("custom_plan.summary", fastingHours, eatingHours))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.gray)
                }

                Picker(AppL10n.string("custom_plan.fasting_hours"), selection: $fastingHours) {
                    ForEach(12...23, id: \.self) { hour in
                        Text(AppL10n.format("custom_plan.hour_option", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()

                Text(AppL10n.string("custom_plan.tip"))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button(AppL10n.string("custom_plan.save")) {
                    onSave()
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primary, in: RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(24)
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppL10n.string("Cancel")) {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.52)])
    }
}

#Preview {
    CustomPlanSheetView(
        fastingHours: .constant(17),
        title: AppL10n.string("custom_plan.title"),
        onSave: {},
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
