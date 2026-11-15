import SwiftUI

extension View {
    func card() -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}

struct Orbs: View {
    @Environment(\.colorScheme) private var cs

    var body: some View {
        ZStack {
            (cs == .dark ? Color.black : Color.white)
            TimelineView(.animation) { tl in
                Canvas { ctx, size in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let main: Color = cs == .dark ? .white : .black
                    for i in 0..<9 {
                        let f = Double(i)
                        let x = CGFloat(0.5 + 0.45 * sin(t * (0.045 + f * 0.006) + f * 1.7)) * size.width
                        let y = CGFloat(0.5 + 0.45 * cos(t * (0.038 + f * 0.005) + f * 2.3)) * size.height
                        let r = CGFloat(70 + f * 12)
                        let c: Color = i % 3 == 0 ? main.opacity(0.55) : (i % 3 == 1 ? Color.gray.opacity(0.5) : main.opacity(0.25))
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(c))
                    }
                }
                .blur(radius: 30)
            }
        }
        .ignoresSafeArea()
    }
}

struct GuidesView: View {
    @State private var q = ""
    private var list: [Guide] {
        q.isEmpty ? Guide.all : Guide.all.filter {
            $0.title.localizedCaseInsensitiveContains(q) || $0.steps.joined(separator: " ").localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(list) { g in
                        NavigationLink(value: g) {
                            HStack(spacing: 14) {
                                Image(systemName: g.icon).font(.title2).frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.title).font(.headline)
                                    Text(g.intro).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .card()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background { Orbs() }
            .navigationTitle("Выживание")
            .searchable(text: $q)
            .navigationDestination(for: Guide.self) { GuideDetail(g: $0) }
        }
    }
}

struct GuideDetail: View {
    let g: Guide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(g.intro).font(.title3).foregroundStyle(.secondary).padding(.horizontal, 4)
                ForEach(Array(g.steps.enumerated()), id: \.offset) { i, s in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)").font(.headline.monospacedDigit())
                            .frame(width: 30, height: 30)
                            .glassEffect(.regular, in: .circle)
                        Text(s)
                    }
                    .card()
                }
            }
            .padding()
        }
        .background { Orbs() }
        .navigationTitle(g.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RadarView: View {
    @EnvironmentObject var nav: Nav
    @Environment(\.colorScheme) private var cs

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let R = min(size.width, size.height) / 2 - 18
            let fg: Color = cs == .dark ? .white : .black
            for k in 1...3 {
                let r = R * CGFloat(k) / 3
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                           with: .color(fg.opacity(0.25)), lineWidth: 1)
            }
            for (i, s) in ["С", "В", "Ю", "З"].enumerated() {
                let a = (Double(i) * 90 - nav.heading) * .pi / 180
                let p = CGPoint(x: c.x + (R + 4) * CGFloat(sin(a)), y: c.y - (R + 4) * CGFloat(cos(a)))
                ctx.draw(Text(s).font(.caption.bold()).foregroundStyle(i == 0 ? fg : fg.opacity(0.5)), at: p)
            }
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 6, y: c.y - 6, width: 12, height: 12)), with: .color(fg))
            var tri = Path()
            tri.move(to: CGPoint(x: c.x, y: c.y - 20))
            tri.addLine(to: CGPoint(x: c.x - 6, y: c.y - 10))
            tri.addLine(to: CGPoint(x: c.x + 6, y: c.y - 10))
            tri.closeSubpath()
            ctx.fill(tri, with: .color(fg))
            guard let me = nav.loc else { return }
            let maxD = max(nav.points.map { me.distance(from: $0.location) }.max() ?? 0, 100)
            for p in nav.points {
                let d = me.distance(from: p.location)
                let b = (Nav.bearing(from: me, to: p.location.coordinate) - nav.heading) * .pi / 180
                let rr = R * 0.85 * CGFloat(d / maxD)
                let pt = CGPoint(x: c.x + rr * CGFloat(sin(b)), y: c.y - rr * CGFloat(cos(b)))
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)), with: .color(fg))
                ctx.draw(Text(p.name).font(.caption2).foregroundStyle(fg), at: CGPoint(x: pt.x, y: pt.y + 14))
            }
        }
    }
}

struct NavView: View {
    @EnvironmentObject var nav: Nav
    @State private var name = ""
    @State private var adding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    RadarView().frame(height: 330).card()
                    HStack {
                        Text("\(Int(nav.heading))° \(nav.direction)")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let l = nav.loc {
                                Text(String(format: "%.5f, %.5f", l.coordinate.latitude, l.coordinate.longitude))
                                Text("±\(Int(max(l.horizontalAccuracy, 0))) м, высота \(Int(l.altitude)) м").foregroundStyle(.secondary)
                            } else {
                                Text("Ищу GPS…").foregroundStyle(.secondary)
                            }
                        }
                        .font(.footnote)
                    }
                    .card()
                    Button { adding = true } label: {
                        Label("Отметить точку здесь", systemImage: "mappin.and.ellipse").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass).controlSize(.large)
                    .disabled(nav.loc == nil)
                    ForEach(nav.points) { p in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.headline)
                                if let me = nav.loc {
                                    Text(Nav.dist(me.distance(from: p.location))).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let me = nav.loc {
                                Image(systemName: "location.north.fill").font(.title2)
                                    .rotationEffect(.degrees(Nav.bearing(from: me, to: p.location.coordinate) - nav.heading))
                            }
                            Button { nav.points.removeAll { $0.id == p.id } } label: { Image(systemName: "trash") }
                                .buttonStyle(.plain).padding(.leading, 12)
                        }
                        .card()
                    }
                    Text("Это не карта местности: без интернета показываются ваши отметки относительно вас. Отметьте лагерь или машину, и стрелка всегда покажет путь назад. Компас работает по датчикам телефона, GPS без интернета.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal, 8)
                }
                .padding()
            }
            .background { Orbs() }
            .navigationTitle("Карта")
            .alert("Название точки", isPresented: $adding) {
                TextField("Лагерь", text: $name)
                Button("Сохранить") { nav.addHere(name); name = "" }
                Button("Отмена", role: .cancel) { name = "" }
            }
        }
    }
}

struct SOSView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var on = false
    @State private var task: Task<Void, Never>?
    @State private var oldBrightness: CGFloat = 0.5

    var body: some View {
        ZStack {
            (on ? Color.white : Color.black).ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("SOS").font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(on ? .black : .white)
                Spacer()
                Button("Закрыть") { dismiss() }.buttonStyle(.glass).controlSize(.large)
            }
            .padding(32)
        }
        .onAppear {
            oldBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1
            UIApplication.shared.isIdleTimerDisabled = true
            task = Task {
                let seq: [Double] = [0.25, 0.25, 0.25, 0.75, 0.75, 0.75, 0.25, 0.25, 0.25]
                while !Task.isCancelled {
                    for (i, d) in seq.enumerated() {
                        on = true
                        try? await Task.sleep(for: .seconds(d))
                        on = false
                        try? await Task.sleep(for: .seconds(i == 2 || i == 5 ? 0.75 : 0.25))
                    }
                    try? await Task.sleep(for: .seconds(1.5))
                }
            }
        }
        .onDisappear {
            task?.cancel()
            UIScreen.main.brightness = oldBrightness
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

struct ToolsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("checked") private var raw = ""
    @State private var sos = false

    private let items = [
        "Вода (2 л и больше)", "Фильтр или таблетки для воды", "Огниво и спички в гермопакете",
        "Нож или мультитул", "Фонарь и запасные батарейки", "Аптечка",
        "Тёплая одежда и термоодеяло", "Свисток", "Павербанк и кабель",
        "Бумажная карта и компас", "Еда на 1–2 дня", "Документы и наличные"
    ]
    private var done: Set<Int> { Set(raw.split(separator: ",").compactMap { Int($0) }) }

    private func toggle(_ i: Int) {
        var s = done
        if s.contains(i) { s.remove(i) } else { s.insert(i) }
        raw = s.sorted().map(String.init).joined(separator: ",")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Button { sos = true } label: {
                        Label("Световой сигнал SOS", systemImage: "light.beacon.max.fill")
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.glass).controlSize(.large)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Чек-лист рюкзака").font(.headline)
                        ForEach(items.indices, id: \.self) { i in
                            Button { toggle(i) } label: {
                                HStack {
                                    Image(systemName: done.contains(i) ? "checkmark.circle.fill" : "circle")
                                    Text(items[i]).strikethrough(done.contains(i))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Оформление").font(.headline)
                        Picker("Тема", selection: $theme) {
                            Text("Авто").tag("system")
                            Text("Светлая").tag("light")
                            Text("Тёмная").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }
                    .card()

                    Text("Все данные хранятся в приложении, интернет не нужен.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
            }
            .background { Orbs() }
            .navigationTitle("Инструменты")
            .fullScreenCover(isPresented: $sos) { SOSView() }
        }
    }
}
