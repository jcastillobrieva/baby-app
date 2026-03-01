import SwiftUI
import Charts

struct GrowthChartView: View {
    @Environment(AppState.self) private var appState
    @State private var records: [GrowthRecord] = []
    @State private var selectedMeasurement = MeasurementType.weight
    @State private var showAddRecord = false

    private let supabase = SupabaseService.shared.client

    enum MeasurementType: String, CaseIterable {
        case weight = "Peso"
        case height = "Talla"
        case head = "PC"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Measurement selector
                Picker("Medida", selection: $selectedMeasurement) {
                    ForEach(MeasurementType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                // Chart
                if records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Sin registros de crecimiento aún")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 250)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Chart {
                        ForEach(chartData, id: \.date) { point in
                            LineMark(
                                x: .value("Edad", point.ageMonths),
                                y: .value(selectedMeasurement.rawValue, point.value)
                            )
                            .foregroundStyle(.pink)
                            .symbol(.circle)

                            PointMark(
                                x: .value("Edad", point.ageMonths),
                                y: .value(selectedMeasurement.rawValue, point.value)
                            )
                            .foregroundStyle(.pink)
                            .annotation(position: .top) {
                                Text(String(format: "%.1f", point.value))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartXAxisLabel("Edad (meses)")
                    .chartYAxisLabel(yAxisLabel)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }

                // Records table
                VStack(alignment: .leading, spacing: 8) {
                    Text("Registros")
                        .font(.headline)

                    ForEach(records) { record in
                        GrowthRecordRow(record: record)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Curva de crecimiento")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddRecord) {
            AddGrowthRecordView {
                Task { await loadRecords() }
            }
        }
        .task {
            await loadRecords()
        }
    }

    private var chartData: [(date: Date, ageMonths: Double, value: Double)] {
        guard let baby = appState.currentBaby else { return [] }

        return records.compactMap { record in
            let age = AgeCalculator.calculate(from: baby.dateOfBirth, to: record.measuredAt)
            let value: Double?

            switch selectedMeasurement {
            case .weight: value = record.weightKg
            case .height: value = record.heightCm
            case .head: value = record.headCircumferenceCm
            }

            guard let v = value else { return nil }
            return (date: record.measuredAt, ageMonths: Double(age.totalMonths), value: v)
        }
    }

    private var yAxisLabel: String {
        switch selectedMeasurement {
        case .weight: return "kg"
        case .height: return "cm"
        case .head: return "cm"
        }
    }

    private func loadRecords() async {
        guard let baby = appState.currentBaby else { return }

        do {
            let data: [GrowthRecord] = try await supabase
                .from("growth_records")
                .select()
                .eq("baby_id", value: baby.id.uuidString)
                .order("measured_at")
                .execute()
                .value

            records = data
        } catch {
            // Keep existing
        }
    }
}

// MARK: - Growth Record Row

struct GrowthRecordRow: View {
    let record: GrowthRecord

    var body: some View {
        HStack {
            Text(DateFormatters.mediumDate.string(from: record.measuredAt))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            if let w = record.weightKg {
                VStack {
                    Text("\(String(format: "%.1f", w)) kg")
                        .font(.caption)
                    if let p = record.weightPercentile {
                        Text("P\(Int(p))")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let h = record.heightCm {
                VStack {
                    Text("\(String(format: "%.1f", h)) cm")
                        .font(.caption)
                    if let p = record.heightPercentile {
                        Text("P\(Int(p))")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let hc = record.headCircumferenceCm {
                VStack {
                    Text("\(String(format: "%.1f", hc)) cm")
                        .font(.caption)
                    if let p = record.headPercentile {
                        Text("P\(Int(p))")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Growth Record

struct AddGrowthRecordView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var headCm = ""
    @State private var isLoading = false

    let onSave: () -> Void

    private let supabase = SupabaseService.shared.client

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Fecha", selection: $date, in: ...Date(), displayedComponents: .date)

                Section("Medidas") {
                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("ej: 8.5", text: $weightKg)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Talla (cm)")
                        Spacer()
                        TextField("ej: 70.0", text: $heightCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Perímetro cefálico (cm)")
                        Spacer()
                        TextField("ej: 44.0", text: $headCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Nuevo registro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(isLoading || (weightKg.isEmpty && heightCm.isEmpty && headCm.isEmpty))
                }
            }
        }
    }

    private func save() async {
        guard let baby = appState.currentBaby else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id
            let ageMonths = AgeCalculator.calculate(from: baby.dateOfBirth, to: date).totalMonths
            let sex: WHOGrowthData.Sex = baby.sex == .male ? .male : .female

            var params: [String: String] = [
                "baby_id": baby.id.uuidString,
                "measured_at": DateFormatters.dateOnly.string(from: date),
                "logged_by": userId.uuidString
            ]

            if let weight = Double(weightKg), weight > 0 {
                params["weight_kg"] = String(weight)
                if let percentile = WHOGrowthData.percentile(
                    value: weight, ageMonths: ageMonths, sex: sex, type: .weight
                ) {
                    params["weight_percentile"] = String(format: "%.1f", percentile)
                }
            }

            if let height = Double(heightCm), height > 0 {
                params["height_cm"] = String(height)
                if let percentile = WHOGrowthData.percentile(
                    value: height, ageMonths: ageMonths, sex: sex, type: .height
                ) {
                    params["height_percentile"] = String(format: "%.1f", percentile)
                }
            }

            if let head = Double(headCm), head > 0 {
                params["head_circumference_cm"] = String(head)
                if let percentile = WHOGrowthData.percentile(
                    value: head, ageMonths: ageMonths, sex: sex, type: .headCircumference
                ) {
                    params["head_percentile"] = String(format: "%.1f", percentile)
                }
            }

            try await supabase
                .from("growth_records")
                .insert(params)
                .execute()

            onSave()
            dismiss()
        } catch {
            // Handle error
        }
    }
}
