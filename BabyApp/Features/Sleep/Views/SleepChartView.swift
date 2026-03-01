import SwiftUI
import Charts

struct SleepChartView: View {
    let dailySleepData: [DailySleepData]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Horas de sueño por día")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(dailySleepData) { data in
                BarMark(
                    x: .value("Día", data.dayLabel),
                    y: .value("Horas", data.totalHours)
                )
                .foregroundStyle(
                    data.totalHours >= 12 ? Color.indigo :
                    data.totalHours >= 10 ? Color.indigo.opacity(0.7) :
                    Color.orange
                )
                .cornerRadius(4)
                .annotation(position: .top, alignment: .center) {
                    if data.totalHours > 0 {
                        Text(String(format: "%.1f", data.totalHours))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...18)
            .frame(height: 180)

            // Average
            let avg = dailySleepData.isEmpty ? 0 :
                dailySleepData.map(\.totalHours).reduce(0, +) / Double(dailySleepData.count)
            Text("Promedio: \(String(format: "%.1f", avg))h/día")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let totalHours: Double
    let nightHours: Double
    let napHours: Double
}
